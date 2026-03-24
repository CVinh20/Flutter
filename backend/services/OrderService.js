const { ObjectId } = require('mongodb');
const { getDB } = require('../config/database');

class OrderService {
  // Create order
  static async createOrder(orderData) {
    const db = getDB();
    const order = {
      ...orderData,
      userId: new ObjectId(orderData.userId),
      products: orderData.products.map(p => ({
        ...p,
        productId: new ObjectId(p.productId)
      })),
      status: 'pending', // pending, processing, completed, cancelled
      paymentStatus: 'unpaid', // unpaid, paid
      createdAt: new Date(),
      updatedAt: new Date()
    };

    const result = await db.collection('orders').insertOne(order);
    order._id = result.insertedId;

    return order;
  }

  // Get user orders
  static async getUserOrders(userId, page = 1, limit = 10) {
    const db = getDB();
    const collection = db.collection('orders');

    const skip = (page - 1) * limit;
    const orders = await collection
      .find({ userId: new ObjectId(userId) })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    const total = await collection.countDocuments({ userId: new ObjectId(userId) });

    return {
      orders,
      total,
      pages: Math.ceil(total / limit)
    };
  }

  // Get order by ID
  static async getOrderById(orderId) {
    const db = getDB();
    const order = await db.collection('orders').findOne({
      _id: new ObjectId(orderId)
    });

    if (!order) {
      throw new Error('Order not found');
    }

    return order;
  }

  // Update order status
  static async updateOrderStatus(orderId, status) {
    const db = getDB();

    const result = await db.collection('orders').findOneAndUpdate(
      { _id: new ObjectId(orderId) },
      { $set: { status, updatedAt: new Date() } },
      { returnDocument: 'after' }
    );

    if (!result.value) {
      throw new Error('Order not found');
    }

    return result.value;
  }

  // Update payment status
  static async updatePaymentStatus(orderId, paymentStatus) {
    const db = getDB();

    const result = await db.collection('orders').findOneAndUpdate(
      { _id: new ObjectId(orderId) },
      { $set: { paymentStatus, updatedAt: new Date() } },
      { returnDocument: 'after' }
    );

    if (!result.value) {
      throw new Error('Order not found');
    }

    return result.value;
  }

  // Cancel order
  static async cancelOrder(orderId) {
    const db = getDB();

    const result = await db.collection('orders').findOneAndUpdate(
      { _id: new ObjectId(orderId) },
      { $set: { status: 'cancelled', updatedAt: new Date() } },
      { returnDocument: 'after' }
    );

    if (!result.value) {
      throw new Error('Order not found');
    }

    return result.value;
  }
}

module.exports = OrderService;
