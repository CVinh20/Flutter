const asyncHandler = require('../middleware/asyncHandler');
const User = require('../models/User');
const Service = require('../models/Service');

// @desc    Get user favorites
// @route   GET /api/users/favorites
// @access  Private
exports.getFavorites = asyncHandler(async (req, res, next) => {
  console.log('🔍 Getting favorites for user:', req.user._id.toString());
  
  const user = await User.findById(req.user._id);
  
  if (!user) {
    return res.status(404).json({
      success: false,
      message: 'User not found'
    });
  }

  const favoriteIds = user.favoriteServices || [];
  console.log('📋 User has', favoriteIds.length, 'favorite services');

  if (favoriteIds.length === 0) {
    return res.status(200).json({
      success: true,
      data: []
    });
  }

  // Filter out invalid ObjectIds (old Firebase IDs)
  const mongoose = require('mongoose');
  const validIds = favoriteIds.filter(id => mongoose.Types.ObjectId.isValid(id));
  
  console.log('✅ Valid MongoDB IDs:', validIds.length, 'out of', favoriteIds.length);

  if (validIds.length === 0) {
    return res.status(200).json({
      success: true,
      data: []
    });
  }

  // Get service details
  const services = await Service.find({
    _id: { $in: validIds },
    isActive: true
  });

  console.log('✅ Found', services.length, 'active services');

  res.status(200).json({
    success: true,
    data: services
  });
});

// @desc    Toggle favorite service
// @route   POST /api/users/favorites/:serviceId
// @access  Private
exports.toggleFavorite = asyncHandler(async (req, res, next) => {
  const { serviceId } = req.params;
  
  console.log('🔄 Toggling favorite:', serviceId, 'for user:', req.user._id.toString());

  // Check if service exists
  const service = await Service.findById(serviceId);
  if (!service) {
    return res.status(404).json({
      success: false,
      message: 'Service not found'
    });
  }

  const user = await User.findById(req.user._id);
  
  if (!user) {
    return res.status(404).json({
      success: false,
      message: 'User not found'
    });
  }

  const favoriteIds = user.favoriteServices || [];
  const isFavorite = favoriteIds.includes(serviceId);

  if (isFavorite) {
    // Remove from favorites
    user.favoriteServices = favoriteIds.filter(id => id !== serviceId);
    console.log('❌ Removed from favorites');
  } else {
    // Add to favorites
    user.favoriteServices = [...favoriteIds, serviceId];
    console.log('✅ Added to favorites');
  }

  await user.save();

  res.status(200).json({
    success: true,
    message: isFavorite ? 'Removed from favorites' : 'Added to favorites',
    isFavorite: !isFavorite
  });
});

// @desc    Check if service is favorite
// @route   GET /api/users/favorites/:serviceId/check
// @access  Private
exports.checkFavorite = asyncHandler(async (req, res, next) => {
  const { serviceId } = req.params;
  
  const user = await User.findById(req.user._id);
  
  if (!user) {
    return res.status(404).json({
      success: false,
      message: 'User not found'
    });
  }

  const isFavorite = (user.favoriteServices || []).includes(serviceId);

  res.status(200).json({
    success: true,
    isFavorite
  });
});

// @desc    Get all users
// @route   GET /api/users
// @access  Private/Admin
exports.getAllUsers = asyncHandler(async (req, res, next) => {
  console.log('📋 Getting all users');
  
  const users = await User.find({})
    .select('-password')
    .sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    count: users.length,
    data: users
  });
});

// @desc    Get user by ID
// @route   GET /api/users/:id
// @access  Private/Admin
exports.getUserById = asyncHandler(async (req, res, next) => {
  const user = await User.findById(req.params.id).select('-password');

  if (!user) {
    return res.status(404).json({
      success: false,
      message: 'User not found'
    });
  }

  res.status(200).json({
    success: true,
    data: user
  });
});

// @desc    Create new user
// @route   POST /api/users
// @access  Private/Admin
exports.createUser = asyncHandler(async (req, res, next) => {
  const user = await User.create(req.body);

  res.status(201).json({
    success: true,
    data: user
  });
});

// @desc    Update user
// @route   PUT /api/users/:id
// @access  Private/Admin
exports.updateUser = asyncHandler(async (req, res, next) => {
  // Don't allow password update through this route
  const { password, ...updateData } = req.body;

  const user = await User.findByIdAndUpdate(
    req.params.id,
    updateData,
    {
      new: true,
      runValidators: true
    }
  ).select('-password');

  if (!user) {
    return res.status(404).json({
      success: false,
      message: 'User not found'
    });
  }

  res.status(200).json({
    success: true,
    data: user
  });
});

// @desc    Delete user
// @route   DELETE /api/users/:id
// @access  Private/Admin
exports.deleteUser = asyncHandler(async (req, res, next) => {
  const user = await User.findByIdAndDelete(req.params.id);

  if (!user) {
    return res.status(404).json({
      success: false,
      message: 'User not found'
    });
  }

  res.status(200).json({
    success: true,
    message: 'User deleted successfully',
    data: {}
  });
});
