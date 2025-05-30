const TrustedDevice = require('../models/TrustedDevice');

exports.savedTrustedDevice = async (userId, deviceId, userAgent, ip) => {
    const existed = await TrustedDevice.findOne({ userId, deviceId });
    if (!existed) return TrustedDevice.create({ userId, deviceId, userAgent, ip });
}