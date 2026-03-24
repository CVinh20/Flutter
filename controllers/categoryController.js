const { Category } = require('../models');
const asyncHandler = require('../middleware/asyncHandler');
const createBaseController = require('./baseController');

// Get base CRUD operations
const baseController = createBaseController(Category, 'Category');

// Custom category-specific methods
const categoryController = {
  ...baseController,

  // @desc    Get active categories
  // @route   GET /api/categories/active
  // @access  Public
  getActive: asyncHandler(async (req, res) => {
    const categories = await Category.find({ isActive: true })
      .sort('order name');

    res.status(200).json({
      success: true,
      count: categories.length,
      data: categories
    });
  }),

  // @desc    Update category order
  // @route   PATCH /api/categories/:id/order
  // @access  Private
  updateOrder: asyncHandler(async (req, res) => {
    const { order } = req.body;

    if (order < 0) {
      return res.status(400).json({
        success: false,
        error: 'Order must be a non-negative number'
      });
    }

    const category = await Category.findByIdAndUpdate(
      req.params.id,
      { order },
      { new: true, runValidators: true }
    );

    if (!category) {
      return res.status(404).json({
        success: false,
        error: 'Category not found'
      });
    }

    res.status(200).json({
      success: true,
      data: category
    });
  }),

  // @desc    Toggle category status
  // @route   PATCH /api/categories/:id/toggle-status
  // @access  Private
  toggleStatus: asyncHandler(async (req, res) => {
    const category = await Category.findById(req.params.id);

    if (!category) {
      return res.status(404).json({
        success: false,
        error: 'Category not found'
      });
    }

    category.isActive = !category.isActive;
    await category.save();

    res.status(200).json({
      success: true,
      data: category
    });
  })
};

module.exports = categoryController;
