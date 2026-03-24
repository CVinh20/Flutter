const express = require('express');
const router = express.Router();
const stylistController = require('../controllers/stylistController');
const { handleValidationErrors, validatePagination, validateStylist } = require('../middleware/validation');
const { protect } = require('../middleware/auth');

// @route   GET /api/stylists/branch/:branchId
// @desc    Get stylists by branch
// @access  Public
router.get('/branch/:branchId', stylistController.getByBranch);

// @route   GET /api/stylists/top-rated
// @desc    Get top rated stylists
// @access  Public
router.get('/top-rated', stylistController.getTopRated);

// @route   GET /api/stylists/search
// @desc    Search stylists
// @access  Public
router.get('/search', stylistController.searchStylists);

// @route   GET /api/stylists
// @desc    Get all stylists with pagination
// @access  Public
router.get('/', [validatePagination, handleValidationErrors], stylistController.getAll);

// @route   GET /api/stylists/:id
// @desc    Get single stylist
// @access  Public
router.get('/:id', stylistController.getById);

// @route   POST /api/stylists
// @desc    Create new stylist
// @access  Private
router.post('/', protect, validateStylist, handleValidationErrors, stylistController.create);

// @route   PUT /api/stylists/:id
// @desc    Update stylist
// @access  Private
router.put('/:id', protect, stylistController.update);

// @route   DELETE /api/stylists/:id
// @desc    Delete stylist
// @access  Private
router.delete('/:id', protect, stylistController.delete);

module.exports = router;

