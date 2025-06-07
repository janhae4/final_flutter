const Email = require('../models/Email');
const User = require('../models/User');
const { userSockets } = require('../db/websocket');

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
    console.log("All Receivers:", allReceivers);
    return await Email.create({
        ...data,
        senderId: userId,
        receiverIds: allReceivers,
        attachmentsCount: data.attachments ? data.attachments.length : 0,
    });
}
exports.createEmail = async (userId, data) => {

    const newEmail = await saveEmail(userId, data);

    if (newEmail.isDraft) return newEmail;

    newEmail.receiverIds.forEach(receiverId => {
        const socket = userSockets.get(receiverId.toString());
        if (socket) {
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

exports.getAllEmails = async (id) =>
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
exports.updateEmail = async (id, data) => Email.findByIdAndUpdate(id, data, { new: true });

exports.deleteEmail = async (id) => Email.findByIdAndDelete(id);

exports.getSentEmails = async (userId) => Email.find({ senderId: userId }).sort({ createdAt: -1 });

exports.getStarredEmails = async (userId) => Email.find({
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

exports.getDrafts = async (userId) => Email.find({ senderId: userId, isDraft: true }).sort({ createdAt: -1 });

exports.getTrash = async (userId) => Email.find({ senderId: userId, isInTrash: true }).sort({ createdAt: -1 });

exports.getSpam = async (userId) => Email.find({ senderId: userId, isSpam: true }).sort({ createdAt: -1 });

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

exports.moveToTrash = async (id) => Email.findByIdAndUpdate(id, { isInTrash: true, starred: false }, { new: true });

exports.restoreEmail = async (id) => Email.findByIdAndUpdate(id, { isInTrash: false }, { new: true });

exports.searchEmails = async (userId, query) => {
    console.log("Search Query:", query);
    const regex = new RegExp(query, 'i');

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
    const { from, to, subject, keywords, hasAttachment, fromDate, toDate, hasAttachments } = req.query;
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
            { labels: { $elemMatch: { _id : label } } },
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

exports.getEmailLabels = async (userId, labelId) => Email.find({
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