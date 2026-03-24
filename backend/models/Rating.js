const mongoose = require('mongoose');

const ratingSchema = new mongoose.Schema({
  bookingId: {
    type: String,
    required: true,
    unique: true
  },
  userId: {
    type: String,
    required: true
  },
  userName: {
    type: String,
    required: true,
    trim: true
  },
  serviceId: {
    type: String,
    required: true
  },
  stylistId: {
    type: String,
    required: true
  },
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },
  comment: {
    type: String,
    default: '',
    trim: true
  }
}, {
  timestamps: true
});

// Indexes
ratingSchema.index({ bookingId: 1 });
ratingSchema.index({ userId: 1 });
ratingSchema.index({ serviceId: 1 });
ratingSchema.index({ stylistId: 1 });
ratingSchema.index({ rating: 1 });
ratingSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Rating', ratingSchema);
