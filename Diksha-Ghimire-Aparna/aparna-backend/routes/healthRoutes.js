const express = require('express');
const router = express.Router();
const healthController = require('../controller/healthController');
const authenticateToken = require('../middleware/jwtmiddleware');

// Debug endpoint - no auth required
router.post('/test', (req, res) => {
  console.log('✅ /health/test endpoint hit');
  res.status(200).json({ message: 'test endpoint works', body: req.body });
});

// DEBUG: Insert test sleep data (no auth for testing)
router.post('/test-sleep/:userId', healthController.insertTestSleepData);

// Auth required for recording health data
router.post('/record', authenticateToken, healthController.recordHealthData);
router.get('/:userId', authenticateToken, healthController.getHealthData);
router.put('/:userId', authenticateToken, healthController.updateHealthData);
router.delete('/:userId', authenticateToken, healthController.deleteHealthData);

module.exports = router;