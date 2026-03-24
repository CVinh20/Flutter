const mongoose = require('mongoose');

const productReviewSchema = new mongoose.Schema({
  productId: {
    type: String,
    required: true
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

// Compound index to prevent duplicate reviews
productReviewSchema.index({ productId: 1, userId: 1 }, { unique: true });
productReviewSchema.index({ productId: 1 });
productReviewSchema.index({ userId: 1 });
productReviewSchema.index({ rating: 1 });
productReviewSchema.index({ createdAt: -1 });

module.exports = mongoose.model('ProductReview', productReviewSchema);
