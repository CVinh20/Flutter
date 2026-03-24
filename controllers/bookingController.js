const { Booking } = require('../models');
const asyncHandler = require('../middleware/asyncHandler');
const createBaseController = require('./baseController');

// Get base CRUD operations
const baseController = createBaseController(Booking, 'Booking');

// Custom booking-specific methods
const bookingController = {
  ...baseController,

  // @desc    Get bookings by user
  // @route   GET /api/bookings/user/:userId
  // @access  Private
  getByUser: asyncHandler(async (req, res) => {
    const bookings = await Booking.find({ userId: req.params.userId })
      .sort('-createdAt');

    res.status(200).json({
      success: true,
      count: bookings.length,
      data: bookings
    });
  }),

  // @desc    Get bookings by stylist
  // @route   GET /api/bookings/stylist/:stylistId
  // @access  Private
  getByStylist: asyncHandler(async (req, res) => {
    const bookings = await Booking.find({ stylistId: req.params.stylistId })
      .sort('-createdAt');

    res.status(200).json({
      success: true,
      count: bookings.length,
      data: bookings
    });
  }),

  // @desc    Get bookings by date range
  // @route   GET /api/bookings/date-range
  // @access  Private
  getByDateRange: asyncHandler(async (req, res) => {
    const { startDate, endDate } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({
        success: false,
        error: 'Start date and end date are required'
      });
    }

    const bookings = await Booking.find({
      dateTime: {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      }
    }).sort('dateTime');

    res.status(200).json({
      success: true,
      count: bookings.length,
      data: bookings
    });
  }),

  // @desc    Update booking status
  // @route   PATCH /api/bookings/:id/status
  // @access  Private
  updateStatus: asyncHandler(async (req, res) => {
    const { status } = req.body;

    if (!['pending', 'confirmed', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status'
      });
    }

    const booking = await Booking.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true, runValidators: true }
    );

    if (!booking) {
      return res.status(404).json({
        success: false,
        error: 'Booking not found'
      });
    }

    res.status(200).json({
      success: true,
      data: booking
    });
  }),

  // @desc    Get booking statistics
  // @route   GET /api/bookings/stats
  // @access  Private
  getStats: asyncHandler(async (req, res) => {
    const stats = await Booking.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          totalRevenue: { $sum: '$finalAmount' }
        }
      }
    ]);

    const totalBookings = await Booking.countDocuments();
    const totalRevenue = await Booking.aggregate([
      {
        $group: {
          _id: null,
          total: { $sum: '$finalAmount' }
        }
      }
    ]);

    res.status(200).json({
      success: true,
      data: {
        totalBookings,
        totalRevenue: totalRevenue[0]?.total || 0,
        statusBreakdown: stats
      }
    });
  })
};

module.exports = bookingController;
