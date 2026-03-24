const { Voucher, UserVoucher } = require('../models');
const asyncHandler = require('../middleware/asyncHandler');
const createBaseController = require('./baseController');

// Get base CRUD operations
const baseController = createBaseController(Voucher, 'Voucher');

// Custom voucher-specific methods
const voucherController = {
  ...baseController,

  // @desc    Get active vouchers
  // @route   GET /api/vouchers/active
  // @access  Public
  getActive: asyncHandler(async (req, res) => {
    const now = new Date();
    
    const vouchers = await Voucher.find({
      isActive: true,
      startDate: { $lte: now },
      endDate: { $gte: now },
      $expr: { $lt: ['$currentUses', '$maxUses'] }
    }).sort('-createdAt');

    res.status(200).json({
      success: true,
      count: vouchers.length,
      data: vouchers
    });
  }),

  // @desc    Get vouchers for new users
  // @route   GET /api/vouchers/new-user
  // @access  Public
  getForNewUsers: asyncHandler(async (req, res) => {
    const now = new Date();
    
    const vouchers = await Voucher.find({
      isActive: true,
      isForNewUser: true,
      startDate: { $lte: now },
      endDate: { $gte: now },
      $expr: { $lt: ['$currentUses', '$maxUses'] }
    }).sort('-value');

    res.status(200).json({
      success: true,
      count: vouchers.length,
      data: vouchers
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
        error: 'Voucher code is required'
      });
    }

    const voucher = await Voucher.findOne({ 
      code: code.toUpperCase(),
      isActive: true 
    });

    if (!voucher) {
      return res.status(404).json({
        success: false,
        error: 'Invalid voucher code'
      });
    }

    const now = new Date();

    // Check if voucher is within valid date range
    if (now < voucher.startDate || now > voucher.endDate) {
      return res.status(400).json({
        success: false,
        error: 'Voucher has expired or not yet active'
      });
    }

    // Check if voucher has remaining uses
    if (voucher.currentUses >= voucher.maxUses) {
      return res.status(400).json({
        success: false,
        error: 'Voucher usage limit exceeded'
      });
    }

    // Check minimum amount requirement
    if (voucher.minAmount && orderAmount < voucher.minAmount) {
      return res.status(400).json({
        success: false,
        error: `Minimum order amount is ${voucher.minAmount}`
      });
    }

    // Check if user already used this voucher
    if (userId) {
      const userVoucher = await UserVoucher.findOne({
        userId,
        voucherId: voucher._id,
        isUsed: true
      });

      if (userVoucher) {
        return res.status(400).json({
          success: false,
          error: 'You have already used this voucher'
        });
      }
    }

    // Calculate discount amount
    let discountAmount = 0;
    if (voucher.type === 0) { // Percentage
      discountAmount = (orderAmount * voucher.value) / 100;
    } else { // Fixed amount
      discountAmount = voucher.value;
    }

    // Ensure discount doesn't exceed order amount
    discountAmount = Math.min(discountAmount, orderAmount);

    res.status(200).json({
      success: true,
      data: {
        voucher,
        discountAmount,
        finalAmount: orderAmount - discountAmount
      }
    });
  }),

  // @desc    Apply voucher
  // @route   POST /api/vouchers/apply
  // @access  Private
  applyVoucher: asyncHandler(async (req, res) => {
    const { code, userId, bookingId } = req.body;

    const voucher = await Voucher.findOne({ 
      code: code.toUpperCase(),
      isActive: true 
    });

    if (!voucher) {
      return res.status(404).json({
        success: false,
        error: 'Invalid voucher code'
      });
    }

    // Increment usage count
    voucher.currentUses += 1;
    await voucher.save();

    // Create or update user voucher record
    await UserVoucher.findOneAndUpdate(
      { userId, voucherId: voucher._id },
      {
        isUsed: true,
        usedAt: new Date(),
        usedInBookingId: bookingId
      },
      { upsert: true, new: true }
    );

    res.status(200).json({
      success: true,
      data: voucher
    });
  }),

  // @desc    Get voucher by code
  // @route   GET /api/vouchers/code/:code
  // @access  Public
  getByCode: asyncHandler(async (req, res) => {
    const voucher = await Voucher.findOne({ 
      code: req.params.code.toUpperCase() 
    });

    if (!voucher) {
      return res.status(404).json({
        success: false,
        error: 'Voucher not found'
      });
    }

    res.status(200).json({
      success: true,
      data: voucher
    });
  }),

  // @desc    Get voucher usage statistics
  // @route   GET /api/vouchers/:id/stats
  // @access  Private
  getStats: asyncHandler(async (req, res) => {
    const voucher = await Voucher.findById(req.params.id);

    if (!voucher) {
      return res.status(404).json({
        success: false,
        error: 'Voucher not found'
      });
    }

    const usageRate = (voucher.currentUses / voucher.maxUses) * 100;
    const remainingUses = voucher.maxUses - voucher.currentUses;

    res.status(200).json({
      success: true,
      data: {
        voucher,
        usageRate: Math.round(usageRate * 100) / 100,
        remainingUses
      }
    });
  })
};

module.exports = voucherController;
