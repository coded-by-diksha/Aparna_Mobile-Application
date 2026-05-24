const express = require('express');
const router = express.Router();
const cycleController = require('../controller/cycleController');
const authenticateToken = require('../middleware/jwtmiddleware');

// All cycle routes require authentication
router.use(authenticateToken);

// Main API
router.post('/record', cycleController.recordPeriod);
router.post('/daily-log', cycleController.addDailyLog);
router.post('/adjust-prediction', cycleController.adjustPrediction);
router.get('/history', cycleController.getHistory);
router.get('/prediction', cycleController.getPrediction);
router.delete('/:id', cycleController.deletePeriod);

// Legacy-style endpoints (same paths as before under /cycles so URIs stay consistent)
router.post('/startCycle', cycleController.startCycle);
router.get('/cycles/:uid', cycleController.getCyclesByUser);
router.get('/startdate/:cid', cycleController.getStartDate);
router.post('/setEndDate', cycleController.setEndDate);
router.get('/endDate/:cid', cycleController.getEndDate);
router.get('/patterns/:cid', cycleController.getPatterns);
router.post('/deletecycle/:cid', cycleController.deleteCycle);

module.exports = router;
