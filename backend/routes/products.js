const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { validateProduct, handleValidationErrors, validatePagination } = require('../middleware/validation');
const { protect, authorize } = require('../middleware/auth');

// @route   GET /api/products
// @desc    Get all products with pagination
// @access  Public
router.get('/', [validatePagination, handleValidationErrors], productController.getAll);

// @route   GET /api/products/:id
// @desc    Get single product
// @access  Public
router.get('/:id', productController.getById);

// @route   POST /api/products
// @desc    Create new product
// @access  Private
router.post('/', protect, authorize('admin'), [validateProduct, handleValidationErrors], productController.create);

// @route   PUT /api/products/:id
// @desc    Update product
// @access  Private
router.put('/:id', protect, authorize('admin'), [validateProduct, handleValidationErrors], productController.update);

// @route   DELETE /api/products/:id
// @desc    Delete product
// @access  Private
router.delete('/:id', protect, authorize('admin'), productController.delete);

module.exports = router;

