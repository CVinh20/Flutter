const asyncHandler = require('../middleware/asyncHandler');
const Service = require('../models/Service');
const Category = require('../models/Category');

// @desc    Get all services
// @route   GET /api/services
// @access  Public
exports.getAll = asyncHandler(async (req, res, next) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    // Build query
    let query = { isActive: true };

    // Filter by category
    if (req.query.categoryId) {
        query.categoryId = req.query.categoryId;
    }

    // Filter by featured
    if (req.query.isFeatured) {
        query.isFeatured = req.query.isFeatured === 'true';
    }

    // Search by name
    if (req.query.search) {
        query.name = { $regex: req.query.search, $options: 'i' };
    }

    // Build sort
    let sort = {};
    if (req.query.sortBy) {
        const parts = req.query.sortBy.split(':');
        sort[parts[0]] = parts[1] === 'desc' ? -1 : 1;
    } else {
        sort = { createdAt: -1 };
    }

    const total = await Service.countDocuments(query);
    const services = await Service.find(query)
        .sort(sort)
        .skip(skip)
        .limit(limit);

    res.status(200).json({
        success: true,
        data: services,
        pagination: {
            page,
            limit,
            total,
            pages: Math.ceil(total / limit)
        }
    });
});

// @desc    Get single service
// @route   GET /api/services/:id
// @access  Public
exports.getById = asyncHandler(async (req, res, next) => {
    const service = await Service.findById(req.params.id);

    if (!service) {
        return res.status(404).json({
            success: false,
            message: 'Không tìm thấy dịch vụ'
        });
    }

    res.status(200).json({
        success: true,
        data: service
    });
});

// @desc    Create new service
// @route   POST /api/services
// @access  Private (Admin)
exports.create = asyncHandler(async (req, res, next) => {
    const { name, categoryId, duration, price, image, description, rating } = req.body;

    // Get category name
    const category = await Category.findById(categoryId);
    if (!category) {
        return res.status(404).json({
            success: false,
            message: 'Không tìm thấy danh mục'
        });
    }

    const service = await Service.create({
        name,
        categoryId,
        categoryName: category.name,
        duration,
        price,
        image,
        description: description || '',
        rating: rating || 0
    });

    res.status(201).json({
        success: true,
        data: service,
        message: 'Tạo dịch vụ thành công'
    });
});

// @desc    Update service
// @route   PUT /api/services/:id
// @access  Private (Admin)
exports.update = asyncHandler(async (req, res, next) => {
    let service = await Service.findById(req.params.id);

    if (!service) {
        return res.status(404).json({
            success: false,
            message: 'Không tìm thấy dịch vụ'
        });
    }

    // If categoryId is being updated, get the new category name
    if (req.body.categoryId && req.body.categoryId !== service.categoryId) {
        const category = await Category.findById(req.body.categoryId);
        if (!category) {
            return res.status(404).json({
                success: false,
                message: 'Không tìm thấy danh mục'
            });
        }
        req.body.categoryName = category.name;
    }

    service = await Service.findByIdAndUpdate(
        req.params.id,
        req.body,
        {
            new: true,
            runValidators: true
        }
    );

    res.status(200).json({
        success: true,
        data: service,
        message: 'Cập nhật dịch vụ thành công'
    });
});

// @desc    Delete service
// @route   DELETE /api/services/:id
// @access  Private (Admin)
exports.delete = asyncHandler(async (req, res, next) => {
    const service = await Service.findById(req.params.id);

    if (!service) {
        return res.status(404).json({
            success: false,
            message: 'Không tìm thấy dịch vụ'
        });
    }

    // Soft delete by setting isActive to false
    service.isActive = false;
    await service.save();

    res.status(200).json({
        success: true,
        message: 'Xóa dịch vụ thành công'
    });
});

// @desc    Get featured services
// @route   GET /api/services/featured
// @access  Public
exports.getFeatured = asyncHandler(async (req, res, next) => {
    const services = await Service.find({
        isActive: true,
        isFeatured: true
    })
        .sort({ featuredOrder: 1, createdAt: -1 })
        .limit(10);

    res.status(200).json({
        success: true,
        data: services
    });
});
