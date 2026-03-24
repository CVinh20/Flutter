const { UserVoucher, Voucher } = require('../models');
const asyncHandler = require('../middleware/asyncHandler');
const createBaseController = require('./baseController');

// Get base CRUD operations
const baseController = createBaseController(UserVoucher, 'UserVoucher');

// Custom user voucher-specific methods
const userVoucherController = {
  ...baseController,

  // @desc    Get user vouchers
  // @route   GET /api/user-vouchers/user/:userId
  // @access  Private
  getByUser: asyncHandler(async (req, res) => {
    const { userId } = req.params;
    const { status } = req.query; // 'used', 'unused', 'all'

    let query = { userId };

    if (status === 'used') {
      query.isUsed = true;
    } else if (status === 'unused') {
      query.isUsed = false;
    }

    const userVouchers = await UserVoucher.find(query)
      .sort('-claimedAt');

    // Populate voucher details
    const voucherIds = userVouchers.map(uv => uv.voucherId);
    const vouchers = await Voucher.find({ _id: { $in: voucherIds } });

    const result = userVouchers.map(userVoucher => {
      const voucher = vouchers.find(v => v._id.toString() === userVoucher.voucherId);
      return {
        ...userVoucher.toObject(),
        voucher
      };
    });

    res.status(200).json({
      success: true,
      count: result.length,
      data: result
    });
  }),

  // @desc    Claim voucher for user
  // @route   POST /api/user-vouchers/claim
  // @access  Private
  claimVoucher: asyncHandler(async (req, res) => {
    const { userId, voucherId } = req.body;

    // Check if voucher exists and is active
    const voucher = await Voucher.findById(voucherId);
    
    if (!voucher) {
      return res.status(404).json({
        success: false,
        error: 'Voucher not found'
      });
    }

    if (!voucher.isActive) {
      return res.status(400).json({
        success: false,
        error: 'Voucher is not active'
      });
    }

    const now = new Date();
    if (now < voucher.startDate || now > voucher.endDate) {
      return res.status(400).json({
        success: false,
        error: 'Voucher is not available at this time'
      });
    }

    if (voucher.currentUses >= voucher.maxUses) {
      return res.status(400).json({
        success: false,
        error: 'Voucher usage limit exceeded'
      });
    }

    // Check if user already claimed this voucher
    const existingClaim = await UserVoucher.findOne({ userId, voucherId });
    
    if (existingClaim) {
      return res.status(400).json({
        success: false,
        error: 'You have already claimed this voucher'
      });
    }

    // Create user voucher record
    const userVoucher = await UserVoucher.create({
      userId,
      voucherId,
      claimedAt: new Date()
    });

    res.status(201).json({
      success: true,
      data: userVoucher
    });
  }),

  // @desc    Use voucher
  // @route   PATCH /api/user-vouchers/:id/use
  // @access  Private
  useVoucher: asyncHandler(async (req, res) => {
    const { bookingId } = req.body;

    const userVoucher = await UserVoucher.findById(req.params.id);

    if (!userVoucher) {
      return res.status(404).json({
        success: false,
        error: 'User voucher not found'
      });
    }

    if (userVoucher.isUsed) {
      return res.status(400).json({
        success: false,
        error: 'Voucher has already been used'
      });
    }

    // Update user voucher
    userVoucher.isUsed = true;
    userVoucher.usedAt = new Date();
    userVoucher.usedInBookingId = bookingId;
    await userVoucher.save();

    res.status(200).json({
      success: true,
      data: userVoucher
    });
  }),

  // @desc    Get available vouchers for user
  // @route   GET /api/user-vouchers/available/:userId
  // @access  Private
  getAvailableForUser: asyncHandler(async (req, res) => {
    const { userId } = req.params;
    const now = new Date();

    // Get all active vouchers
    const activeVouchers = await Voucher.find({
      isActive: true,
      startDate: { $lte: now },
      endDate: { $gte: now },
      $expr: { $lt: ['$currentUses', '$maxUses'] }
    });

    // Get user's claimed vouchers
    const claimedVouchers = await UserVoucher.find({ userId });
    const claimedVoucherIds = claimedVouchers.map(uv => uv.voucherId);

    // Filter out already claimed vouchers
    const availableVouchers = activeVouchers.filter(voucher => 
      !claimedVoucherIds.includes(voucher._id.toString())
    );

    res.status(200).json({
      success: true,
      count: availableVouchers.length,
      data: availableVouchers
    });
  }),

  // @desc    Get unused vouchers for user
  // @route   GET /api/user-vouchers/unused/:userId
  // @access  Private
  getUnusedForUser: asyncHandler(async (req, res) => {
    const { userId } = req.params;
    const now = new Date();

    const unusedUserVouchers = await UserVoucher.find({
      userId,
      isUsed: false
    }).sort('-claimedAt');

    // Get voucher details and filter out expired ones
    const voucherIds = unusedUserVouchers.map(uv => uv.voucherId);
    const vouchers = await Voucher.find({
      _id: { $in: voucherIds },
      isActive: true,
      endDate: { $gte: now }
    });

    const result = unusedUserVouchers
      .map(userVoucher => {
        const voucher = vouchers.find(v => v._id.toString() === userVoucher.voucherId);
        if (voucher) {
          return {
            ...userVoucher.toObject(),
            voucher
          };
        }
        return null;
      })
      .filter(item => item !== null);

    res.status(200).json({
      success: true,
      count: result.length,
      data: result
    });
  })
};

module.exports = userVoucherController;
