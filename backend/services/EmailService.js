const Email = require('../models/Email');
const User = require('../models/User');
const { userSockets } = require('../db/websocket');
const axios = require('axios');

const resolveUsers = async (emails) => {
    if (!emails) return [];
    console.log("Resolving Users for Emails:", emails);
    const users = await Promise.all(
        emails.map(email => User.findOne({ email }).select('_id'))
    );
    return users.filter(Boolean).map(user => user._id);
};

const saveEmail = async (userId, data) => {
    const [receivers, ccs, bccs] = await Promise.all([
        resolveUsers(data.to),
        resolveUsers(data.cc),
        resolveUsers(data.bcc),
    ]);

    const allReceivers = [...receivers, ...ccs, ...bccs];

    const spamStatus = await predictSpamStatus(data.subject + "\n" + data.content);
    const isSpam = spamStatus === 'spam';
    const emailPayload = {
        ...data,
        senderId: userId,
        receiverIds: allReceivers,
        attachmentsCount: data.attachments ? data.attachments.length : 0,
        isSpam
    };

    return await Email.create(emailPayload);
};

const predictSpamStatus = async (message) => {
    try {
        const res = await axios.post('https://final-flutter-ml.onrender.com/predict', {
            message: message || ''
        });
        return res.data.prediction || 'ham';
    } catch (err) {
        console.error("ML API error:", err.message);
        return 'ham';
    }
};


exports.createEmail = async (userId, data) => {

    const newEmail = await saveEmail(userId, data);
    console.log("SAVED", newEmail)

    newEmail.receiverIds.forEach(receiverId => {
        const socket = userSockets.get(receiverId.toString());
        if (socket) {
            console.log('Sending new email to user', receiverId);
            socket.emit('new_email', {
                id: newEmail._id,
                sender: newEmail.sender,
                subject: newEmail.subject,
                plainTextContent: newEmail.plainTextContent,
                attachmentsCount: newEmail.attachmentsCount,
            });
        }
    });

    return newEmail;
}

exports.updateEmail = async (id, data) => await Email.findByIdAndUpdate(id, data, { new: true }).select('+receiverIds +bcc +cc +content +attachments +isReplied +isForwarded +originalEmailId +starred +isDraft +isInTrash +isSpam');

exports.getAllEmails = async (id) => await
    Email.find({
        $and: [
            {
                $or: [
                    { senderId: id },
                    { receiverIds: id }
                ]
            },
            { isInTrash: false },
            { isSpam: false },
            { isDraft: false },
        ]
    })
        .sort({ createdAt: -1 })

exports.getEmailById = async (id) => {
    const email = await Email.findById(id).select(
        '+receiverIds +bcc +cc +content +attachments +isReplied +isForwarded +originalEmailId +starred +isDraft +isInTrash +isSpam'
    ).lean();

    if (!email) throw new Error('Email not found');

    const threadOriginalId = email.originalEmailId || email._id.toString();

    const threadEmails = await Email.find({
        $or: [
            { _id: threadOriginalId },
            { originalEmailId: threadOriginalId },
        ]
    }).select(
        '+receiverIds +bcc +cc +content +attachments +isReplied +isForwarded +originalEmailId +starred +isDraft +isInTrash +isSpam'
    ).sort({ createdAt: 1 }).lean();

    return {
        email,
        thread: threadEmails,
    };
};
exports.updateEmail = async (id, data) => await Email.findByIdAndUpdate(id, data, { new: true });

exports.deleteEmail = async (id) => await Email.findByIdAndDelete(id);

exports.getSentEmails = async (userId) => await Email.find({ senderId: userId }).sort({ createdAt: -1 });

exports.getStarredEmails = async (userId) => await Email.find({
    $and: [
        {
            $or: [
                { senderId: userId },
                { receiverIds: userId }
            ]
        },
        { starred: true }
    ]
}).sort({ createdAt: -1 });

exports.getDrafts = async (userId) => await Email.find({ senderId: userId, isDraft: true }).sort({ createdAt: -1 });

exports.getTrash = async (userId) => await Email.find({ senderId: userId, isInTrash: true }).sort({ createdAt: -1 });

