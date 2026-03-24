const express = require('express');
const router = express.Router();

// Import all route modules
const authRoutes = require('./auth');
const bookingRoutes = require('./bookings');
const userRoutes = require('./users');
const productRoutes = require('./products');
const serviceRoutes = require('./services');
const voucherRoutes = require('./vouchers');
const orderRoutes = require('./orders');
const branchRoutes = require('./branches');
const categoryRoutes = require('./categories');
const productCategoryRoutes = require('./productCategories');
const ratingRoutes = require('./ratings');
const stylistRoutes = require('./stylists');
const userVoucherRoutes = require('./userVouchers');
const productReviewRoutes = require('./productReviews');
const uploadRoutes = require('./upload');

// API Routes
router.use('/auth', authRoutes);
router.use('/bookings', bookingRoutes);
router.use('/users', userRoutes);
router.use('/products', productRoutes);
router.use('/services', serviceRoutes);
router.use('/vouchers', voucherRoutes);
router.use('/orders', orderRoutes);
router.use('/branches', branchRoutes);
router.use('/categories', categoryRoutes);
router.use('/product-categories', productCategoryRoutes);
router.use('/ratings', ratingRoutes);
router.use('/stylists', stylistRoutes);
router.use('/user-vouchers', userVoucherRoutes);
router.use('/product-reviews', productReviewRoutes);
router.use('/upload', uploadRoutes);

// Health check route
router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'API is running',
    timestamp: new Date().toISOString()
  });
});

// API info route
router.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Gentlemen\'s Grooming API',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      bookings: '/api/bookings',
      users: '/api/users',
      products: '/api/products',
      services: '/api/services',
      vouchers: '/api/vouchers',
      orders: '/api/orders',
      branches: '/api/branches',
      categories: '/api/categories',
      productCategories: '/api/product-categories',
      ratings: '/api/ratings',
      stylists: '/api/stylists',
      userVouchers: '/api/user-vouchers',
      productReviews: '/api/product-reviews'
    }
  });
});

module.exports = router;

