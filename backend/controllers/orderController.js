const OrderService = require('../services/OrderService');
const asyncHandler = require('../middleware/asyncHandler');

// Get all orders
exports.getAll = asyncHandler(async (req, res, next) => {
  const { page = 1, limit = 10 } = req.query;
  
  const orders = await OrderService.getUserOrders(
    req.user._id,
    parseInt(page),
    parseInt(limit)
  );

  res.status(200).json({
    success: true,
    data: orders.orders,
    pagination: {
      total: orders.total,
      pages: orders.pages,
      currentPage: parseInt(page)
    }
  });
});

// Create order
exports.create = asyncHandler(async (req, res, next) => {
  const order = await OrderService.createOrder({
    ...req.body,
    userId: req.user._id
  });

  res.status(201).json({
    success: true,
    message: 'Order created successfully',
    data: order
  });
});

// Get user orders
exports.getUserOrders = asyncHandler(async (req, res, next) => {
  const { page = 1, limit = 10 } = req.query;
  
  const orders = await OrderService.getUserOrders(
    req.user._id,
    parseInt(page),
    parseInt(limit)
  );

  res.status(200).json({
    success: true,
    data: orders.orders,
    pagination: {
      total: orders.total,
      pages: orders.pages,
      currentPage: parseInt(page)
    }
  });
});

// Get order by ID
exports.getById = asyncHandler(async (req, res, next) => {
  const order = await OrderService.getOrderById(req.params.id);

  res.status(200).json({
    success: true,
    data: order
  });
});

// Update order status
exports.updateStatus = asyncHandler(async (req, res, next) => {
  const { status } = req.body;

  const order = await OrderService.updateOrderStatus(req.params.id, status);

  res.status(200).json({
    success: true,
    message: 'Order status updated successfully',
    data: order
  });
});

// Update payment status
exports.updatePaymentStatus = asyncHandler(async (req, res, next) => {
  const { paymentStatus } = req.body;

  const order = await OrderService.updatePaymentStatus(req.params.id, paymentStatus);

  res.status(200).json({
    success: true,
    message: 'Payment status updated successfully',
    data: order
  });
});

// Cancel order
exports.cancel = asyncHandler(async (req, res, next) => {
  const order = await OrderService.cancelOrder(req.params.id);

  res.status(200).json({
    success: true,
    message: 'Order cancelled successfully',
    data: order
  });
});

// Update order
exports.update = asyncHandler(async (req, res, next) => {
  const order = await OrderService.updateOrderStatus(req.params.id, req.body.status || 'pending');

  res.status(200).json({
    success: true,
    message: 'Order updated successfully',
    data: order
  });
});

// Delete order
exports.delete = asyncHandler(async (req, res, next) => {
  const order = await OrderService.cancelOrder(req.params.id);

  res.status(200).json({
    success: true,
    message: 'Order deleted successfully',
    data: order
  });
});
