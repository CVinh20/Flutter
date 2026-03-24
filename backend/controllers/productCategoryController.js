const asyncHandler = require('../middleware/asyncHandler');
const ProductCategory = require('../models/ProductCategory');

// Helper: normalize product category for API responses
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

// @desc    Get all product categories
// @route   GET /api/product-categories
// @access  Public
exports.getAll = asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page, 10) || 1;
  const limit = parseInt(req.query.limit, 10) || 100;
  const skip = (page - 1) * limit;

  const includeInactive = req.query.includeInactive === 'true';
  const search = req.query.search;

  const query = {};
  if (!includeInactive) {
    query.isActive = true;
  }
  if (search) {
    query.name = { $regex: search, $options: 'i' };
  }

  const total = await ProductCategory.countDocuments(query);
  const categories = await ProductCategory.find(query)
    .sort({ order: 1, name: 1 })
    .skip(skip)
    .limit(limit);

  res.status(200).json({
    success: true,
    data: categories.map(formatCategory),
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit),
    },
  });
});

// @desc    Get single product category
// @route   GET /api/product-categories/:id
// @access  Public
exports.getById = asyncHandler(async (req, res) => {
  const category = await ProductCategory.findById(req.params.id);

  if (!category) {
    return res.status(404).json({
      success: false,
      message: 'Không tìm thấy danh mục sản phẩm',
    });
  }

  res.status(200).json({
    success: true,
    data: formatCategory(category),
  });
});

// @desc    Create new product category
// @route   POST /api/product-categories
// @access  Private/Admin
exports.create = asyncHandler(async (req, res) => {
  const { name, description, imageUrl, order } = req.body;

  const existing = await ProductCategory.findOne({ name });
  if (existing) {
    return res.status(400).json({
      success: false,
      message: 'Danh mục với tên này đã tồn tại',
    });
  }

  const category = await ProductCategory.create({
    name,
    description,
    imageUrl,
    order: order || 0,
  });

  res.status(201).json({
    success: true,
    message: 'Tạo danh mục sản phẩm thành công',
    data: formatCategory(category),
  });
});

// @desc    Update product category
// @route   PUT /api/product-categories/:id
// @access  Private/Admin
exports.update = asyncHandler(async (req, res) => {
  const { name } = req.body;
  const categoryId = req.params.id;

  const existingCategory = await ProductCategory.findById(categoryId);
  if (!existingCategory) {
    return res.status(404).json({
      success: false,
      message: 'Không tìm thấy danh mục sản phẩm',
    });
  }

  if (name && name !== existingCategory.name) {
    const dup = await ProductCategory.findOne({ name });
    if (dup) {
      return res.status(400).json({
        success: false,
        message: 'Danh mục với tên này đã tồn tại',
      });
    }
  }

  const updated = await ProductCategory.findByIdAndUpdate(
    categoryId,
    { ...req.body },
    { new: true, runValidators: true },
  );

  res.status(200).json({
    success: true,
    message: 'Cập nhật danh mục sản phẩm thành công',
    data: formatCategory(updated),
  });
});

// @desc    Delete (soft delete) product category
// @route   DELETE /api/product-categories/:id
// @access  Private/Admin
exports.delete = asyncHandler(async (req, res) => {
  const category = await ProductCategory.findById(req.params.id);

  if (!category) {
    return res.status(404).json({
      success: false,
      message: 'Không tìm thấy danh mục sản phẩm',
    });
  }

  category.isActive = false;
  await category.save();

  res.status(200).json({
    success: true,
    message: 'Đã vô hiệu hóa danh mục sản phẩm',
  });
});

