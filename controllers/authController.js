const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { User } = require('../models');
const asyncHandler = require('../middleware/asyncHandler');

// Generate JWT Token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE,
  });
};

const authController = {
  // @desc    Register user
  // @route   POST /api/auth/register
  // @access  Public
  register: asyncHandler(async (req, res) => {
    const { fullName, email, password, role = 'customer' } = req.body;

    // Check if user exists
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({
        success: false,
        error: 'User already exists'
      });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create user
    const user = await User.create({
      fullName,
      email,
      password: hashedPassword,
      role,
      isActive: true
    });

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      data: {
        _id: user._id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        isActive: user.isActive,
        token
      }
    });
  }),

  // @desc    Login user
  // @route   POST /api/auth/login
  // @access  Public
  login: asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    // Validate email & password
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Please provide email and password'
      });
    }

    // Check for user
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    // Check if password matches
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        error: 'Account is deactivated'
      });
    }

    // Update last login
    user.lastLoginAt = new Date();
    await user.save();

    // Generate token
    const token = generateToken(user._id);

    res.status(200).json({
      success: true,
      data: {
        _id: user._id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        isActive: user.isActive,
        lastLoginAt: user.lastLoginAt,
        token
      }
    });
  }),

  // @desc    Get current logged in user
  // @route   GET /api/auth/me
  // @access  Private
  getMe: asyncHandler(async (req, res) => {
    const user = await User.findById(req.user.id);

    res.status(200).json({
      success: true,
      data: user
    });
  }),

  // @desc    Update user profile
  // @route   PUT /api/auth/profile
  // @access  Private
  updateProfile: asyncHandler(async (req, res) => {
    const fieldsToUpdate = {
      fullName: req.body.fullName,
      displayName: req.body.displayName,
      phoneNumber: req.body.phoneNumber,
      photoURL: req.body.photoURL
    };

    const user = await User.findByIdAndUpdate(req.user.id, fieldsToUpdate, {
      new: true,
      runValidators: true
    });

    res.status(200).json({
      success: true,
      data: user
    });
  }),

  // @desc    Change password
  // @route   PUT /api/auth/change-password
  // @access  Private
  changePassword: asyncHandler(async (req, res) => {
    const { currentPassword, newPassword } = req.body;

    // Get user with password
    const user = await User.findById(req.user.id).select('+password');

    // Check current password
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({
        success: false,
        error: 'Current password is incorrect'
      });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Password updated successfully'
    });
  }),

  // @desc    Forgot password
  // @route   POST /api/auth/forgot-password
  // @access  Public
  forgotPassword: asyncHandler(async (req, res) => {
    const { email } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // In a real app, you would send an email with reset token
    // For now, just return success message
    res.status(200).json({
      success: true,
      message: 'Password reset instructions sent to email'
    });
  }),

  // @desc    Logout user
  // @route   POST /api/auth/logout
  // @access  Private
  logout: asyncHandler(async (req, res) => {
    // In JWT, logout is handled on client side by removing token
    // You could implement token blacklisting here if needed
    
    res.status(200).json({
      success: true,
      message: 'Logged out successfully'
    });
  })
};

module.exports = authController;
