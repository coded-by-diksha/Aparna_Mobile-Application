const express = require('express');
const router = express.Router();

const expertHelpController = require('../controller/expertHelpController');

// Public routes (anyone can see experts)
router.get('/', expertHelpController.getAllExperts);
router.get('/:id', expertHelpController.getExpertById);

// Admin routes (only admins should be able to modify, but keeping it simple for now)
router.post('/', expertHelpController.createExpert);
router.put('/:id', expertHelpController.updateExpert);
router.delete('/:id', expertHelpController.deleteExpert);

module.exports = router;
