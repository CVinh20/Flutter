const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { handleValidationErrors, validatePagination } = require('../middleware/validation');
const { protect } = require('../middleware/auth');

// @route   GET /api/orders
// @desc    Get all orders with pagination
// @access  Private
router.get('/', protect, [validatePagination, handleValidationErrors], orderController.getAll);

// @route   GET /api/orders/:id
// @desc    Get single order
// @access  Private
router.get('/:id', protect, orderController.getById);

// @route   POST /api/orders
// @desc    Create new order
// @access  Private
router.post('/', protect, orderController.create);

// @route   PUT /api/orders/:id
// @desc    Update order
// @access  Private
router.put('/:id', protect, orderController.update);

// @route   DELETE /api/orders/:id
// @desc    Delete order
// @access  Private
router.delete('/:id', protect, orderController.delete);

module.exports = router;

