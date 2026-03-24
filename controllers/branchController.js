const { Branch } = require('../models');
const asyncHandler = require('../middleware/asyncHandler');
const createBaseController = require('./baseController');

// Get base CRUD operations
const baseController = createBaseController(Branch, 'Branch');

// Custom branch-specific methods
const branchController = {
  ...baseController,

  // @desc    Get branches near location
  // @route   GET /api/branches/nearby
  // @access  Public
  getNearby: asyncHandler(async (req, res) => {
    const { latitude, longitude, maxDistance = 10 } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        error: 'Latitude and longitude are required'
      });
    }

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const maxDist = parseFloat(maxDistance);

    // Simple distance calculation (for more accurate results, use MongoDB's geospatial queries)
    const branches = await Branch.find({ isActive: true });
    
    const nearbyBranches = branches.filter(branch => {
      const distance = calculateDistance(lat, lng, branch.latitude, branch.longitude);
      return distance <= maxDist;
    }).map(branch => {
      const distance = calculateDistance(lat, lng, branch.latitude, branch.longitude);
      return {
        ...branch.toObject(),
        distance: Math.round(distance * 100) / 100 // Round to 2 decimal places
      };
    }).sort((a, b) => a.distance - b.distance);

    res.status(200).json({
      success: true,
      count: nearbyBranches.length,
      data: nearbyBranches
    });
  }),

  // @desc    Get active branches
  // @route   GET /api/branches/active
  // @access  Public
  getActive: asyncHandler(async (req, res) => {
    const branches = await Branch.find({ isActive: true })
      .sort('-rating name');

    res.status(200).json({
      success: true,
      count: branches.length,
      data: branches
    });
  }),

  // @desc    Update branch rating
  // @route   PATCH /api/branches/:id/rating
  // @access  Private
  updateRating: asyncHandler(async (req, res) => {
    const { rating } = req.body;

    if (rating < 0 || rating > 5) {
      return res.status(400).json({
        success: false,
        error: 'Rating must be between 0 and 5'
      });
    }

    const branch = await Branch.findByIdAndUpdate(
      req.params.id,
      { rating },
      { new: true, runValidators: true }
    );

    if (!branch) {
      return res.status(404).json({
        success: false,
        error: 'Branch not found'
      });
    }

    res.status(200).json({
      success: true,
      data: branch
    });
  }),

  // @desc    Toggle branch status
  // @route   PATCH /api/branches/:id/toggle-status
  // @access  Private
  toggleStatus: asyncHandler(async (req, res) => {
    const branch = await Branch.findById(req.params.id);

    if (!branch) {
      return res.status(404).json({
        success: false,
        error: 'Branch not found'
      });
    }

    branch.isActive = !branch.isActive;
    await branch.save();

    res.status(200).json({
      success: true,
      data: branch
    });
  })
};

// Helper function to calculate distance between two coordinates
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of the Earth in kilometers
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const d = R * c; // Distance in kilometers
  return d;
}

function deg2rad(deg) {
  return deg * (Math.PI/180);
}

module.exports = branchController;
