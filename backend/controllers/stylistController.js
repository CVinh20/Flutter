const asyncHandler = require('../middleware/asyncHandler');
const Stylist = require('../models/Stylist');

// @desc    Get all stylists
// @route   GET /api/stylists
// @access  Public
exports.getAll = asyncHandler(async (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  // Build query
  let query = { isActive: true };

  // Search by name or experience
  if (req.query.search) {
    query.$or = [
      { name: { $regex: req.query.search, $options: 'i' } },
      { experience: { $regex: req.query.search, $options: 'i' } }
    ];
  }

  // Filter by branch
  if (req.query.branchId) {
    query.branchId = req.query.branchId;
  }

  // Build sort
  let sort = {};
  if (req.query.sortBy) {
    const parts = req.query.sortBy.split(':');
    sort[parts[0]] = parts[1] === 'desc' ? -1 : 1;
  } else {
    sort = { rating: -1, name: 1 };
  }

  const total = await Stylist.countDocuments(query);
  const stylists = await Stylist.find(query)
    .sort(sort)
    .skip(skip)
    .limit(limit);

  res.status(200).json({
    success: true,
    data: stylists,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit)
    }
  });
});

// @desc    Get single stylist
// @route   GET /api/stylists/:id
// @access  Public
exports.getById = asyncHandler(async (req, res, next) => {
  const stylist = await Stylist.findById(req.params.id);

  if (!stylist) {
    return res.status(404).json({
      success: false,
      message: 'Không tìm thấy stylist'
    });
  }

  res.status(200).json({
    success: true,
    data: stylist
  });
});

// @desc    Get stylists by branch
// @route   GET /api/stylists/branch/:branchId
// @access  Public
exports.getByBranch = asyncHandler(async (req, res, next) => {
  const stylists = await Stylist.find({ 
    branchId: req.params.branchId,
    isActive: true 
  }).sort({ rating: -1, name: 1 });

  res.status(200).json({
    success: true,
    count: stylists.length,
    data: stylists
  });
});

// @desc    Get top rated stylists
// @route   GET /api/stylists/top-rated
// @access  Public
exports.getTopRated = asyncHandler(async (req, res, next) => {
  const limit = parseInt(req.query.limit) || 10;

  const stylists = await Stylist.find({ 
    isActive: true,
    rating: { $gte: 4 }
  })
    .sort({ rating: -1, reviewCount: -1 })
    .limit(limit);

  res.status(200).json({
    success: true,
    count: stylists.length,
    data: stylists
  });
});

// @desc    Search stylists
// @route   GET /api/stylists/search
// @access  Public
exports.searchStylists = asyncHandler(async (req, res, next) => {
  const { q, branchId, minRating } = req.query;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  let query = { isActive: true };

  // Text search
  if (q) {
    const searchRegex = new RegExp(q, 'i');
    query.$or = [
      { name: searchRegex },
      { experience: searchRegex },
      { specialties: { $in: [searchRegex] } }
    ];
  }

  // Branch filter
  if (branchId) {
    query.branchId = branchId;
  }

  // Rating filter
  if (minRating) {
    query.rating = { $gte: parseFloat(minRating) };
  }

  const stylists = await Stylist.find(query)
    .sort({ rating: -1, name: 1 })
    .skip(skip)
    .limit(limit);

  const total = await Stylist.countDocuments(query);

  res.status(200).json({
    success: true,
    count: stylists.length,
    total,
    pagination: {
      page,
      limit,
      pages: Math.ceil(total / limit)
    },
    data: stylists
  });
});

// @desc    Create new stylist
// @route   POST /api/stylists
// @access  Private (Admin)
exports.create = asyncHandler(async (req, res, next) => {
  const { name, experience, image, phone, email, specialties, branchId, branchName, rating } = req.body;

  console.log('📥 Received stylist data:', { name, branchId, branchName, experience, image });

  // Validate required fields
  if (!branchId || !branchName) {
    return res.status(400).json({
      success: false,
      message: 'branchId và branchName là bắt buộc'
    });
  }

  // Check if stylist with same name and branch exists
  const existingStylist = await Stylist.findOne({ name, branchId });
  if (existingStylist) {
    return res.status(400).json({
      success: false,
      message: 'Stylist với tên này đã tồn tại trong chi nhánh'
    });
  }

  const stylist = await Stylist.create({
    name,
    experience,
    image,
    phone,
    email,
    specialties: specialties || [],
    branchId,
    branchName,
    rating: rating || 5.0,
    reviewCount: 0
  });

  console.log('✅ Created stylist:', stylist._id);

  res.status(201).json({
    success: true,
    data: stylist,
    message: 'Tạo stylist thành công'
  });
});

// @desc    Update stylist
// @route   PUT /api/stylists/:id
// @access  Private (Admin)
exports.update = asyncHandler(async (req, res, next) => {
  let stylist = await Stylist.findById(req.params.id);

  if (!stylist) {
    return res.status(404).json({
      success: false,
      message: 'Không tìm thấy stylist'
    });
  }

  // Check if updating name to an existing name in the same branch
  if (req.body.name && req.body.name !== stylist.name) {
    const existingStylist = await Stylist.findOne({ 
      name: req.body.name, 
      branchId: req.body.branchId || stylist.branchId
    });
    if (existingStylist) {
      return res.status(400).json({
        success: false,
        message: 'Stylist với tên này đã tồn tại trong chi nhánh'
      });
    }
  }

  stylist = await Stylist.findByIdAndUpdate(
    req.params.id,
    req.body,
    {
      new: true,
      runValidators: true
    }
  );

  res.status(200).json({
    success: true,
    data: stylist,
    message: 'Cập nhật stylist thành công'
  });
});

// @desc    Delete stylist
// @route   DELETE /api/stylists/:id
// @access  Private (Admin)
exports.delete = asyncHandler(async (req, res, next) => {
  const stylist = await Stylist.findById(req.params.id);

  if (!stylist) {
    return res.status(404).json({
      success: false,
      message: 'Không tìm thấy stylist'
    });
  }

  // Soft delete by setting isActive to false
  stylist.isActive = false;
  await stylist.save();

  res.status(200).json({
    success: true,
    message: 'Xóa stylist thành công'
  });
});
