const express = require('express');
const router = express.Router();
const productReviewController = require('../controllers/defaultController');
const { handleValidationErrors, validatePagination } = require('../middleware/validation');
const { protect } = require('../middleware/auth');

// @route   GET /api/product-reviews
// @desc    Get all product reviews with pagination
// @access  Public
router.get('/', [validatePagination, handleValidationErrors], productReviewController.getAll);

// @route   GET /api/product-reviews/:id
// @desc    Get single product review
// @access  Public
router.get('/:id', productReviewController.getById);

// @route   POST /api/product-reviews
// @desc    Create new product review
// @access  Private
router.post('/', protect, productReviewController.create);

// @route   PUT /api/product-reviews/:id
// @desc    Update product review
// @access  Private
router.put('/:id', protect, productReviewController.update);

// @route   DELETE /api/product-reviews/:id
// @desc    Delete product review
// @access  Private
router.delete('/:id', protect, productReviewController.delete);

module.exports = router;

