const { Order } = require('../models');
const asyncHandler = require('../middleware/asyncHandler');
const createBaseController = require('./baseController');

// Get base CRUD operations
const baseController = createBaseController(Order, 'Order');

// Custom order-specific methods
const orderController = {
  ...baseController,

  // @desc    Get orders by user
  // @route   GET /api/orders/user/:userId
  // @access  Private
  getByUser: asyncHandler(async (req, res) => {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;

    const orders = await Order.find({ userId: req.params.userId })
      .sort('-createdAt')
      .skip(startIndex)
      .limit(limit);

    const total = await Order.countDocuments({ userId: req.params.userId });

    res.status(200).json({
      success: true,
      count: orders.length,
      total,
      pagination: {
        page,
        limit,
        pages: Math.ceil(total / limit)
      },
      data: orders
    });
  }),

  // @desc    Update order status
  // @route   PATCH /api/orders/:id/status
  // @access  Private
  updateStatus: asyncHandler(async (req, res) => {
    const { status } = req.body;
    const validStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status'
      });
    }

    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true, runValidators: true }
    );

    if (!order) {
      return res.status(404).json({
        success: false,
        error: 'Order not found'
      });
    }

    res.status(200).json({
      success: true,
      data: order
    });
  }),

  // @desc    Update payment status
  // @route   PATCH /api/orders/:id/payment
  // @access  Private
  updatePaymentStatus: asyncHandler(async (req, res) => {
    const { isPaid } = req.body;

    const updateData = { isPaid };
    if (isPaid) {
      updateData.paidAt = new Date();
    } else {
      updateData.paidAt = null;
    }

    const order = await Order.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!order) {
      return res.status(404).json({
        success: false,
        error: 'Order not found'
      });
    }

    res.status(200).json({
      success: true,
      data: order
    });
  }),

  // @desc    Get orders by status
  // @route   GET /api/orders/status/:status
  // @access  Private
  getByStatus: asyncHandler(async (req, res) => {
    const { status } = req.params;
    const validStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status'
      });
    }

    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;

    const orders = await Order.find({ status })
      .sort('-createdAt')
      .skip(startIndex)
      .limit(limit);

    const total = await Order.countDocuments({ status });

    res.status(200).json({
      success: true,
      count: orders.length,
      total,
      pagination: {
        page,
        limit,
        pages: Math.ceil(total / limit)
      },
      data: orders
    });
  }),

  // @desc    Get order statistics
  // @route   GET /api/orders/stats
  // @access  Private
  getStats: asyncHandler(async (req, res) => {
    const totalOrders = await Order.countDocuments();
    const paidOrders = await Order.countDocuments({ isPaid: true });
    
    const revenueStats = await Order.aggregate([
      { $match: { isPaid: true } },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: '$total' },
          averageOrderValue: { $avg: '$total' }
        }
      }
    ]);

    const statusStats = await Order.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]);

    const paymentMethodStats = await Order.aggregate([
      {
        $group: {
          _id: '$paymentMethod',
          count: { $sum: 1 }
        }
      }
    ]);

    res.status(200).json({
      success: true,
      data: {
        totalOrders,
        paidOrders,
        totalRevenue: revenueStats[0]?.totalRevenue || 0,
        averageOrderValue: revenueStats[0]?.averageOrderValue || 0,
        statusBreakdown: statusStats,
        paymentMethodBreakdown: paymentMethodStats
      }
    });
  }),

  // @desc    Get orders by date range
  // @route   GET /api/orders/date-range
  // @access  Private
  getByDateRange: asyncHandler(async (req, res) => {
    const { startDate, endDate } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({
        success: false,
        error: 'Start date and end date are required'
      });
    }

    const orders = await Order.find({
      createdAt: {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      }
    }).sort('-createdAt');

    res.status(200).json({
      success: true,
      count: orders.length,
      data: orders
    });
  })
};

module.exports = orderController;
