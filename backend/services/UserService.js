const User = require('../models/User');

exports.getAllUsers = async () => User.find();

exports.getUser = async (id) => User.findById(id);

exports.createUser = async (data) => {
    if (await User.findOne({ phone: data.phone })) throw new Error('Phone number already exists');
    if (await User.findOne({ email: data.email })) throw new Error('Email already exists');
    return User.create(data);
}

exports.updateUser = async (id, data) => User.findByIdAndUpdate(id, data);

exports.deleteUser = async (id) => User.findByIdAndDelete(id);

exports.login = async (username, password) => {
    const user = await User.findOne({ 
        $or: [{ phone: username }, { email: username }]
    });
    if (!user) throw new Error('User not found');
    if (user.password !== password) throw new Error('Invalid password');
    return user;
};

exports.getUserByPhone = async (phone) => User.findOne({ phone });

exports.getUserByEmail = async (email) => User.findOne({ email });

