const express = require('express');
const router = express.Router();
const profileController = require('../controller/profile');
const authenticateToken = require('../middleware/jwtmiddleware');

// Profile routes
router.get('/:user_id', authenticateToken, profileController.getUserProfile);
router.put('/:user_id', authenticateToken, profileController.updateUserProfile);
router.put('/photo/:user_id', authenticateToken, profileController.uploadMiddleware, profileController.addprofileImage);

module.exports = router;