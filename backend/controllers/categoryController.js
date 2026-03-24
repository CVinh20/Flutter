const asyncHandler = require('../middleware/asyncHandler');
const Category = require('../models/Category');

const formatCategory = (category) => ({
  _id: category._id.toString(),
  name: category.name,
  description: category.description || '',
  imageUrl: category.imageUrl || null,
  isActive: category.isActive,
  order: category.order || 0,
  createdAt: category.createdAt,
  updatedAt: category.updatedAt,
});

// @desc    Get all categories
// @route   GET /api/categories
// @access  Public
exports.getAll = asyncHandler(async (req, res, next) => {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 100; // Default limit higher for categories
    const skip = (page - 1) * limit;

    // Build query
    const query = {};

    // Include inactive when admin asks for it
    if (req.query.includeInactive !== 'true') {
        query.isActive = true;
    }

    // Search by name
    if (req.query.search) {
        query.name = { $regex: req.query.search, $options: 'i' };
    }

    // Build sort
    let sort = { order: 1, name: 1 }; // Default sort by order then name

    const total = await Category.countDocuments(query);
    const categories = await Category.find(query)
        .sort(sort)
        .skip(skip)
        .limit(limit);

    res.status(200).json({
        success: true,
        data: categories.map(formatCategory),
        pagination: {
            page,
            limit,
            total,
            pages: Math.ceil(total / limit)
        }
    });
});

// @desc    Get single category
// @route   GET /api/categories/:id
// @access  Public
exports.getById = asyncHandler(async (req, res, next) => {
    const category = await Category.findById(req.params.id);

    if (!category) {
        return res.status(404).json({
            success: false,
            message: 'Không tìm thấy danh mục'
        });
    }

    res.status(200).json({
        success: true,
        data: formatCategory(category)
    });
});

// @desc    Create new category
// @route   POST /api/categories
// @access  Private (Admin)
exports.create = asyncHandler(async (req, res, next) => {
    const { name, description, imageUrl, order } = req.body;

    // Validate required fields
    if (!name || name.trim() === '') {
        return res.status(400).json({
            success: false,
            message: 'Tên danh mục là bắt buộc'
        });
    }

    // Check if category with same name exists
    const existingCategory = await Category.findOne({ name: name.trim() });
    if (existingCategory) {
        return res.status(400).json({
            success: false,
            message: 'Danh mục với tên này đã tồn tại'
        });
    }

    const category = await Category.create({
        name: name.trim(),
        description: description || '',
        imageUrl: imageUrl || null,
        order: order || 0,
        isActive: true
    });

    res.status(201).json({
        success: true,
        data: formatCategory(category),
        message: 'Tạo danh mục thành công'
    });
});

// @desc    Update category
// @route   PUT /api/categories/:id
// @access  Private (Admin)
exports.update = asyncHandler(async (req, res, next) => {
    let category = await Category.findById(req.params.id);

    if (!category) {
        return res.status(404).json({
            success: false,
            message: 'Không tìm thấy danh mục'
        });
    }

    // Check if updating name to an existing name
    if (req.body.name && req.body.name !== category.name) {
        const existingCategory = await Category.findOne({ name: req.body.name });
        if (existingCategory) {
            return res.status(400).json({
                success: false,
                message: 'Danh mục với tên này đã tồn tại'
            });
        }
    }

    category = await Category.findByIdAndUpdate(
        req.params.id,
        req.body,
        {
            new: true,
            runValidators: true
        }
    );

    res.status(200).json({
        success: true,
        data: formatCategory(category),
        message: 'Cập nhật danh mục thành công'
    });
});

// @desc    Delete category
// @route   DELETE /api/categories/:id
// @access  Private (Admin)
exports.delete = asyncHandler(async (req, res, next) => {
    const category = await Category.findById(req.params.id);

    if (!category) {
        return res.status(404).json({
            success: false,
            message: 'Không tìm thấy danh mục'
        });
    }

    // Hard delete - completely remove from database
    await Category.findByIdAndDelete(req.params.id);

    res.status(200).json({
        success: true,
        message: 'Xóa danh mục thành công'
    });
});
