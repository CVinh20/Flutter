const express = require('express');
const router = express.Router();
const productCategoryController = require('../controllers/productCategoryController');
const { handleValidationErrors, validatePagination } = require('../middleware/validation');
const { protect, authorize } = require('../middleware/auth');

// @route   GET /api/product-categories
// @desc    Get all product categories with pagination
// @access  Public
router.get('/', [validatePagination, handleValidationErrors], productCategoryController.getAll);

// @route   GET /api/product-categories/:id
// @desc    Get single product category
// @access  Public
router.get('/:id', productCategoryController.getById);

// @route   POST /api/product-categories
// @desc    Create new product category
// @access  Private
router.post('/', protect, authorize('admin'), productCategoryController.create);

// @route   PUT /api/product-categories/:id
// @desc    Update product category
// @access  Private
router.put('/:id', protect, authorize('admin'), productCategoryController.update);

// @route   DELETE /api/product-categories/:id
// @desc    Delete product category
// @access  Private
router.delete('/:id', protect, authorize('admin'), productCategoryController.delete);

module.exports = router;

