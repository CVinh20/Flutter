const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  branchName: {
    type: String,
    required: true,
    trim: true
  },
  customerName: {
    type: String,
    required: true,
    trim: true
  },
  customerPhone: {
    type: String,
    required: true,
    trim: true
  },
  dateTime: {
    type: Date,
    required: true
  },
  discountAmount: {
    type: Number,
    default: 0,
    min: 0
  },
  finalAmount: {
    type: Number,
    required: true,
    min: 0
  },
  note: {
    type: String,
    default: '',
    trim: true
  },
  paymentMethod: {
    type: String,
    required: true,
    enum: ['cash', 'vietqr', 'card', 'transfer']
  },
  serviceDuration: {
    type: String,
    required: true
  },
  serviceId: {
    type: String,
    required: true
  },
  serviceName: {
    type: String,
    required: true,
    trim: true
  },
  servicePrice: {
    type: Number,
    required: true,
    min: 0
  },
  status: {
    type: String,
    required: true,
    enum: ['pending', 'confirmed', 'completed', 'cancelled'],
    default: 'pending'
  },
  stylistId: {
    type: String,
    required: true
  },
  stylistName: {
    type: String,
    required: true,
    trim: true
  },
  userId: {
    type: String,
    required: true
  },
  voucherId: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

// Indexes for better query performance
bookingSchema.index({ userId: 1 });
bookingSchema.index({ stylistId: 1 });
bookingSchema.index({ serviceId: 1 });
bookingSchema.index({ dateTime: 1 });
bookingSchema.index({ status: 1 });

module.exports = mongoose.model('Booking', bookingSchema);
