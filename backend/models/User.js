const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const userSchema = new mongoose.Schema({
    phone: { type: String, required: true, unique: true, indexedDB: true },
    password: { type: String, required: true, select: false },
    email: { type: String, unique: true, indexedDB: true },
    name: String,
    birthDate: Date,
    avatarUrl: String,
    twoFactorSecret: { type: String, default: null, select: false },
    twoStepVerification: { type: Boolean, default: false },
    backupCodes: {
        type: [
            {
                code: String,
                used: { type: Boolean, default: false },
            },
        ],
        select: false
    }
}, { timestamps: true });

userSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();

    try {
        const salt = await bcrypt.genSalt(10);
        this.password = await bcrypt.hash(this.password, salt);
        next();
    } catch (err) {
        next(err);
    }
})

userSchema.methods.comparePassword = async function (candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

userSchema.methods.generateBackupCodes = function () {
    const codes = [];
    for (let i = 0; i < 10; i++) {
        const code = Math.random().toString(36).substring(2, 8).toUpperCase();
        codes.push({ code, used: false });
    }
    this.backupCodes = codes;
    return codes.map(c => c.code);
};

module.exports = mongoose.model('User', userSchema);

