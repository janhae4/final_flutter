const express = require('express');
const EmailController = require('../controllers/EmailController');
const { verifyToken } = require('../middlewares/verifyToken');

const router = express.Router();
router.use(verifyToken);

router.get('/search', EmailController.searchEmails);
router.get('/sent', EmailController.getSentEmails);
router.get('/drafts', EmailController.getDrafts);
router.get('/trash', EmailController.getTrash);
router.get('/starred', EmailController.getStarredEmails);
router.get('/labels/:labelId', EmailController.getEmailsByLabel);
router.get('/spams', EmailController.getEmailSpam);

router.get('/:id', EmailController.getEmailById);
router.put('/:id', EmailController.updateEmail);
router.post('/:id/star', EmailController.toggleStar);
router.post('/:id/read', EmailController.markRead);
router.post('/:id/trash', EmailController.moveToTrash);
router.post('/:id/restore', EmailController.restoreFromTrash);
router.patch('/:id/', EmailController.updateEmail);
router.delete('/:id', EmailController.deleteEmail);
router.post('/:id/labels', EmailController.addLabel);
router.delete('/:id/labels/:labelId', EmailController.deleteLabel);

router.post('/', EmailController.createEmail);
router.get('/', EmailController.getAllEmails);

module.exports = router;
