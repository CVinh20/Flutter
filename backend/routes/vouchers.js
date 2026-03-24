const express = require('express');
const router = express.Router();
const voucherController = require('../controllers/voucherController');
const { validateVoucher, handleValidationErrors, validatePagination } = require('../middleware/validation');
const { protect, authorize } = require('../middleware/auth');

// @route   GET /api/vouchers/active
// @desc    Get active vouchers
// @access  Public
router.get('/active', voucherController.getActive);

// @route   POST /api/vouchers/validate
// @desc    Validate voucher code
// @access  Public
router.post('/validate', voucherController.validateVoucher);

// @route   POST /api/vouchers/apply
// @desc    Apply voucher
// @access  Private
router.post('/apply', protect, voucherController.applyVoucher);

// @route   GET /api/vouchers/code/:code
// @desc    Get voucher by code
// @access  Public
router.get('/code/:code', voucherController.getByCode);

// @route   GET /api/vouchers
// @desc    Get all vouchers with pagination
// @access  Public
router.get('/', [validatePagination, handleValidationErrors], voucherController.getAll);

// @route   GET /api/vouchers/:id
// @desc    Get single voucher
// @access  Public
router.get('/:id', voucherController.getById);

// @route   POST /api/vouchers
// @desc    Create new voucher
// @access  Private
router.post('/', protect, authorize('admin'), [validateVoucher, handleValidationErrors], voucherController.create);

// @route   PUT /api/vouchers/:id
// @desc    Update voucher
// @access  Private
router.put('/:id', protect, authorize('admin'), [validateVoucher, handleValidationErrors], voucherController.update);

// @route   DELETE /api/vouchers/:id
// @desc    Delete voucher
// @access  Private
router.delete('/:id', protect, authorize('admin'), voucherController.delete);

module.exports = router;

