const Email = require('../models/Email');
const EmailService = require('../services/EmailService');

exports.createEmail = async (req, res) => {
    try {
        const email = await EmailService.createEmail(req.user.id, req.body);
        res.status(201).json(email);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};


exports.updateEmail = async (req, res) => {
    try {
        const email = await EmailService.updateEmail(req.params.id, req.body);
        if (!email) return res.status(404).json({ message: 'Email not found' });
        console.log(email);     
        res.json(email);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

exports.getAllEmails = async (req, res) => {
    try {
        console.log(req.user.id);
        const emails = await EmailService.getAllEmails(req.user.id);
        res.json(emails);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getEmailById = async (req, res) => {
    try {
        const email = await EmailService.getEmailById(req.params.id);
        if (!email) return res.status(404).json({ message: 'Email not found' });
        res.json(email);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.updateEmail = async (req, res) => {
    try {
        const email = await EmailService.updateEmail(req.params.id, req.body);
        if (!email) return res.status(404).json({ message: 'Email not found' });
        res.json(email);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

exports.deleteEmail = async (req, res) => {
    try {
        const email = await EmailService.deleteEmail(req.params.id);
        if (!email) return res.status(404).json({ message: 'Email not found' });
        res.json({ message: 'Email deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.sendEmail = async (req, res) => {
    try {
        const email = await EmailService.sendEmail(req.body);
        res.json(email);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getSentEmails = async (req, res) => {
    try {
        const emails = await EmailService.getSentEmails(req.user.id, req.body);
        res.json(emails);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

exports.getStarredEmails = async (req, res) => {
    try {
        const emails = await EmailService.getStarredEmails(req.user.id);
        res.json(emails);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

exports.getDrafts = async (req, res) => {
    try {
        const emails = await EmailService.getDrafts(req.user.id);
        res.json(emails);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

exports.getTrash = async (req, res) => {
    try {
        const emails = await EmailService.getTrash(req.user.id);
        res.json(emails);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

exports.toggleStar = async (req, res) => {
    try {
        const email = await EmailService.toggleStar(req.params.id);
        res.json(email);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

exports.markRead = async (req, res) => {
    try {
        const email = await EmailService.markRead(req.params.id);
        res.json(email);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

exports.moveToTrash = async (req, res) => {
    try {
        const email = await EmailService.moveToTrash(req.params.id);
        res.json(email);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

exports.restoreFromTrash = async (req, res) => {
    try {
        const email = await EmailService.restoreEmail(req.params.id);
        res.json(email);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

exports.searchEmails = async (req, res) => {
    try {
        let email;
        if (req.query.query) {
            email = await EmailService.searchEmails(req.user.id, req.query.query);
        }
        else {
            email = await EmailService.advancedSearch(req.user.id, req);
        }
        res.json(email);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.addLabel = async (req, res) => {
    try {
        const email = await EmailService.addLabelToEmail(req.params.id, req.body);
        res.json(email);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.deleteLabel = async (req, res) => {
    try {
        const email = await EmailService.removeLabelFromEmail(req.params.id, req.params.labelId);
        res.json(email);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getEmailsByLabel = async (req, res) => {
    try {
        const emails = await EmailService.getEmailsByLabel(req.user.id, req.params.labelId);
        res.json(emails);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getEmailSpam = async (req, res) => {
    try {
        const emails = await EmailService.getEmailSpam(req.user.id);
        res.json(emails);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};