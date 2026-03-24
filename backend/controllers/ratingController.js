const RatingService = require('../services/RatingService');
const asyncHandler = require('../middleware/asyncHandler');

// Create rating
exports.create = asyncHandler(async (req, res, next) => {
  const rating = await RatingService.createRating({
    ...req.body,
    userId: req.user._id
  });

  res.status(201).json({
    success: true,
    message: 'Rating created successfully',
    data: rating
  });
});

// Get stylist ratings
exports.getStylistRatings = asyncHandler(async (req, res, next) => {
  const { page = 1, limit = 10 } = req.query;
  
  const ratings = await RatingService.getStylistRatings(
    req.params.stylistId,
    parseInt(page),
    parseInt(limit)
  );

  res.status(200).json({
    success: true,
    data: ratings.ratings,
    pagination: {
      total: ratings.total,
      pages: ratings.pages,
      currentPage: parseInt(page)
    }
  });
});

// Get average rating for stylist
exports.getAverageRating = asyncHandler(async (req, res, next) => {
  const avgRating = await RatingService.getAverageStylistRating(req.params.stylistId);

  res.status(200).json({
    success: true,
    data: avgRating
  });
});

// Get rating by ID
exports.getById = asyncHandler(async (req, res, next) => {
  const rating = await RatingService.getRatingById(req.params.id);

  res.status(200).json({
    success: true,
    data: rating
  });
});

// Update rating
exports.update = asyncHandler(async (req, res, next) => {
  const rating = await RatingService.updateRating(req.params.id, req.body);

  res.status(200).json({
    success: true,
    message: 'Rating updated successfully',
    data: rating
  });
});

// Delete rating
exports.delete = asyncHandler(async (req, res, next) => {
  await RatingService.deleteRating(req.params.id);

  res.status(200).json({
    success: true,
    message: 'Rating deleted successfully'
  });
});
