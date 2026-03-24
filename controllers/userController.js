const { User } = require('../models');
const asyncHandler = require('../middleware/asyncHandler');
const createBaseController = require('./baseController');

// Get base CRUD operations
const baseController = createBaseController(User, 'User');

// Custom user-specific methods
const userController = {
  ...baseController,

  // @desc    Get user by email
  // @route   GET /api/users/email/:email
  // @access  Private
  getByEmail: asyncHandler(async (req, res) => {
    const user = await User.findOne({ email: req.params.email });

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.status(200).json({
      success: true,
      data: user
    });
  }),

  // @desc    Get users by role
  // @route   GET /api/users/role/:role
  // @access  Private
  getByRole: asyncHandler(async (req, res) => {
    const { role } = req.params;
    
    if (!['customer', 'stylist', 'admin'].includes(role)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid role'
      });
    }

    const users = await User.find({ role, isActive: true })
      .sort('-createdAt');

    res.status(200).json({
      success: true,
      count: users.length,
      data: users
    });
  }),

  // @desc    Update user profile
  // @route   PUT /api/users/:id/profile
  // @access  Private
  updateProfile: asyncHandler(async (req, res) => {
    const allowedFields = ['fullName', 'displayName', 'phoneNumber', 'photoURL'];
    const updateData = {};

    // Only allow specific fields to be updated
    Object.keys(req.body).forEach(key => {
      if (allowedFields.includes(key)) {
        updateData[key] = req.body[key];
      }
    });

    const user = await User.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.status(200).json({
      success: true,
      data: user
    });
  }),

  // @desc    Add favorite service
  // @route   POST /api/users/:id/favorites/:serviceId
  // @access  Private
  addFavoriteService: asyncHandler(async (req, res) => {
    const { id, serviceId } = req.params;

    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    if (!user.favoriteServices.includes(serviceId)) {
      user.favoriteServices.push(serviceId);
      await user.save();
    }

    res.status(200).json({
      success: true,
      data: user
    });
  }),

  // @desc    Remove favorite service
  // @route   DELETE /api/users/:id/favorites/:serviceId
  // @access  Private
  removeFavoriteService: asyncHandler(async (req, res) => {
    const { id, serviceId } = req.params;

    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    user.favoriteServices = user.favoriteServices.filter(
      fav => fav !== serviceId
    );
    await user.save();

    res.status(200).json({
      success: true,
      data: user
    });
  }),

  // @desc    Update last login
  // @route   PATCH /api/users/:id/last-login
  // @access  Private
  updateLastLogin: asyncHandler(async (req, res) => {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { lastLoginAt: new Date() },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.status(200).json({
      success: true,
      data: user
    });
  }),

  // @desc    Deactivate user
  // @route   PATCH /api/users/:id/deactivate
  // @access  Private
  deactivateUser: asyncHandler(async (req, res) => {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isActive: false },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.status(200).json({
      success: true,
      data: user
    });
  })
};

module.exports = userController;
