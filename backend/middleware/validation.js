const { body, param, query, validationResult } = require('express-validator');

// Validation result handler
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: 'Validation Error',
      details: errors.array()
    });
  }
  next();
};

// Common validations
const validateObjectId = (field) => [
  param(field).isMongoId().withMessage(`${field} must be a valid MongoDB ObjectId`)
];

const validatePagination = [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  // Cho phép limit rộng hơn để tránh lỗi 400 khi client request > 100
  query('limit').optional().isInt({ min: 1, max: 500 }).withMessage('Limit must be between 1 and 500')
];

// Booking validations
const validateBooking = [
  body('branchName').notEmpty().trim().withMessage('Branch name is required'),
  body('customerName').notEmpty().trim().withMessage('Customer name is required'),
  body('customerPhone').notEmpty().trim().withMessage('Customer phone is required'),
  body('dateTime').isISO8601().withMessage('Valid date time is required'),
  body('amount').isNumeric().isFloat({ min: 0 }).withMessage('Amount must be a positive number'),
  body('paymentMethod').isIn(['cash', 'vietqr', 'card', 'transfer']).withMessage('Invalid payment method'),
  body('serviceDuration').notEmpty().withMessage('Service duration is required'),
  body('serviceId').notEmpty().withMessage('Service ID is required'),
  body('serviceName').notEmpty().trim().withMessage('Service name is required'),
  body('servicePrice').isNumeric().isFloat({ min: 0 }).withMessage('Service price must be a positive number'),
  body('stylistId').notEmpty().withMessage('Stylist ID is required'),
  body('stylistName').notEmpty().trim().withMessage('Stylist name is required')
];

// User validations
const validateUser = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('fullName').notEmpty().trim().withMessage('Full name is required'),
  body('role').optional().isIn(['customer', 'stylist', 'admin']).withMessage('Invalid role')
];

// Product validations
const validateProduct = [
  body('name').notEmpty().trim().withMessage('Product name is required'),
  body('price').isNumeric().isFloat({ min: 0 }).withMessage('Price must be a positive number'),
  body('categoryId').notEmpty().withMessage('Category ID is required'),
  body('stock').optional().isInt({ min: 0 }).withMessage('Stock must be a non-negative integer')
];

// Service validations
const validateService = [
  body('name').notEmpty().trim().withMessage('Service name is required'),
  body('categoryId').notEmpty().withMessage('Category ID is required'),
  body('duration').notEmpty().withMessage('Duration is required'),
  body('price').isNumeric().isFloat({ min: 0 }).withMessage('Price must be a positive number')
];

// Branch validations
const validateBranch = [
  body('name').notEmpty().trim().withMessage('Branch name is required'),
  body('address').notEmpty().trim().withMessage('Address is required'),
  body('hours').notEmpty().trim().withMessage('Operating hours is required'),
  body('latitude').isNumeric().isFloat({ min: -90, max: 90 }).withMessage('Latitude must be between -90 and 90'),
  body('longitude').isNumeric().isFloat({ min: -180, max: 180 }).withMessage('Longitude must be between -180 and 180'),
  body('rating').optional().isFloat({ min: 0, max: 5 }).withMessage('Rating must be between 0 and 5')
];

// Voucher validations
const validateVoucher = [
  body('code').notEmpty().trim().withMessage('Voucher code is required'),
  body('name').notEmpty().trim().withMessage('Voucher name is required'),
  body('discount').isNumeric().isFloat({ min: 0 }).withMessage('Discount must be a positive number'),
  body('minOrderValue').isNumeric().isFloat({ min: 0 }).withMessage('Min order value must be a positive number'),
  body('maxDiscount').optional().isNumeric().withMessage('Max discount must be a number'),
  body('totalQuantity').isInt({ min: 0 }).withMessage('Total quantity must be zero or a positive number'),
  body('usedQuantity').optional().isInt({ min: 0 }).withMessage('Used quantity must be zero or a positive number'),
  body('validFrom').isISO8601().withMessage('Valid start date is required'),
  body('validTo').isISO8601().withMessage('Valid end date is required')
];

// Stylist validations
const validateStylist = [
  body('name').notEmpty().trim().withMessage('Stylist name is required'),
  body('branchId').notEmpty().trim().withMessage('Branch ID is required'),
  body('branchName').notEmpty().trim().withMessage('Branch name is required'),
  body('experience').optional().trim(),
  body('image').optional().trim(),
  body('rating').optional().isFloat({ min: 0, max: 5 }).withMessage('Rating must be between 0 and 5')
];

module.exports = {
  handleValidationErrors,
  validateObjectId,
  validatePagination,
  validateBooking,
  validateUser,
  validateProduct,
  validateService,
  validateBranch,
  validateVoucher,
  validateStylist
};
