const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true
  },
  fullName: {
    type: String,
    required: true,
    trim: true
  },
  displayName: {
    type: String,
    trim: true
  },
  password: {
    type: String,
    required: true,
    minlength: 6,
    select: false
  },
  phoneNumber: {
    type: String,
    default: null,
    trim: true
  },
  photoURL: {
    type: String,
    default: null
  },
  role: {
    type: String,
    required: true,
    enum: ['user', 'customer', 'stylist', 'admin'],
    default: 'customer'
  },
  stylistId: {
    type: String,
    default: null
  },
  isActive: {
    type: Boolean,
    default: true
  },
  favoriteServices: [{
    type: String
  }],
  lastLoginAt: {
    type: Date,
    default: null
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
userSchema.index({ email: 1 });
userSchema.index({ role: 1 });
userSchema.index({ stylistId: 1 });
userSchema.index({ isActive: 1 });
userSchema.index({ userId: 1 });

module.exports = mongoose.model('User', userSchema);
