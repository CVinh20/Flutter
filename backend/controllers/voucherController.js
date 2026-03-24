const VoucherService = require('../services/voucherService');
const asyncHandler = require('../middleware/asyncHandler');

// Custom voucher-specific methods
const voucherController = {
  // @desc    Get all vouchers
  // @route   GET /api/vouchers
  // @access  Public
  getAll: asyncHandler(async (req, res) => {
    const includeInactive = req.query.includeInactive === 'true';
    const vouchers = await VoucherService.getAllVouchers(includeInactive);
    
    res.status(200).json({
      success: true,
      count: vouchers.length,
      data: vouchers
    });
  }),

  // @desc    Get voucher by ID
  // @route   GET /api/vouchers/:id
  // @access  Public
  getById: asyncHandler(async (req, res) => {
    const voucher = await VoucherService.getVoucherById(req.params.id);
    
    if (!voucher) {
      return res.status(404).json({
        success: false,
        message: 'Voucher not found'
      });
    }

    res.status(200).json({
      success: true,
      data: voucher
    });
  }),

  // @desc    Create new voucher
  // @route   POST /api/vouchers
  // @access  Private/Admin
  create: asyncHandler(async (req, res) => {
    const voucher = await VoucherService.createVoucher(req.body);
    
    res.status(201).json({
      success: true,
      data: voucher
    });
  }),

  // @desc    Update voucher
  // @route   PUT /api/vouchers/:id
  // @access  Private/Admin
  update: asyncHandler(async (req, res) => {
    const voucher = await VoucherService.updateVoucher(req.params.id, req.body);
    
    if (!voucher) {
      return res.status(404).json({
        success: false,
        message: 'Voucher not found'
      });
    }

    res.status(200).json({
      success: true,
      data: voucher
    });
  }),

  // @desc    Delete voucher
  // @route   DELETE /api/vouchers/:id
  // @access  Private/Admin
  delete: asyncHandler(async (req, res) => {
    const result = await VoucherService.deleteVoucher(req.params.id);
    
    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Voucher not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Voucher deleted successfully'
    });
  }),

  // @desc    Get active vouchers
  // @route   GET /api/vouchers/active
  // @access  Public
  getActive: asyncHandler(async (req, res) => {
    const vouchers = await VoucherService.getActiveVouchers();

    res.status(200).json({
      success: true,
      count: vouchers.length,
      data: vouchers
    });
  }),

  // @desc    Get voucher by code
  // @route   GET /api/vouchers/code/:code
  // @access  Public
  getByCode: asyncHandler(async (req, res) => {
    const voucher = await VoucherService.getVoucherByCode(req.params.code);

    if (!voucher) {
      return res.status(404).json({
        success: false,
        message: 'Voucher not found'
      });
    }

    res.status(200).json({
      success: true,
      data: voucher
    });
  }),

  // @desc    Validate voucher code
  // @route   POST /api/vouchers/validate
  // @access  Public
  validateVoucher: asyncHandler(async (req, res) => {
    const { code, userId, orderAmount } = req.body;

    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'Voucher code is required'
      });
    }

    try {
      const validation = await VoucherService.validateVoucher(code, userId, orderAmount);
      
      res.status(200).json({
        success: true,
        data: validation
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }),

  // @desc    Apply voucher
  // @route   POST /api/vouchers/apply
  // @access  Private
  applyVoucher: asyncHandler(async (req, res) => {
    const { code, userId, bookingId } = req.body;

    try {
      const result = await VoucherService.applyVoucher(code, userId, bookingId);
      
      res.status(200).json({
        success: true,
        data: result
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  })
};

module.exports = voucherController;
