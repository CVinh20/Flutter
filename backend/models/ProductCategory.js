const mongoose = require('mongoose');

const productCategorySchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
    unique: true
  },
  description: {
    type: String,
    default: '',
    trim: true
  },
  imageUrl: {
    type: String,
    default: null
  },
  isActive: {
    type: Boolean,
    default: true
  },
  order: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

productCategorySchema.index({ name: 1 });
productCategorySchema.index({ isActive: 1 });
productCategorySchema.index({ order: 1 });

module.exports = mongoose.model('ProductCategory', productCategorySchema);
