const { Stylist } = require('../models');
const asyncHandler = require('../middleware/asyncHandler');
const createBaseController = require('./baseController');

// Get base CRUD operations
const baseController = createBaseController(Stylist, 'Stylist');

// Custom stylist-specific methods
const stylistController = {
  ...baseController,

  // @desc    Get stylists by branch
  // @route   GET /api/stylists/branch/:branchId
  // @access  Public
  getByBranch: asyncHandler(async (req, res) => {
    const stylists = await Stylist.find({ 
      branchId: req.params.branchId,
      isActive: true 
    }).sort('-rating name');

    res.status(200).json({
      success: true,
      count: stylists.length,
      data: stylists
    });
  }),

  // @desc    Get active stylists
  // @route   GET /api/stylists/active
  // @access  Public
  getActive: asyncHandler(async (req, res) => {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;

    const stylists = await Stylist.find({ isActive: true })
      .sort('-rating name')
      .skip(startIndex)
      .limit(limit);

    const total = await Stylist.countDocuments({ isActive: true });

    res.status(200).json({
      success: true,
      count: stylists.length,
      total,
      pagination: {
        page,
        limit,
        pages: Math.ceil(total / limit)
      },
      data: stylists
    });
  }),

  // @desc    Get top rated stylists
  // @route   GET /api/stylists/top-rated
  // @access  Public
  getTopRated: asyncHandler(async (req, res) => {
    const limit = parseInt(req.query.limit, 10) || 10;

    const stylists = await Stylist.find({ 
      isActive: true,
      rating: { $gte: 4 } // Rating 4 or higher
    })
      .sort('-rating -reviewCount')
      .limit(limit);

    res.status(200).json({
      success: true,
      count: stylists.length,
      data: stylists
    });
  }),

  // @desc    Search stylists
  // @route   GET /api/stylists/search
  // @access  Public
  searchStylists: asyncHandler(async (req, res) => {
    const { q, branchId, minRating } = req.query;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;

    let query = { isActive: true };

    // Text search
    if (q) {
      const searchRegex = new RegExp(q, 'i');
      query.$or = [
        { name: searchRegex },
        { experience: searchRegex },
        { specialties: { $in: [searchRegex] } }
      ];
    }

    // Branch filter
    if (branchId) {
      query.branchId = branchId;
    }

    // Rating filter
    if (minRating) {
      query.rating = { $gte: parseFloat(minRating) };
    }

    const stylists = await Stylist.find(query)
      .sort('-rating name')
      .skip(startIndex)
      .limit(limit);

    const total = await Stylist.countDocuments(query);

    res.status(200).json({
      success: true,
      count: stylists.length,
      total,
      pagination: {
        page,
        limit,
        pages: Math.ceil(total / limit)
      },
      data: stylists
    });
  }),

  // @desc    Update stylist specialties
  // @route   PATCH /api/stylists/:id/specialties
  // @access  Private
  updateSpecialties: asyncHandler(async (req, res) => {
    const { specialties } = req.body;

    if (!Array.isArray(specialties)) {
      return res.status(400).json({
        success: false,
        error: 'Specialties must be an array'
      });
    }

    const stylist = await Stylist.findByIdAndUpdate(
      req.params.id,
      { specialties },
      { new: true, runValidators: true }
    );

    if (!stylist) {
      return res.status(404).json({
        success: false,
        error: 'Stylist not found'
      });
    }

    res.status(200).json({
      success: true,
      data: stylist
    });
  }),

  // @desc    Toggle stylist status
  // @route   PATCH /api/stylists/:id/toggle-status
  // @access  Private
  toggleStatus: asyncHandler(async (req, res) => {
    const stylist = await Stylist.findById(req.params.id);

    if (!stylist) {
      return res.status(404).json({
        success: false,
        error: 'Stylist not found'
      });
    }

    stylist.isActive = !stylist.isActive;
    await stylist.save();

    res.status(200).json({
      success: true,
      data: stylist
    });
  }),

  // @desc    Get stylist statistics
  // @route   GET /api/stylists/:id/stats
  // @access  Private
  getStylistStats: asyncHandler(async (req, res) => {
    const stylist = await Stylist.findById(req.params.id);

    if (!stylist) {
      return res.status(404).json({
        success: false,
        error: 'Stylist not found'
      });
    }

    // You can add more statistics here like bookings count, revenue, etc.
    res.status(200).json({
      success: true,
      data: {
        stylist,
        rating: stylist.rating,
        reviewCount: stylist.reviewCount,
        specialtiesCount: stylist.specialties.length
      }
    });
  })
};

module.exports = stylistController;
