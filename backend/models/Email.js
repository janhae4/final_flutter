const mongoose = require('mongoose')

const emailSchema = new mongoose.Schema({
    senderId: { type: String, select: false, index: true },
    sender: { type: String, required: true },
    to: { type: [String], required: true },
    receiverIds: { type: [String], default: [], select: false },
    cc: { type: [String], default: [], select: false },
    bcc: { type: [String], default: [], select: false },
    subject: { type: String, required: true },
    content: { type: [mongoose.Schema.Types.Mixed], required: true, select: false },
    plainTextContent: { type: String, required: true, index: true },
    attachments: { type: [{ name: String, path: String, data: String }], default: [], select: false },
    attachmentsCount: { type: Number, default: 0 },
    labels: [{
        _id: { type: String, required: true, index: true },
        label: { type: String, required: true },
        color: { type: String, default: '#000000' },
    }, { _id: false }],
    originalEmailId: { type: String, default: null, select: false },
    isReplied: { type: Boolean, default: false, select: false },
    isForwarded: { type: Boolean, default: false, select: false },
    starred: { type: Boolean, default: false },
    isRead: { type: Boolean, default: false},
    isDraft: { type: Boolean, default: false, select: false },
    isInTrash: { type: Boolean, default: false, select: false },
    isSpam: { type: Boolean, default: false, select: false },
}, { timestamps: true });

module.exports = mongoose.model('Email', emailSchema);