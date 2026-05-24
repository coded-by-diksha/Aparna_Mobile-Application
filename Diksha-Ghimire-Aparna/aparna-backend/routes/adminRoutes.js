const express = require('express');
const router = express.Router();
const adminController = require('../controller/admin');
const authenticateToken = require('../middleware/jwtmiddleware');

router.get('/users', authenticateToken, adminController.getAllUsers);
router.post('/users', authenticateToken, adminController.createUserByAdmin);
router.get('/stats', authenticateToken, adminController.getStats);
router.delete('/users/delete/:id', authenticateToken, adminController.deleteUserByID);

module.exports = router;
