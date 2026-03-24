const express = require('express');
const router = express.Router();
const defaultController = require('../controllers/defaultController');
const { handleValidationErrors, validatePagination } = require('../middleware/validation');
const { protect } = require('../middleware/auth');

// @route   GET /api/ratings
// @desc    Get all ratings with pagination
// @access  Public
router.get('/', [validatePagination, handleValidationErrors], defaultController.getAll);

// @route   GET /api/ratings/:id
// @desc    Get single rating
// @access  Public
router.get('/:id', defaultController.getById);

// @route   POST /api/ratings
// @desc    Create new rating
// @access  Private
router.post('/', protect, defaultController.create);

// @route   PUT /api/ratings/:id
// @desc    Update rating
// @access  Private
router.put('/:id', protect, defaultController.update);

// @route   DELETE /api/ratings/:id
// @desc    Delete rating
// @access  Private
router.delete('/:id', protect, defaultController.delete);

module.exports = router;

