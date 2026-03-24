const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');
const { handleValidationErrors, validatePagination } = require('../middleware/validation');
const { protect, authorize } = require('../middleware/auth');

// @route   GET /api/categories
// @desc    Get all categories with pagination
// @access  Public
router.get('/', [validatePagination, handleValidationErrors], categoryController.getAll);

// @route   GET /api/categories/:id
// @desc    Get single category
// @access  Public
router.get('/:id', categoryController.getById);

// @route   POST /api/categories
// @desc    Create new category
// @access  Private
router.post('/', protect, authorize('admin'), categoryController.create);

// @route   PUT /api/categories/:id
// @desc    Update category
// @access  Private
router.put('/:id', protect, authorize('admin'), categoryController.update);

// @route   DELETE /api/categories/:id
// @desc    Delete category
// @access  Private
router.delete('/:id', protect, authorize('admin'), categoryController.delete);

module.exports = router;

