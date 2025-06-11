const User = require('../models/User');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const QRCode = require('qrcode');
const speakeasy = require('speakeasy');

const generateToken = (user, day = '7d', purpose = 'auth') => {
    return jwt.sign(
        { id: user._id, email: user.email, purpose },
        process.env.JWT_SECRET,
        { expiresIn: day }
    );
};

exports.getAllUsers = async () => User.find();

exports.getUser = async (id) => User.findById(id);

exports.createUser = async (data) => {
    if (await User.findOne({ phone: data.username })) throw new Error('Phone number already exists');
    const email = `${data.username}@gmail.com`;
    return User.create({
        name: data.name,
        phone: data.username,
        password: data.password,
        email
    });
}

exports.updateUser = async (id, data) => {
    const user = await User.findById(id);
    if (!user) throw new Error('User not found');
    if (user.email !== data.email && await User.findOne({ email: data.email })) throw new Error('Email already exists');
    if (user.phone !== data.phone && await User.findOne({ phone: data.phone })) throw new Error('Phone number already exists');
    console.log(data);
    return User.findByIdAndUpdate(id, data, { new: true });
};

exports.changePassword = async (id, data) => {
    const user = await User.findById(id).select('+password');
    if (!user) throw new Error('User not found');

    const isMatch = await bcrypt.compare(data.oldPassword, user.password);
    if (!isMatch) throw new Error('Invalid password');

    const isSameAsOld = await bcrypt.compare(data.newPassword, user.password);
    if (isSameAsOld) throw new Error('New password cannot be the same as the old password');

    user.password = data.newPassword;
    return user.save();
}

exports.deleteUser = async (id) => User.findByIdAndDelete(id);

exports.login = async (username, password) => {
    const user = await User.findOne({
        $or: [{ phone: username }, { email: username }]
    }).select('+password');
    console.log(user);
    if (!user) throw new Error('User not found');
    const isPasswordValid = await user.comparePassword(password);
    console.log(isPasswordValid);
    if (!isPasswordValid) throw new Error('Invalid password');
    if (!user.twoStepVerification) return { token: generateToken(user) };

    const tempToken = generateToken(user, '5m', '2FA');
    return {
        require2FA: true,
        tempToken,
        message: '2FA required'
    }
};

const generatePassword = () => {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$!';
    let password = '';
    for (let i = 0; i < 10; i++) {
        password += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return password;
};

exports.recoveryPassword = async (userId, otp) => {
    const user = await User.findById(userId).select('+password +twoFactorSecret');
    if (!user) throw new Error('User not found');
    if (user.twoStepVerification) {
        const verified = speakeasy.totp.verify({
            secret: user.twoFactorSecret,
            encoding: 'base32',
            token: otp.trim(),
            window: 2
        });
        console.log("user", user.email)
        console.log("expected", speakeasy.totp({ secret: user.twoFactorSecret, encoding: 'base32' }));
        if (!verified) throw new Error('Invalid 2FA code');
    }
    const newPassword = generatePassword();

    user.password = newPassword;
    await user.save();

    return newPassword;
};

exports.setup2FA = async (userId) => {
    const user = await User.findById(userId);
    if (!user) throw new Error('User not found');

    const secret = speakeasy.generateSecret({
        name: `GMAIL SIMULATOR`,
        issuer: '2FA App'
    });

    user.twoFactorSecret = secret.base32;
    await user.save();

    return {
        manualEntryKey: secret.base32
    };
};

exports.verify2FA = async (userId, token) => {
    const user = await User.findById(userId).select('+twoFactorSecret +backupCodes');
    if (!user || !user.twoFactorSecret) throw new Error('No 2FA setup found');

    const trimmedToken = token.trim();
    const isNumeric = /^\d+$/.test(trimmedToken);

    if (isNumeric) {
        const verified = speakeasy.totp.verify({
            secret: user.twoFactorSecret,
            encoding: 'base32',
            token: trimmedToken,
            window: 2,
        });
        if (!verified) {
            throw new Error('Invalid OTP code');
        }
    } else {
        const codeIndex = user.backupCodes.findIndex(
            (c) => c.code === trimmedToken && !c.used
        );

        if (codeIndex === -1) {
            throw new Error('Invalid or already used backup code');
        }
        user.backupCodes[codeIndex].used = true;
        await user.save();
    }
    return { token: generateToken(user) };
};


exports.enable2FA = async (userId, token) => {
    const user = await User.findById(userId).select('+twoFactorSecret');
    if (!user || !user.twoFactorSecret) throw new Error('No 2FA setup found');
    const verified = speakeasy.totp.verify({
        secret: user.twoFactorSecret,
        encoding: 'base32',
        token: token.trim(),
        window: 2
    });

    if (!verified) throw new Error('Invalid verification code');

    user.twoStepVerification = true;
    const backupCodes = user.generateBackupCodes();
    await user.save();
    return backupCodes;
};

exports.disable2FA = async (userId, password, code) => {
    const user = await User.findById(userId).select('+twoFactorSecret +password');
    if (!user) throw new Error('User not found');

    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) throw new Error('Invalid password');

    const verified = speakeasy.totp.verify({
        secret: user.twoFactorSecret,
        encoding: 'base32',
        token: code,
        window: 2
    });

    if (!verified) throw new Error('Invalid 2FA code');

    user.twoStepVerification = false;
    user.twoFactorSecret = null;
    user.backupCodes = [];
    await user.save();

    return true;
};


exports.getUserByPhone = async (phone) => User.findOne({ phone });

exports.getUserByEmail = async (email) => User.findOne({ email });

exports.uploadImageToBackend = async (userId, path) => {
    const replacePath = path.replace(/\\/g, '/');
    return await User.findByIdAndUpdate(userId, { avatarUrl: replacePath }, { new: true });
}

exports.createLabel = async (userId, label) => await User.findByIdAndUpdate(
    userId,
    { $push: { labels: label } },
    { new: true }
).select('labels');

exports.getLabels = async (userId) => await User.findById(userId)
    .select('labels')
    .then(user => user.labels || [])
    .catch(() => []);

exports.updateLabel = async (userId, labelId, newLabel) => await User.findOneAndUpdate(
    { _id: userId, "labels._id": labelId },
    { $set: { "labels.$.label": newLabel.newLabel } },
    { new: true }
).select('labels');

exports.deleteLabel = async (userId, labelId) =>
    await User.findByIdAndUpdate(
        userId,
        { $pull: { labels: { _id: labelId } } },
        { new: true }
    ).select('labels');