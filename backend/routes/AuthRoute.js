const UserController = require('../controllers/UserController');
const express = require('express');
const router = express.Router();
const { verifyToken, verifyAnyToken } = require('../middlewares/verifyToken');
const upload = require('../middlewares/multer');

router.post("/login", UserController.login);
router.post("/register", UserController.register);
router.get("/profile", verifyToken, UserController.getUser);
router.put("/profile", verifyToken, UserController.updateUser);
router.put("/password", verifyToken, UserController.changePassword);
router.post("/recovery-password", verifyToken, UserController.recoveryPassword);
router.post("/generate-2fa", verifyToken, UserController.generate2FA);
router.post("/enable-2fa", verifyToken, UserController.enable2FA);
router.post("/verify-2fa", verifyAnyToken, UserController.verify2FA);
router.post("/disable-2fa", verifyToken, UserController.disable2FA);
router.post("/upload-profile-picture", verifyToken, upload.single('profile_picture'), UserController.uploadImageToBackend);


router.get("/labels", verifyToken, UserController.getAllLabels);
router.post("/labels", verifyToken, UserController.createLabel);
router.put("/labels/:id", verifyToken, UserController.updateLabel);
router.delete("/labels/:id", verifyToken, UserController.deleteLabel);
module.exports = router;