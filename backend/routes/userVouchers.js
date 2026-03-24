const express = require('express');
const router = express.Router();
const userVoucherController = require('../controllers/defaultController');
const { handleValidationErrors, validatePagination } = require('../middleware/validation');
const { protect } = require('../middleware/auth');

// @route   GET /api/user-vouchers
// @desc    Get all user vouchers with pagination
// @access  Private
router.get('/', protect, [validatePagination, handleValidationErrors], userVoucherController.getAll);

// @route   GET /api/user-vouchers/:id
// @desc    Get single user voucher
// @access  Private
router.get('/:id', protect, userVoucherController.getById);

// @route   POST /api/user-vouchers
// @desc    Create new user voucher
// @access  Private
router.post('/', protect, userVoucherController.create);

// @route   PUT /api/user-vouchers/:id
// @desc    Update user voucher
// @access  Private
router.put('/:id', protect, userVoucherController.update);

// @route   DELETE /api/user-vouchers/:id
// @desc    Delete user voucher
// @access  Private
router.delete('/:id', protect, userVoucherController.delete);

module.exports = router;

