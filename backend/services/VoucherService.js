const { ObjectId } = require('mongodb');
const { getDB } = require('../config/database');

class VoucherService {
  static formatVoucher(voucher) {
    return {
      _id: voucher._id.toString(),
      code: voucher.code,
      name: voucher.name,
      description: voucher.description || '',
      discount: Number(voucher.discount || 0),
      maxDiscount: voucher.maxDiscount != null ? Number(voucher.maxDiscount) : null,
      minOrderValue: Number(voucher.minOrderValue || 0),
      totalQuantity: voucher.totalQuantity || 0,
      usedQuantity: voucher.usedQuantity || 0,
      isActive: voucher.isActive !== false,
      validFrom: voucher.validFrom,
      validTo: voucher.validTo,
      imageUrl: voucher.imageUrl || null,
      productIds: voucher.productIds || [],
      voucherType: voucher.voucherType || 'all',
      createdAt: voucher.createdAt,
      updatedAt: voucher.updatedAt,
    };
  }

  static normalizeVoucherPayload(data) {
    const now = new Date();
    
    // Parse dates safely
    let validFrom = now;
    let validTo = now;
    
    try {
      if (data.validFrom) {
        validFrom = new Date(data.validFrom);
        if (isNaN(validFrom.getTime())) validFrom = now;
      }
      if (data.validTo) {
        validTo = new Date(data.validTo);
        if (isNaN(validTo.getTime())) validTo = now;
      }
    } catch (e) {
      console.error('Error parsing dates:', e);
    }
    
    return {
      code: (data.code || '').toUpperCase(),
      name: data.name || '',
      description: data.description || '',
      discount: Number(data.discount || 0),
      maxDiscount: data.maxDiscount != null ? Number(data.maxDiscount) : null,
      minOrderValue: Number(data.minOrderValue || 0),
      totalQuantity: Number(data.totalQuantity || 0),
      usedQuantity: Number(data.usedQuantity || 0),
      validFrom: validFrom,
      validTo: validTo,
      isActive: data.isActive !== false,
      imageUrl: data.imageUrl || null,
      productIds: Array.isArray(data.productIds) ? data.productIds : [],
      voucherType: data.voucherType || 'all',
      updatedAt: new Date(),
    };
  }

  // Create voucher
  static async createVoucher(voucherData) {
    const db = getDB();
    console.log('📝 Creating voucher with data:', JSON.stringify(voucherData, null, 2));
    const payload = this.normalizeVoucherPayload(voucherData);
    console.log('✅ Normalized payload:', JSON.stringify(payload, null, 2));
    payload.createdAt = new Date();

    const result = await db.collection('vouchers').insertOne(payload);
    payload._id = result.insertedId;

    return this.formatVoucher(payload);
  }

  // Get all vouchers (optionally only active)
  static async getVouchers(page = 1, limit = 10, onlyActive = true) {
    const db = getDB();
    const collection = db.collection('vouchers');
    const now = new Date();
    const skip = (page - 1) * limit;

    const query = {};
    if (onlyActive) {
      query.isActive = true;
      query.validFrom = { $lte: now };
      query.validTo = { $gte: now };
      query.$expr = { $lt: ['$usedQuantity', '$totalQuantity'] };
    }

    const vouchers = await collection
      .find(query)
      .skip(skip)
      .limit(limit)
      .sort({ validTo: 1 })
      .toArray();

    const total = await collection.countDocuments(query);

    return {
      vouchers: vouchers.map(this.formatVoucher),
      total,
      pages: Math.ceil(total / limit),
    };
  }

  // Get all vouchers without pagination (for admin)
  static async getAllVouchers(includeInactive = false) {
    const db = getDB();
    const collection = db.collection('vouchers');
    const now = new Date();

    const query = {};
    if (!includeInactive) {
      query.isActive = true;
      query.validFrom = { $lte: now };
      query.validTo = { $gte: now };
    }

    const vouchers = await collection
      .find(query)
      .sort({ createdAt: -1 })
      .toArray();

    return vouchers.map(this.formatVoucher);
  }

  // Get active vouchers
  static async getActiveVouchers() {
    const db = getDB();
    const collection = db.collection('vouchers');
    const now = new Date();

    const vouchers = await collection
      .find({
        isActive: true,
        validFrom: { $lte: now },
        validTo: { $gte: now },
        $expr: { $lt: ['$usedQuantity', '$totalQuantity'] }
      })
      .sort({ createdAt: -1 })
      .toArray();

    return vouchers.map(this.formatVoucher);
  }

  // Delete voucher
  static async deleteVoucher(voucherId) {
    const db = getDB();
    
    const result = await db.collection('vouchers').deleteOne({
      _id: new ObjectId(voucherId)
    });

    return result.deletedCount > 0;
  }

