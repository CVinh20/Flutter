const { Rating, Service, Stylist } = require('../models');
const asyncHandler = require('../middleware/asyncHandler');
const createBaseController = require('./baseController');

// Get base CRUD operations
const baseController = createBaseController(Rating, 'Rating');

// Custom rating-specific methods
const ratingController = {
  ...baseController,

  // @desc    Get ratings by service
  // @route   GET /api/ratings/service/:serviceId
  // @access  Public
  getByService: asyncHandler(async (req, res) => {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;

    const ratings = await Rating.find({ serviceId: req.params.serviceId })
      .sort('-createdAt')
      .skip(startIndex)
      .limit(limit);

    const total = await Rating.countDocuments({ serviceId: req.params.serviceId });

    res.status(200).json({
      success: true,
      count: ratings.length,
      total,
      pagination: {
        page,
        limit,
        pages: Math.ceil(total / limit)
      },
      data: ratings
    });
  }),

  // @desc    Get ratings by stylist
  // @route   GET /api/ratings/stylist/:stylistId
  // @access  Public
  getByStylist: asyncHandler(async (req, res) => {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;

    const ratings = await Rating.find({ stylistId: req.params.stylistId })
      .sort('-createdAt')
      .skip(startIndex)
      .limit(limit);

    const total = await Rating.countDocuments({ stylistId: req.params.stylistId });

    res.status(200).json({
      success: true,
      count: ratings.length,
      total,
      pagination: {
        page,
        limit,
        pages: Math.ceil(total / limit)
      },
      data: ratings
    });
  }),

  // @desc    Get ratings by user
  // @route   GET /api/ratings/user/:userId
  // @access  Private
  getByUser: asyncHandler(async (req, res) => {
    const ratings = await Rating.find({ userId: req.params.userId })
      .sort('-createdAt');

    res.status(200).json({
      success: true,
      count: ratings.length,
      data: ratings
    });
  }),

  // @desc    Create rating and update related entities
  // @route   POST /api/ratings
  // @access  Private
  createRating: asyncHandler(async (req, res) => {
    // Check if rating already exists for this booking
    const existingRating = await Rating.findOne({ bookingId: req.body.bookingId });
    
    if (existingRating) {
      return res.status(400).json({
        success: false,
        error: 'Rating already exists for this booking'
      });
    }

    const rating = await Rating.create(req.body);

    // Update service rating
    await updateServiceRating(req.body.serviceId);
    
    // Update stylist rating
    await updateStylistRating(req.body.stylistId);

    res.status(201).json({
      success: true,
      data: rating
    });
  }),

  // @desc    Update rating and related entities
  // @route   PUT /api/ratings/:id
  // @access  Private
  updateRating: asyncHandler(async (req, res) => {
    const rating = await Rating.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!rating) {
      return res.status(404).json({
        success: false,
        error: 'Rating not found'
      });
    }

    // Update service rating
    await updateServiceRating(rating.serviceId);
    
    // Update stylist rating
    await updateStylistRating(rating.stylistId);

    res.status(200).json({
      success: true,
      data: rating
    });
  }),

  // @desc    Get rating statistics for service
  // @route   GET /api/ratings/service/:serviceId/stats
  // @access  Public
  getServiceStats: asyncHandler(async (req, res) => {
    const stats = await Rating.aggregate([
      { $match: { serviceId: req.params.serviceId } },
      {
        $group: {
          _id: null,
          averageRating: { $avg: '$rating' },
          totalRatings: { $sum: 1 },
          ratingDistribution: {
            $push: '$rating'
          }
        }
      }
    ]);

    if (stats.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          averageRating: 0,
          totalRatings: 0,
          ratingDistribution: {}
        }
      });
    }

    const distribution = {};
    for (let i = 1; i <= 5; i++) {
      distribution[i] = stats[0].ratingDistribution.filter(r => Math.floor(r) === i).length;
    }

    res.status(200).json({
      success: true,
      data: {
        averageRating: Math.round(stats[0].averageRating * 10) / 10,
        totalRatings: stats[0].totalRatings,
        ratingDistribution: distribution
      }
    });
  })
};

// Helper function to update service rating
async function updateServiceRating(serviceId) {
  const ratings = await Rating.find({ serviceId });
  
  if (ratings.length > 0) {
    const totalRating = ratings.reduce((sum, rating) => sum + rating.rating, 0);
    const averageRating = totalRating / ratings.length;
    
    await Service.findByIdAndUpdate(serviceId, {
      rating: Math.round(averageRating * 10) / 10,
      reviewCount: ratings.length
    });
  }
}

// Helper function to update stylist rating
async function updateStylistRating(stylistId) {
  const ratings = await Rating.find({ stylistId });
  
  if (ratings.length > 0) {
    const totalRating = ratings.reduce((sum, rating) => sum + rating.rating, 0);
    const averageRating = totalRating / ratings.length;
    
    await Stylist.findByIdAndUpdate(stylistId, {
      rating: Math.round(averageRating * 10) / 10,
      reviewCount: ratings.length
    });
  }
}

module.exports = ratingController;
