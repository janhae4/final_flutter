const mongoose = require('mongoose')

const emailSchema = new mongoose.Schema({
    senderId: { type: String, selected: false, indexedDB: true },
    sender: { type: String, required: true },
    to: { type: [String], required: true },
    receiverIds: { type: [String], default: [], selected: false },
    cc: { type: [String], default: [] },
    bcc: { type: [String], default: [] },
    subject: { type: String, required: true },
    content: { type: [mongoose.Schema.Types.Mixed], required: true, selected: false },
    plainTextContent: { type: String, required: true, indexedDB: true },
    attachments: { type: [String], default: [] },
    labels: { type: [String], default: [] },
    starred: { type: Boolean, default: false },
    isRead: { type: Boolean, default: false },
    isDraft: { type: Boolean, default: false },
    isInTrash: { type: Boolean, default: false },
}, { timestamps: true });

module.exports = mongoose.model('Email', emailSchema);