const AuthService = require('../services/AuthService');
const asyncHandler = require('../middleware/asyncHandler');

// @desc    Register user
// @route   POST /api/auth/register
// @access  Public
exports.register = asyncHandler(async (req, res, next) => {
  const { fullName, email, password, role, stylistId } = req.body;

  const user = await AuthService.register({
    fullName,
    email,
    password,
    role: role || 'customer',
    stylistId
  });

  res.status(201).json({
    success: true,
    message: 'User registered successfully',
    data: user
  });
});

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
exports.login = asyncHandler(async (req, res, next) => {
  const { email, password } = req.body;

  const user = await AuthService.login(email, password);

  res.status(200).json({
    success: true,
    message: 'Login successful',
    data: user       
  });
});

// @desc    Google Sign In
// @route   POST /api/auth/google
// @access  Public
exports.googleSignIn = asyncHandler(async (req, res, next) => {
  const { idToken, email, displayName, photoUrl } = req.body;

  const user = await AuthService.googleSignIn({
    idToken,
    email,
    displayName,
    photoUrl
  });

  res.status(200).json({
    success: true,
    message: 'Google sign in successful',
    data: user
  });
});

// @desc    Get current user
// @route   GET /api/auth/me
// @access  Private
exports.getMe = asyncHandler(async (req, res, next) => {
  const user = await AuthService.getCurrentUser(req.user._id);

  res.status(200).json({
    success: true,
    data: user
  });
});

// @desc    Update user profile
// @route   PUT /api/auth/profile
// @access  Private
exports.updateProfile = asyncHandler(async (req, res, next) => {
  const { fullName, phoneNumber, displayName, photoURL } = req.body;

  const user = await AuthService.updateProfile(req.user._id, {
    fullName,
    phoneNumber,
    displayName,
    photoURL
  });

  res.status(200).json({
    success: true,
    message: 'Profile updated successfully',
    data: user
  });
});

// @desc    Change password
// @route   PUT /api/auth/change-password
// @access  Private
exports.changePassword = asyncHandler(async (req, res, next) => {
  const { currentPassword, newPassword } = req.body;

  await AuthService.changePassword(req.user._id, currentPassword, newPassword);

  res.status(200).json({
    success: true,
    message: 'Password changed successfully'
  });
});

// @desc    Forgot password
// @route   POST /api/auth/forgot-password
// @access  Public
exports.forgotPassword = asyncHandler(async (req, res, next) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({
      success: false,
      error: 'Email is required'
    });
  }

  await AuthService.sendPasswordResetEmail(email);

  res.status(200).json({
    success: true,
    message: 'Password reset email sent successfully'
  });
});

// @desc    Reset password with token
// @route   POST /api/auth/reset-password
// @access  Public
exports.resetPassword = asyncHandler(async (req, res, next) => {
  const { token, newPassword } = req.body;

  await AuthService.resetPassword(token, newPassword);

  res.status(200).json({
    success: true,
    message: 'Password reset successfully'
  });
});

// @desc    Logout user
// @route   POST /api/auth/logout
// @access  Private
exports.logout = asyncHandler(async (req, res, next) => {
  // With JWT, logout is handled on client side
  res.status(200).json({
    success: true,
    message: 'Logged out successfully'
  });
});
