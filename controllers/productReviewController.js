const { ProductReview, Product } = require('../models');
const asyncHandler = require('../middleware/asyncHandler');
const createBaseController = require('./baseController');

// Get base CRUD operations
const baseController = createBaseController(ProductReview, 'ProductReview');

// Custom product review-specific methods
const productReviewController = {
  ...baseController,

  // @desc    Get reviews by product
  // @route   GET /api/product-reviews/product/:productId
  // @access  Public
  getByProduct: asyncHandler(async (req, res) => {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;

    const reviews = await ProductReview.find({ productId: req.params.productId })
      .sort('-createdAt')
      .skip(startIndex)
      .limit(limit);

    const total = await ProductReview.countDocuments({ productId: req.params.productId });

    res.status(200).json({
      success: true,
      count: reviews.length,
      total,
      pagination: {
        page,
        limit,
        pages: Math.ceil(total / limit)
      },
      data: reviews
    });
  }),

  // @desc    Get reviews by user
  // @route   GET /api/product-reviews/user/:userId
  // @access  Private
  getByUser: asyncHandler(async (req, res) => {
    const reviews = await ProductReview.find({ userId: req.params.userId })
      .sort('-createdAt');

    res.status(200).json({
      success: true,
      count: reviews.length,
      data: reviews
    });
  }),

  // @desc    Create review and update product rating
  // @route   POST /api/product-reviews
  // @access  Private
  createReview: asyncHandler(async (req, res) => {
    // Check if user already reviewed this product
    const existingReview = await ProductReview.findOne({
      productId: req.body.productId,
      userId: req.body.userId
    });

    if (existingReview) {
      return res.status(400).json({
        success: false,
        error: 'You have already reviewed this product'
      });
    }

    const review = await ProductReview.create(req.body);

    // Update product rating
    await updateProductRating(req.body.productId);

    res.status(201).json({
      success: true,
      data: review
    });
  }),

  // @desc    Update review and product rating
  // @route   PUT /api/product-reviews/:id
  // @access  Private
  updateReview: asyncHandler(async (req, res) => {
    const review = await ProductReview.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!review) {
      return res.status(404).json({
        success: false,
        error: 'Product review not found'
      });
    }

    // Update product rating
    await updateProductRating(review.productId);

    res.status(200).json({
      success: true,
      data: review
    });
  }),

  // @desc    Delete review and update product rating
  // @route   DELETE /api/product-reviews/:id
  // @access  Private
  deleteReview: asyncHandler(async (req, res) => {
    const review = await ProductReview.findByIdAndDelete(req.params.id);

    if (!review) {
      return res.status(404).json({
        success: false,
        error: 'Product review not found'
      });
    }

    // Update product rating
    await updateProductRating(review.productId);

    res.status(200).json({
      success: true,
      data: {}
    });
  }),

  // @desc    Get review statistics for product
  // @route   GET /api/product-reviews/product/:productId/stats
  // @access  Public
  getProductStats: asyncHandler(async (req, res) => {
    const stats = await ProductReview.aggregate([
      { $match: { productId: req.params.productId } },
      {
        $group: {
          _id: null,
          averageRating: { $avg: '$rating' },
          totalReviews: { $sum: 1 },
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
          totalReviews: 0,
          ratingDistribution: {}
        }
      });
    }

    const distribution = {};
    for (let i = 1; i <= 5; i++) {
      distribution[i] = stats[0].ratingDistribution.filter(r => r === i).length;
    }

    res.status(200).json({
      success: true,
      data: {
        averageRating: Math.round(stats[0].averageRating * 10) / 10,
        totalReviews: stats[0].totalReviews,
        ratingDistribution: distribution
      }
    });
  }),

  // @desc    Get reviews by rating
  // @route   GET /api/product-reviews/product/:productId/rating/:rating
  // @access  Public
  getByRating: asyncHandler(async (req, res) => {
    const { productId, rating } = req.params;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;

    const ratingValue = parseInt(rating);
    if (ratingValue < 1 || ratingValue > 5) {
      return res.status(400).json({
        success: false,
        error: 'Rating must be between 1 and 5'
      });
    }

    const reviews = await ProductReview.find({ 
      productId, 
      rating: ratingValue 
    })
      .sort('-createdAt')
      .skip(startIndex)
      .limit(limit);

    const total = await ProductReview.countDocuments({ 
      productId, 
      rating: ratingValue 
    });

    res.status(200).json({
      success: true,
      count: reviews.length,
      total,
      pagination: {
        page,
        limit,
        pages: Math.ceil(total / limit)
      },
      data: reviews
    });
  })
};

// Helper function to update product rating
async function updateProductRating(productId) {
  const reviews = await ProductReview.find({ productId });
  
  if (reviews.length > 0) {
    const totalRating = reviews.reduce((sum, review) => sum + review.rating, 0);
    const averageRating = totalRating / reviews.length;
    
    await Product.findByIdAndUpdate(productId, {
      rating: Math.round(averageRating * 10) / 10,
      reviewCount: reviews.length
    });
  } else {
    await Product.findByIdAndUpdate(productId, {
      rating: 0,
      reviewCount: 0
    });
  }
}

module.exports = productReviewController;
