const { Service, Rating } = require('../models');
const asyncHandler = require('../middleware/asyncHandler');
const createBaseController = require('./baseController');

// Get base CRUD operations
const baseController = createBaseController(Service, 'Service');

// Custom service-specific methods
const serviceController = {
  ...baseController,

  // @desc    Get services by category
  // @route   GET /api/services/category/:categoryId
  // @access  Public
  getByCategory: asyncHandler(async (req, res) => {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;

    const services = await Service.find({ 
      categoryId: req.params.categoryId,
      isActive: true 
    })
      .sort('-rating -featuredOrder')
      .skip(startIndex)
      .limit(limit);

    const total = await Service.countDocuments({ 
      categoryId: req.params.categoryId,
      isActive: true 
    });

    res.status(200).json({
      success: true,
      count: services.length,
      total,
      pagination: {
        page,
        limit,
        pages: Math.ceil(total / limit)
      },
      data: services
    });
  }),

  // @desc    Get featured services
  // @route   GET /api/services/featured
  // @access  Public
  getFeatured: asyncHandler(async (req, res) => {
    const limit = parseInt(req.query.limit, 10) || 10;

    const services = await Service.find({ 
      isFeatured: true,
      isActive: true 
    })
      .sort('featuredOrder -rating')
      .limit(limit);

    res.status(200).json({
      success: true,
      count: services.length,
      data: services
    });
  }),

  // @desc    Search services
  // @route   GET /api/services/search
  // @access  Public
  searchServices: asyncHandler(async (req, res) => {
    const { q, minPrice, maxPrice, category } = req.query;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;

    let query = { isActive: true };

    // Text search
    if (q) {
      const searchRegex = new RegExp(q, 'i');
      query.$or = [
        { name: searchRegex },
        { categoryName: searchRegex },
        { description: searchRegex }
      ];
    }

    // Price range filter
    if (minPrice || maxPrice) {
      query.price = {};
      if (minPrice) query.price.$gte = parseFloat(minPrice);
      if (maxPrice) query.price.$lte = parseFloat(maxPrice);
    }

    // Category filter
    if (category) {
      query.categoryId = category;
    }

    const services = await Service.find(query)
      .sort('-rating -createdAt')
      .skip(startIndex)
      .limit(limit);

    const total = await Service.countDocuments(query);

    res.status(200).json({
      success: true,
      count: services.length,
      total,
      pagination: {
        page,
        limit,
        pages: Math.ceil(total / limit)
      },
      data: services
    });
  }),

  // @desc    Update service rating
  // @route   PATCH /api/services/:id/rating
  // @access  Private
  updateRating: asyncHandler(async (req, res) => {
    const serviceId = req.params.id;

    // Calculate average rating from ratings
    const ratings = await Rating.find({ serviceId });
    
    if (ratings.length === 0) {
      return res.status(200).json({
        success: true,
        message: 'No ratings found for this service'
      });
    }

    const totalRating = ratings.reduce((sum, rating) => sum + rating.rating, 0);
    const averageRating = totalRating / ratings.length;

    const service = await Service.findByIdAndUpdate(
      serviceId,
      { 
        rating: Math.round(averageRating * 10) / 10, // Round to 1 decimal place
        reviewCount: ratings.length 
      },
      { new: true }
    );

    if (!service) {
      return res.status(404).json({
        success: false,
        error: 'Service not found'
      });
    }

    res.status(200).json({
      success: true,
      data: service
    });
  }),

  // @desc    Toggle featured status
  // @route   PATCH /api/services/:id/featured
  // @access  Private
  toggleFeatured: asyncHandler(async (req, res) => {
    const { isFeatured, featuredOrder } = req.body;

    const updateData = { isFeatured };
    if (featuredOrder !== undefined) {
      updateData.featuredOrder = featuredOrder;
    }

    const service = await Service.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!service) {
      return res.status(404).json({
        success: false,
        error: 'Service not found'
      });
    }

    res.status(200).json({
      success: true,
      data: service
    });
  }),

  // @desc    Get services by price range
  // @route   GET /api/services/price-range
  // @access  Public
  getByPriceRange: asyncHandler(async (req, res) => {
    const { min, max } = req.query;

    if (!min || !max) {
      return res.status(400).json({
        success: false,
        error: 'Min and max price are required'
      });
    }

    const services = await Service.find({
      price: { $gte: parseFloat(min), $lte: parseFloat(max) },
      isActive: true
    }).sort('price');

    res.status(200).json({
      success: true,
      count: services.length,
      data: services
    });
  })
};

module.exports = serviceController;
