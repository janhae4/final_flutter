const Email = require('../models/Email');
const User = require('../models/User');
const { userSockets } = require('../db/websocket');

exports.createEmail = async (userId, data) => {
    const resolveUsers = async (emails) => {
        if (!emails) return [];
        const users = await Promise.all(
            emails.map(email => User.findOne({ email }).select('_id'))
        );
        return users.filter(Boolean).map(user => user._id);
    };

    const [receivers, ccs, bccs] = await Promise.all([
        resolveUsers(data.to),
        resolveUsers(data.cc),
        resolveUsers(data.bcc),
    ]);

    const allReceivers = [...receivers, ...ccs, ...bccs];

    const newEmail = await Email.create({
        ...data,
        senderId: userId,
        receiverIds: allReceivers
    });

    allReceivers.forEach(receiverId => {
        const socket = userSockets.get(receiverId.toString());
        if (socket) {
            socket.emit('new_email', {
                id: newEmail._id,
                sender: newEmail.sender,
                subject: newEmail.subject,
                plainTextContent: newEmail.plainTextContent,
                attachments: newEmail.attachments,
                labels: newEmail.labels,
                starred: newEmail.starred,
                isRead: newEmail.isRead,
                isDraft: newEmail.isDraft,
                isInTrash: newEmail.isInTrash,
                createdAt: newEmail.createdAt
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
            { isInTrash: false }
        ]
    })
        .sort({ createdAt: -1 })
        .select('-receiverIds -content -__v -senderId -to -bcc -cc -updatedAt');

exports.getEmailById = async (id) => Email.findById(id).select('-senderId -receiverIds -__v -updatedAt');

exports.updateEmail = async (id, data) => Email.findByIdAndUpdate(id, data, { new: true });

exports.deleteEmail = async (id) => Email.findByIdAndDelete(id);

exports.getSentEmails = async (userId) => Email.find({ senderId: userId }).sort({ createdAt: -1 });

exports.getStarredEmails = async (userId) => Email.find({ senderId: userId, starred: true }).sort({ createdAt: -1 });

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
    const { from, to, subject, keywords, hasAttachment, fromDate, toDate , hasAttachments} = req.query;
    const query = {
        $and: [
            { isInTrash: false },
            {
                $or: [
                    { senderId: userId},
                    { receiverIds: userId},
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