  // Validate voucher
  static async validateVoucher(code, userId, orderAmount) {
    const db = getDB();
    const now = new Date();

    const voucher = await db.collection('vouchers').findOne({
      code: code.toUpperCase(),
      isActive: true
    });

    if (!voucher) {
      throw new Error('Invalid voucher code');
    }

    // Check date range
    if (now < voucher.validFrom || now > voucher.validTo) {
      throw new Error('Voucher has expired or not yet active');
    }

    // Check quantity
    if (voucher.usedQuantity >= voucher.totalQuantity) {
      throw new Error('Voucher usage limit exceeded');
    }

    // Check minimum order value
    if (orderAmount < voucher.minOrderValue) {
      throw new Error(`Minimum order amount is ${voucher.minOrderValue}`);
    }

    // Check if user already used this voucher
    if (userId) {
      const userVoucher = await db.collection('user_vouchers').findOne({
        userId,
        voucherId: voucher._id.toString(),
        isUsed: true
      });

      if (userVoucher) {
        throw new Error('You have already used this voucher');
      }
    }

    // Calculate discount
    let discountAmount = voucher.discount;
    if (voucher.maxDiscount && discountAmount > voucher.maxDiscount) {
      discountAmount = voucher.maxDiscount;
    }
    discountAmount = Math.min(discountAmount, orderAmount);

    return {
      voucher: this.formatVoucher(voucher),
      discountAmount,
      finalAmount: orderAmount - discountAmount
    };
  }

  // Apply voucher
  static async applyVoucher(code, userId, bookingId) {
    const db = getDB();

    const voucher = await db.collection('vouchers').findOne({
      code: code.toUpperCase(),
      isActive: true
    });

    if (!voucher) {
      throw new Error('Invalid voucher code');
    }

    // Increment usage
    await db.collection('vouchers').updateOne(
      { _id: voucher._id },
      { 
        $inc: { usedQuantity: 1 },
        $set: { updatedAt: new Date() }
      }
    );

    // Create user voucher record
    await db.collection('user_vouchers').updateOne(
      { userId, voucherId: voucher._id.toString() },
      {
        $set: {
          isUsed: true,
          usedAt: new Date(),
          usedInBookingId: bookingId
        }
      },
      { upsert: true }
    );

    return this.formatVoucher(voucher);
  }

  // Get voucher by code
  static async getVoucherByCode(code) {
    const db = getDB();
    const now = new Date();
    const voucher = await db.collection('vouchers').findOne({
      code: code.toUpperCase(),
      isActive: true,
      validFrom: { $lte: now },
      validTo: { $gte: now },
      $expr: { $lt: ['$usedQuantity', '$totalQuantity'] },
    });

    if (!voucher) {
      throw new Error('Voucher not found or expired');
    }

    return this.formatVoucher(voucher);
  }

  // Get voucher by ID
  static async getVoucherById(voucherId) {
    const db = getDB();
    const voucher = await db.collection('vouchers').findOne({
      _id: new ObjectId(voucherId),
    });

    if (!voucher) {
      throw new Error('Voucher not found');
    }

    return this.formatVoucher(voucher);
  }

  // Use voucher
  static async useVoucher(voucherId) {
    const db = getDB();

    const result = await db.collection('vouchers').findOneAndUpdate(
      { _id: new ObjectId(voucherId) },
      { $inc: { usedQuantity: 1 }, $set: { updatedAt: new Date() } },
      { returnDocument: 'after' }
    );

    if (!result.value) {
      throw new Error('Voucher not found');
    }

    return this.formatVoucher(result.value);
  }

  // Update voucher
  static async updateVoucher(voucherId, updateData) {
    const db = getDB();
    
    console.log('🔄 Updating voucher:', voucherId);
    console.log('📋 Update data:', JSON.stringify(updateData, null, 2));
    
    try {
      // Check if voucher exists first
      const existing = await db.collection('vouchers').findOne({
        _id: new ObjectId(voucherId)
      });
      
      if (!existing) {
        console.log('❌ Voucher not found with ID:', voucherId);
        throw new Error('Voucher not found');
      }
      
      console.log('✅ Found existing voucher:', existing.code);
      
      const payload = this.normalizeVoucherPayload(updateData);
      console.log('✅ Normalized payload:', JSON.stringify(payload, null, 2));

      const result = await db.collection('vouchers').findOneAndUpdate(
        { _id: new ObjectId(voucherId) },
        { $set: payload },
        { returnDocument: 'after' }
      );

      if (!result) {
        console.log('❌ findOneAndUpdate returned no value');
        throw new Error('Failed to update voucher');
      }

      console.log('✅ Updated voucher successfully');
      return this.formatVoucher(result);
    } catch (error) {
      console.error('❌ Error updating voucher:', error);
      throw error;
    }
  }

  // Deactivate voucher
  static async deactivateVoucher(voucherId) {
    const db = getDB();

    const result = await db.collection('vouchers').findOneAndUpdate(
      { _id: new ObjectId(voucherId) },
      { $set: { isActive: false, updatedAt: new Date() } },
      { returnDocument: 'after' }
    );

    if (!result.value) {
      throw new Error('Voucher not found');
    }

    return this.formatVoucher(result.value);
  }
}

module.exports = VoucherService;
