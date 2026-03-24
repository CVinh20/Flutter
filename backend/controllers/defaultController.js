const asyncHandler = require('../middleware/asyncHandler');

const defaultHandler = asyncHandler(async (req, res, next) => {
  res.status(200).json({ success: true, data: [], message: 'Feature coming soon' });
});

const defaultSingleHandler = asyncHandler(async (req, res, next) => {
  res.status(200).json({ success: true, data: {}, message: 'Feature coming soon' });
});

module.exports = {
  getAll: defaultHandler,
  getById: defaultSingleHandler,
  create: defaultHandler,
  update: defaultHandler,
  delete: defaultHandler,
  createHandler: defaultHandler,
  updateHandler: defaultHandler,
  deleteHandler: defaultHandler,
  getUserBookings: defaultHandler,
  getStylistRatings: defaultHandler,
  searchProducts: defaultHandler,
  search: defaultHandler
};
