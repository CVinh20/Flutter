const mongoose = require('mongoose');

const stylistSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  branchId: {
    type: String,
    required: true
  },
  branchName: {
    type: String,
    required: true,
    trim: true
  },
  experience: {
    type: String,
    default: '',
    trim: true
  },
  image: {
    type: String,
    default: null
  },
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  },
  reviewCount: {
    type: Number,
    default: 0,
    min: 0
  },
  specialties: [{
    type: String,
    trim: true
  }],
  isActive: {
    type: Boolean,
    default: true
  },
  userId: {
    type: String,
    unique: true,
    sparse: true
  }
}, {
  timestamps: true
});

// Indexes
stylistSchema.index({ name: 1 });
stylistSchema.index({ branchId: 1 });
stylistSchema.index({ isActive: 1 });
stylistSchema.index({ rating: -1 });
stylistSchema.index({ userId: 1 });

module.exports = mongoose.model('Stylist', stylistSchema);
