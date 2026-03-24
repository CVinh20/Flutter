const mongoose = require('mongoose');

const branchSchema = new mongoose.Schema({
  address: {
    type: String,
    required: true,
    trim: true
  },
  hours: {
    type: String,
    required: true,
    trim: true
  },
  image: {
    type: String,
    default: null
  },
  latitude: {
    type: Number,
    required: true,
    min: -90,
    max: 90
  },
  longitude: {
    type: Number,
    required: true,
    min: -180,
    max: 180
  },
  name: {
    type: String,
    required: true,
    trim: true,
    unique: true
  },
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Index for geospatial queries
branchSchema.index({ latitude: 1, longitude: 1 });
// Note: name index is automatically created by unique: true
branchSchema.index({ isActive: 1 });

module.exports = mongoose.model('Branch', branchSchema);
