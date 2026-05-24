const express = require('express');
const router = express.Router();
const aamaController = require('../controller/aama');
const authenticateToken = require('../middleware/jwtmiddleware');

// Aama chatbot routes
router.post('/chat', authenticateToken, aamaController.sendMessage);
router.post('/storeChat', authenticateToken, aamaController.storeChatMessage);
router.get('/chathistory', authenticateToken, aamaController.getChatHistory);
router.post('/greeting', authenticateToken, aamaController.getGreeting);
router.get('/health', aamaController.checkHealth);

module.exports = router;