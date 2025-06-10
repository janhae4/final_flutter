const { default: axios } = require("axios")

exports.checkHealth = async(req, res) => {
    try {
        await axios.get('https://final-flutter-ml.onrender.com/');
        res.status(200).json({ message: 'Success' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
}