const mongoose = require('mongoose');

const userVoucherSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true
  },
  voucherId: {
    type: String,
    required: true
  },
  claimedAt: {
    type: Date,
    default: Date.now
  },
  isUsed: {
    type: Boolean,
    default: false
  },
  usedAt: {
    type: Date,
    default: null
  },
  usedInBookingId: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

// Compound index to prevent duplicate claims
userVoucherSchema.index({ userId: 1, voucherId: 1 }, { unique: true });
userVoucherSchema.index({ userId: 1 });
userVoucherSchema.index({ voucherId: 1 });
userVoucherSchema.index({ isUsed: 1 });
userVoucherSchema.index({ claimedAt: -1 });

module.exports = mongoose.model('UserVoucher', userVoucherSchema);