exports.getSpam = async (userId) => await Email.find({
    $and: [
        {
            $or: [{ senderId: userId },
            { receiverIds: userId }], isSpam: true
        }

    ]
}).sort({ createdAt: -1 });

exports.toggleStar = async (id) => {
    const email = await Email.findById(id);
    if (!email) throw new Error('Email not found');
    email.starred = !email.starred;
    return await email.save();
};
exports.markRead = async (id) => {
    const email = await Email.findById(id);
    if (!email) throw new Error('Email not found');
    email.isRead = !email.isRead;
    return await email.save();
}

exports.moveToTrash = async (id) => await Email.findByIdAndUpdate(id, { isInTrash: true, starred: false }, { new: true });

exports.restoreEmail = async (id) => await Email.findByIdAndUpdate(id, { isInTrash: false }, { new: true });

exports.searchEmails = async (userId, query) => {
    const escapeRegex = str => str.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
    const regex = new RegExp(escapeRegex(query), 'i');
    console.log("Search Query:", query, regex.test("Earn $5000"));
    return await Email.find({
        $and: [
            {
                $or: [
                    { sender: regex },
                    { to: { $elemMatch: { $regex: regex } } },
                    { subject: regex },
                    { plainTextContent: regex },
                ]
            },
            {
                $or: [
                    { senderId: userId },
                    { receiverIds: userId },
                ]
            },
            { isInTrash: false },
        ]
    }).sort({ createdAt: -1 });
};

exports.advancedSearch = async (userId, req) => {
    console.log("Advanced Search Query:", req);
    const { from, to, subject, keywords, fromDate, toDate, hasAttachments } = req.query;
    const query = {
        $and: [
            { isInTrash: false },
            {
                $or: [
                    { senderId: userId },
                    { receiverIds: userId },
                ]
            }
        ]
    };

    if (from) query.$and.push({ sender: new RegExp(from, 'i') });
    if (to) query.$and.push({ to: { $elemMatch: { $regex: new RegExp(to, 'i') } } });
    if (subject) query.$and.push({ subject: new RegExp(subject, 'i') });
    if (keywords) query.$and.push({ plainTextContent: new RegExp(keywords, 'i') });
    if (hasAttachments === 'true') query.$and.push({ attachments: { $ne: [] } });
    if (fromDate && toDate) {
        query.$and.push({
            createdAt: { $gte: new Date(fromDate), $lte: new Date(toDate) }
        });
    }
    else if (fromDate) {
        query.$and.push({ createdAt: { $gte: new Date(fromDate) } });
    } else if (toDate) {
        query.$and.push({ createdAt: { $lte: new Date(toDate) } });
    }

    return await Email.find(query).sort({ createdAt: -1 });
}


exports.getEmailsByLabel = async (userId, label) => {
    console.log(label)
    return await Email.find({
        $and: [
            {
                $or: [
                    { senderId: userId },
                    { receiverIds: userId }
                ]
            },
            { labels: { $elemMatch: { _id: label } } },
            { isInTrash: false }
        ]
    }).sort({ createdAt: -1 });
};

exports.addLabelToEmail = async (emailId, label) => {
    const email = await Email.findById(emailId);
    if (!email) throw new Error('Email not found');
    if (email.labels.map(l => l.id).includes(label.label._id)) {
        email.labels = email.labels.filter(l => l._id !== label.label._id);
    }
    else {
        email.labels.push(label.label);
    }
    return await email.save();
};

exports.removeLabelFromEmail = async (emailId, label) => {
    const email = await Email.findById(emailId);
    if (!email) throw new Error('Email not found');
    email.labels = email.labels.filter(l => l._id !== label);
    return await email.save();
}

exports.getEmailLabels = async (userId, labelId) => await Email.find({
    $and: [
        {
            $or: [
                { senderId: userId },
                { receiverIds: userId }
            ]
        },
        { labels: { $elemMatch: { _id: labelId } } },
        { isInTrash: false }
    ]
})
    .sort({ createdAt: -1 })
    .select('-receiverIds -content -__v -senderId -to -bcc -cc -updatedAt');