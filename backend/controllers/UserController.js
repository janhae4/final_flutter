const { base } = require('../models/User');
const UserService = require('../services/UserService');

require('dotenv').config();

exports.createUser = async (req, res) => {
    try {
        const user = await UserService.createUser(req.body);
        res.status(201).json(user);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

exports.getAllUsers = async (req, res) => {
    try {
        const users = await UserService.getAllUsers();
        res.json(users);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getUser = async (req, res) => {
    try {
        console.log("===============")
        console.log(req.user.id)
        const user = await UserService.getUser(req.user.id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.json({ user });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.updateUser = async (req, res) => {
    try {
        const user = await UserService.updateUser(req.user.id, req.body);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json({ user });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.deleteUser = async (req, res) => {
    try {
        const user = await UserService.deleteUser(req.params.id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.json({ message: 'User deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.login = async (req, res) => {
    try {
        const result = await UserService.login(req.body.username, req.body.password);
        res.json(result);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.register = async (req, res) => {
    try {
        const user = await UserService.createUser(req.body);
        res.status(201).json(user);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
}

exports.changePassword = async (req, res) => {
    try {
        const user = await UserService.changePassword(req.user.id, req.body);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json({ message: 'Password changed successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.generate2FA = async (req, res) => {
    try {
        const user = await UserService.setup2FA(req.user.id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

exports.enable2FA = async (req, res) => {
    try {
        const r = await UserService.enable2FA(req.user.id, req.body.code);
        res.status(200).json({ backupCodes: r });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

exports.verify2FA = async (req, res) => {
    try {
        const user = await UserService.verify2FA(req.user.id, req.body.code);
        res.status(200).json({ message: '2FA verification successful', token: user.token });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

exports.disable2FA = async (req, res) => {
    try {
        const user = await UserService.disable2FA(req.user.id, req.body.password, req.body.code);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json({ message: '2FA disabled successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

exports.uploadImageToBackend = async (req, res) => {
    try {
        const user = await UserService.uploadImageToBackend(req.user.id, req.file.path);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json({ message: 'Image uploaded successfully', user });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

exports.getAllLabels = async (req, res) => {
    try {
        const labels = await UserService.getAllLabels(req.user.id);
        res.json(labels);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.createLabel = async (req, res) => {
    try {
        const label = await UserService.createLabel(req.user.id, req.body);
        res.status(201).json(label);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.updateLabel = async (req, res) => {
    try {
        const label = await UserService.updateLabel(req.user.id, req.params.id, req.body);
        if (!label) {
            return res.status(404).json({ message: 'Label not found' });
        }
        res.json(label);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.deleteLabel = async (req, res) => {
    try {
        const label = await UserService.deleteLabel(req.user.id, req.params.id);
        if (!label) {
            return res.status(404).json({ message: 'Label not found' });
        }
        res.json({ message: 'Label deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};