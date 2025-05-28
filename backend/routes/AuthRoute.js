const UserController = require('../controllers/UserController');
const express = require('express');
const router = express.Router();

router.post("/login", UserController.login);
router.post("/register", UserController.register);
module.exports = router;