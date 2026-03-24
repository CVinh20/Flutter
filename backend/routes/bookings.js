const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const { validateBooking, handleValidationErrors, validatePagination } = require('../middleware/validation');
const { protect } = require('../middleware/auth');

// @route   GET /api/bookings
// @desc    Get all bookings with pagination
// @access  Public
router.get('/', [validatePagination, handleValidationErrors], bookingController.getAll);

// @route   GET /api/bookings/stats
// @desc    Get booking statistics
// @access  Private
router.get('/stats', protect, bookingController.getStats);

// @route   GET /api/bookings/user
// @desc    Get user bookings
// @access  Private
router.get('/user', protect, bookingController.getUserBookings);

// @route   GET /api/bookings/stylist/:stylistId
// @desc    Get stylist bookings
// @access  Public
router.get('/stylist/:stylistId', bookingController.getStylistBookings);

// @route   GET /api/bookings/:id
// @desc    Get single booking
// @access  Public
router.get('/:id', bookingController.getById);

// @route   POST /api/bookings
// @desc    Create new booking
// @access  Private
router.post('/', protect, [validateBooking, handleValidationErrors], bookingController.create);

// @route   PUT /api/bookings/:id
// @desc    Update booking
// @access  Private
router.put('/:id', protect, bookingController.update);

// @route   POST /api/bookings/:id/confirm
// @desc    Confirm booking (for stylist)
// @access  Private
router.post('/:id/confirm', protect, bookingController.confirmBooking);

// @route   PATCH /api/bookings/:id/check-in
// @desc    Check-in customer and start service (for stylist)
// @access  Private
router.patch('/:id/check-in', protect, bookingController.checkIn);

// @route   PATCH /api/bookings/:id/service-status
// @desc    Update service status (for stylist)
// @access  Private
router.patch('/:id/service-status', protect, bookingController.updateServiceStatus);

// @route   PATCH /api/bookings/:id/notes
// @desc    Update stylist notes (for stylist)
// @access  Private
router.patch('/:id/notes', protect, bookingController.updateNotes);

// @route   DELETE /api/bookings/:id
// @desc    Delete booking
// @access  Private
router.delete('/:id', protect, bookingController.delete);

module.exports = router;

