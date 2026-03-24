const mongoose = require('mongoose');

const voucherSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    uppercase: true
  },
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    default: '',
    trim: true
  },
  type: {
    type: Number,
    required: true,
    enum: [0, 1], // 0: percentage, 1: fixed amount
    default: 0
  },
  value: {
    type: Number,
    required: true,
    min: 0
  },
  condition: {
    type: Number,
    default: 0,
    min: 0
  },
  minAmount: {
    type: Number,
    default: null,
    min: 0
  },
  maxUses: {
    type: Number,
    required: true,
    min: 1
  },
  currentUses: {
    type: Number,
    default: 0,
    min: 0
  },
  startDate: {
    type: Date,
    required: true
  },
  endDate: {
    type: Date,
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isForNewUser: {
    type: Boolean,
    default: false
  },
  specificServiceIds: [{
    type: String
  }],
  imageUrl: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

// Validation
voucherSchema.pre('save', function(next) {
  if (this.endDate <= this.startDate) {
    next(new Error('End date must be after start date'));
  }
  if (this.currentUses > this.maxUses) {
    next(new Error('Current uses cannot exceed max uses'));
  }
  next();
});

// Indexes
voucherSchema.index({ code: 1 });
voucherSchema.index({ isActive: 1 });
voucherSchema.index({ startDate: 1, endDate: 1 });
voucherSchema.index({ isForNewUser: 1 });

module.exports = mongoose.model('Voucher', voucherSchema);
