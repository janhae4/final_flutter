const User = require('../models/User');

exports.getAllUsers = async () => User.find();

exports.getUser = async (id) => User.findById(id);

exports.createUser = async (data) => {
    if (await User.findOne({ username: data.username })) throw new Error('Phone number already exists');
    if (await User.findOne({ email: data.email })) throw new Error('Email already exists');
    const email = `${data.username}@gmail.com`;
    return User.create({
        phone: data.username,
        password: data.password,
        email
    });
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

