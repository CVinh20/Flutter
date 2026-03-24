const asyncHandler = require('../middleware/asyncHandler');
const Branch = require('../models/Branch');

// @desc    Get all branches
// @route   GET /api/branches
// @access  Public
exports.getAll = asyncHandler(async (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  // Build query
  let query = { isActive: true };

  // Search by name or address
  if (req.query.search) {
    query.$or = [
      { name: { $regex: req.query.search, $options: 'i' } },
      { address: { $regex: req.query.search, $options: 'i' } }
    ];
  }

  // Build sort
  let sort = {};
  if (req.query.sortBy) {
    const parts = req.query.sortBy.split(':');
    sort[parts[0]] = parts[1] === 'desc' ? -1 : 1;
  } else {
    sort = { createdAt: -1 };
  }

  const total = await Branch.countDocuments(query);
  const branches = await Branch.find(query)
    .sort(sort)
    .skip(skip)
    .limit(limit);

  res.status(200).json({
    success: true,
    data: branches,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit)
    }
  });
});

// @desc    Get single branch
// @route   GET /api/branches/:id
// @access  Public
exports.getById = asyncHandler(async (req, res, next) => {
  const branch = await Branch.findById(req.params.id);

  if (!branch) {
    return res.status(404).json({
      success: false,
      message: 'Không tìm thấy chi nhánh'
    });
  }

  res.status(200).json({
    success: true,
    data: branch
  });
});

// @desc    Create new branch
// @route   POST /api/branches
// @access  Private (Admin)
exports.create = asyncHandler(async (req, res, next) => {
  const { name, address, hours, image, latitude, longitude, rating } = req.body;

  // Check if branch with same name exists
  const existingBranch = await Branch.findOne({ name });
  if (existingBranch) {
    return res.status(400).json({
      success: false,
      message: 'Chi nhánh với tên này đã tồn tại'
    });
  }

  const branch = await Branch.create({
    name,
    address,
    hours,
    image,
    latitude,
    longitude,
    rating: rating || 0
  });

  res.status(201).json({
    success: true,
    data: branch,
    message: 'Tạo chi nhánh thành công'
  });
});

// @desc    Update branch
// @route   PUT /api/branches/:id
// @access  Private (Admin)
exports.update = asyncHandler(async (req, res, next) => {
  let branch = await Branch.findById(req.params.id);

  if (!branch) {
    return res.status(404).json({
      success: false,
      message: 'Không tìm thấy chi nhánh'
    });
  }

  // Check if updating name to an existing name
  if (req.body.name && req.body.name !== branch.name) {
    const existingBranch = await Branch.findOne({ name: req.body.name });
    if (existingBranch) {
      return res.status(400).json({
        success: false,
        message: 'Chi nhánh với tên này đã tồn tại'
      });
    }
  }

  branch = await Branch.findByIdAndUpdate(
    req.params.id,
    req.body,
    {
      new: true,
      runValidators: true
    }
  );

  res.status(200).json({
    success: true,
    data: branch,
    message: 'Cập nhật chi nhánh thành công'
  });
});

// @desc    Delete branch
// @route   DELETE /api/branches/:id
// @access  Private (Admin)
exports.delete = asyncHandler(async (req, res, next) => {
  const branch = await Branch.findById(req.params.id);

  if (!branch) {
    return res.status(404).json({
      success: false,
      message: 'Không tìm thấy chi nhánh'
    });
  }

  // Soft delete by setting isActive to false
  branch.isActive = false;
  await branch.save();

  res.status(200).json({
    success: true,
    message: 'Xóa chi nhánh thành công'
  });
});

// @desc    Get nearby branches
// @route   GET /api/branches/nearby
// @access  Public
exports.getNearby = asyncHandler(async (req, res, next) => {
  const { latitude, longitude, maxDistance = 10000 } = req.query; // maxDistance in meters

  if (!latitude || !longitude) {
    return res.status(400).json({
      success: false,
      message: 'Vui lòng cung cấp vĩ độ và kinh độ'
    });
  }

  const lat = parseFloat(latitude);
  const lng = parseFloat(longitude);

  // Simple distance calculation (can be improved with geospatial queries)
  const branches = await Branch.find({ isActive: true });

  const branchesWithDistance = branches.map(branch => {
    const distance = calculateDistance(lat, lng, branch.latitude, branch.longitude);
    return {
      ...branch.toObject(),
      distance
    };
  }).filter(branch => branch.distance <= maxDistance)
    .sort((a, b) => a.distance - b.distance);

  res.status(200).json({
    success: true,
    data: branchesWithDistance
  });
});

// Helper function to calculate distance between two coordinates (Haversine formula)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth's radius in meters
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) *
    Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distance in meters
}
