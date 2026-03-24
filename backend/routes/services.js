const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/serviceController');
const { validateService, handleValidationErrors, validatePagination } = require('../middleware/validation');
const { protect } = require('../middleware/auth');

// @route   GET /api/services
// @desc    Get all services with pagination
// @access  Public
router.get('/', [validatePagination, handleValidationErrors], serviceController.getAll);

// @route   GET /api/services/:id
// @desc    Get single service
// @access  Public
router.get('/:id', serviceController.getById);

// @route   POST /api/services
// @desc    Create new service
// @access  Private
router.post('/', protect, [validateService, handleValidationErrors], serviceController.create);

// @route   PUT /api/services/:id
// @desc    Update service
// @access  Private
router.put('/:id', protect, [validateService, handleValidationErrors], serviceController.update);

// @route   DELETE /api/services/:id
// @desc    Delete service
// @access  Private
router.delete('/:id', protect, serviceController.delete);

module.exports = router;

