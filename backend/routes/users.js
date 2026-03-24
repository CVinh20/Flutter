const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { validateUser, handleValidationErrors, validatePagination } = require('../middleware/validation');
const { protect } = require('../middleware/auth');

// @route   GET /api/users/favorites
// @desc    Get user favorite services
// @access  Private
router.get('/favorites', protect, userController.getFavorites);

// @route   POST /api/users/favorites/:serviceId
// @desc    Toggle favorite service
// @access  Private
router.post('/favorites/:serviceId', protect, userController.toggleFavorite);

// @route   GET /api/users/favorites/:serviceId/check
// @desc    Check if service is favorite
// @access  Private
router.get('/favorites/:serviceId/check', protect, userController.checkFavorite);

// @route   GET /api/users
// @desc    Get all users with pagination
// @access  Private
router.get('/', protect, userController.getAllUsers);

// @route   GET /api/users/:id
// @desc    Get single user
// @access  Private
router.get('/:id', protect, userController.getUserById);

// @route   POST /api/users
// @desc    Create new user
// @access  Public
router.post('/', [validateUser, handleValidationErrors], userController.createUser);

// @route   PUT /api/users/:id
// @desc    Update user
// @access  Private
router.put('/:id', protect, userController.updateUser);

// @route   DELETE /api/users/:id
// @desc    Delete user
// @access  Private
router.delete('/:id', protect, userController.deleteUser);

module.exports = router;

