const express = require('express');
const router = express.Router();
const branchController = require('../controllers/branchController');
const { handleValidationErrors, validatePagination, validateBranch } = require('../middleware/validation');
const { protect } = require('../middleware/auth');

// @route   GET /api/branches/nearby
// @desc    Get nearby branches
// @access  Public
router.get('/nearby', branchController.getNearby);

// @route   GET /api/branches
// @desc    Get all branches with pagination
// @access  Public
router.get('/', [validatePagination, handleValidationErrors], branchController.getAll);

// @route   GET /api/branches/:id
// @desc    Get single branch
// @access  Public
router.get('/:id', branchController.getById);

// @route   POST /api/branches
// @desc    Create new branch
// @access  Private
router.post('/', protect, [validateBranch, handleValidationErrors], branchController.create);

// @route   PUT /api/branches/:id
// @desc    Update branch
// @access  Private
router.put('/:id', protect, [validateBranch, handleValidationErrors], branchController.update);

// @route   DELETE /api/branches/:id
// @desc    Delete branch
// @access  Private
router.delete('/:id', protect, branchController.delete);

module.exports = router;

