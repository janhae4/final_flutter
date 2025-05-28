const UserController = require('../controllers/UserController');
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middlewares/verifyToken');

router.post("/login", UserController.login);
router.post("/register", UserController.register);
router.get("/profile", verifyToken, UserController.getUser);
module.exports = router;