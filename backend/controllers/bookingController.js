const BookingService = require('../services/BookingService');
const asyncHandler = require('../middleware/asyncHandler');

// Get all bookings
exports.getAll = asyncHandler(async (req, res, next) => {
  const { page = 1, limit = 10, startDate, endDate } = req.query;
  
  // Default to wide range to get all bookings if dates not specified
  const defaultStartDate = startDate ? new Date(startDate) : new Date('2020-01-01');
  const defaultEndDate = endDate ? new Date(endDate) : new Date('2030-12-31');
  
  const bookings = await BookingService.getBookingsByDateRange(
    defaultStartDate,
    defaultEndDate,
    parseInt(page),
    parseInt(limit)
  );

  res.status(200).json({
    success: true,
    data: bookings.bookings,
    pagination: {
      total: bookings.total,
      pages: bookings.pages,
      currentPage: parseInt(page)
    }
  });
});

// Create booking
exports.create = asyncHandler(async (req, res, next) => {
  const booking = await BookingService.createBooking({
    ...req.body,
    userId: req.user._id
  });

  res.status(201).json({
    success: true,
    message: 'Booking created successfully',
    data: booking
  });
});

// Get user bookings
exports.getUserBookings = asyncHandler(async (req, res, next) => {
  const { page = 1, limit = 10 } = req.query;
  
  console.log('📋 Getting bookings for user:', req.user._id.toString());
  
  const bookings = await BookingService.getUserBookings(
    req.user._id,
    parseInt(page),
    parseInt(limit)
  );

  console.log('✅ Found', bookings.total, 'bookings for user');
  console.log('📦 Booking IDs:', bookings.bookings.map(b => b._id));

  res.status(200).json({
    success: true,
    data: bookings.bookings,
    pagination: {
      total: bookings.total,
      pages: bookings.pages,
      currentPage: parseInt(page)
    }
  });
});

// Get stylist bookings
exports.getStylistBookings = asyncHandler(async (req, res, next) => {
  const { page = 1, limit = 10 } = req.query;
  const stylistId = req.params.stylistId;
  
  console.log('📋 Getting bookings for stylist:', stylistId);
  
  const bookings = await BookingService.getStylistBookings(
    stylistId,
    parseInt(page),
    parseInt(limit)
  );

  console.log('✅ Found', bookings.total, 'bookings for stylist');

  res.status(200).json({
    success: true,
    data: bookings.bookings,
    pagination: {
      total: bookings.total,
      pages: bookings.pages,
      currentPage: parseInt(page)
    }
  });
});

// Get booking by ID
exports.getById = asyncHandler(async (req, res, next) => {
  const booking = await BookingService.getBookingById(req.params.id);

  res.status(200).json({
    success: true,
    data: booking
  });
});

// Update booking
exports.update = asyncHandler(async (req, res, next) => {
  const booking = await BookingService.updateBooking(req.params.id, req.body);

  res.status(200).json({
    success: true,
    message: 'Booking updated successfully',
    data: booking
  });
});

// Cancel booking
exports.cancel = asyncHandler(async (req, res, next) => {
  const booking = await BookingService.cancelBooking(req.params.id);

  res.status(200).json({
    success: true,
    message: 'Booking cancelled successfully',
    data: booking
  });
});

// Delete booking
exports.delete = asyncHandler(async (req, res, next) => {
  await BookingService.deleteBooking(req.params.id);

  res.status(200).json({
    success: true,
    message: 'Booking deleted successfully'
  });
});

// Confirm booking (for stylist)
exports.confirmBooking = asyncHandler(async (req, res, next) => {
  const bookingId = req.params.id;
  const { stylistId } = req.body;
  
  console.log('🔄 Confirming booking:', bookingId, 'by stylist:', stylistId);
  
  const booking = await BookingService.updateBooking(bookingId, { 
    status: 'Đã xác nhận' 
  });

  res.status(200).json({
    success: true,
    message: 'Đơn đã được xác nhận',
    data: booking
  });
});

// Check-in customer (for stylist)
exports.checkIn = asyncHandler(async (req, res, next) => {
  const bookingId = req.params.id;
  
  console.log('✅ Check-in customer for booking:', bookingId);
  
  const booking = await BookingService.updateBooking(bookingId, { 
    checkInTime: new Date(),
    status: 'in_progress',
    serviceStatus: 'in_progress'
  });

  res.status(200).json({
    success: true,
    message: 'Khách hàng đã check-in, dịch vụ đang thực hiện',
    data: booking
  });
});

// Update service status (for stylist)
exports.updateServiceStatus = asyncHandler(async (req, res, next) => {
  const bookingId = req.params.id;
  const { serviceStatus } = req.body;
  
  console.log('🔄 Updating service status for booking:', bookingId, 'to:', serviceStatus);
  
  // When service is completed, also update booking status
  const updateData = { serviceStatus };
  if (serviceStatus === 'completed') {
    updateData.status = 'Hoàn tất';
  }
  
  const booking = await BookingService.updateBooking(bookingId, updateData);

  res.status(200).json({
    success: true,
    message: 'Trạng thái dịch vụ đã được cập nhật',
    data: booking
  });
});

// Update stylist notes (for stylist)
exports.updateNotes = asyncHandler(async (req, res, next) => {
  const bookingId = req.params.id;
  const { stylistNotes } = req.body;
  
  console.log('📝 Updating notes for booking:', bookingId);
  
  const booking = await BookingService.updateBooking(bookingId, { 
    stylistNotes 
  });

  res.status(200).json({
    success: true,
    message: 'Ghi chú đã được lưu',
    data: booking
  });
});

// Get booking stats
exports.getStats = asyncHandler(async (req, res, next) => {
  const db = require('../config/database').getDB();
  const collection = db.collection('bookings');

  const stats = await collection.aggregate([
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 }
      }
    }
  ]).toArray();

  res.status(200).json({
    success: true,
    data: stats
  });
});
