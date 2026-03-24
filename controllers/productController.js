const { Product, ProductReview } = require('../models');
const asyncHandler = require('../middleware/asyncHandler');
const createBaseController = require('./baseController');

// Get base CRUD operations
const baseController = createBaseController(Product, 'Product');

// Custom product-specific methods
const productController = {
  ...baseController,

  // @desc    Get products by category
  // @route   GET /api/products/category/:categoryId
  // @access  Public
  getByCategory: asyncHandler(async (req, res) => {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;

    const products = await Product.find({ 
      categoryId: req.params.categoryId,
      isActive: true 
    })
      .sort('-createdAt')
      .skip(startIndex)
      .limit(limit);

    const total = await Product.countDocuments({ 
      categoryId: req.params.categoryId,
      isActive: true 
    });

    res.status(200).json({
      success: true,
      count: products.length,
      total,
      pagination: {
        page,
        limit,
        pages: Math.ceil(total / limit)
      },
      data: products
    });
  }),

  // @desc    Search products
  // @route   GET /api/products/search
  // @access  Public
  searchProducts: asyncHandler(async (req, res) => {
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

    const products = await Product.find(query)
      .sort('-createdAt')
      .skip(startIndex)
      .limit(limit);

    const total = await Product.countDocuments(query);

    res.status(200).json({
      success: true,
      count: products.length,
      total,
      pagination: {
        page,
        limit,
        pages: Math.ceil(total / limit)
      },
      data: products
    });
  }),

  // @desc    Update product stock
  // @route   PATCH /api/products/:id/stock
  // @access  Private
  updateStock: asyncHandler(async (req, res) => {
    const { stock } = req.body;

    if (stock < 0) {
      return res.status(400).json({
        success: false,
        error: 'Stock cannot be negative'
      });
    }

    const product = await Product.findByIdAndUpdate(
      req.params.id,
      { stock },
      { new: true, runValidators: true }
    );

    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }

    res.status(200).json({
      success: true,
      data: product
    });
  }),

  // @desc    Update product rating
  // @route   PATCH /api/products/:id/rating
  // @access  Private
  updateRating: asyncHandler(async (req, res) => {
    const productId = req.params.id;

    // Calculate average rating from reviews
    const reviews = await ProductReview.find({ productId });
    
    if (reviews.length === 0) {
      return res.status(200).json({
        success: true,
        message: 'No reviews found for this product'
      });
    }

    const totalRating = reviews.reduce((sum, review) => sum + review.rating, 0);
    const averageRating = totalRating / reviews.length;

    const product = await Product.findByIdAndUpdate(
      productId,
      { 
        rating: Math.round(averageRating * 10) / 10, // Round to 1 decimal place
        reviewCount: reviews.length 
      },
      { new: true }
    );

    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }

    res.status(200).json({
      success: true,
      data: product
    });
  }),

  // @desc    Get featured products
  // @route   GET /api/products/featured
  // @access  Public
  getFeatured: asyncHandler(async (req, res) => {
    const limit = parseInt(req.query.limit, 10) || 10;

    const products = await Product.find({ 
      isActive: true,
      rating: { $gte: 4 } // Products with rating 4 or higher
    })
      .sort('-rating -reviewCount')
      .limit(limit);

    res.status(200).json({
      success: true,
      count: products.length,
      data: products
    });
  })
};

module.exports = productController;
