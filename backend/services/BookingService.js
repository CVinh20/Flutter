const { ObjectId } = require('mongodb');
const { getDB } = require('../config/database');

class BookingService {
  static toObjectId(id) {
    if (!id) return null;
    if (id instanceof ObjectId) return id;
    if (ObjectId.isValid(id)) return new ObjectId(id);
    return null;
  }

  static formatBooking(doc) {
    console.log('🔄 Formatting booking with _id:', doc._id, 'type:', typeof doc._id);
    return {
      _id: doc._id.toString(),
      userId: doc.userId ? doc.userId.toString() : null,
      stylistId: doc.stylistId ? doc.stylistId.toString() : null,
      serviceId: doc.serviceId ? doc.serviceId.toString() : null,
      serviceName: doc.serviceName,
      servicePrice: doc.servicePrice,
      serviceDuration: doc.serviceDuration,
      serviceImage: doc.serviceImage,
      stylistName: doc.stylistName,
      dateTime: doc.dateTime,
      status: doc.status,
      note: doc.note,
      customerName: doc.customerName,
      customerPhone: doc.customerPhone,
      branchName: doc.branchName,
      paymentMethod: doc.paymentMethod,
      amount: doc.amount ?? doc.finalAmount ?? 0,
      isPaid: doc.isPaid ?? false,
      voucherCode: doc.voucherCode,
      discount: doc.discount ?? doc.discountAmount ?? 0,
      originalAmount: doc.originalAmount,
      stylistNotes: doc.stylistNotes,
      checkInTime: doc.checkInTime,
      serviceStatus: doc.serviceStatus,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  // Create booking
  static async createBooking(bookingData) {
    const db = getDB();
    console.log('📝 Creating booking for userId:', bookingData.userId?.toString());

    const booking = {
      ...bookingData,
      userId: this.toObjectId(bookingData.userId),
      stylistId: this.toObjectId(bookingData.stylistId),
      serviceId: this.toObjectId(bookingData.serviceId),
      dateTime: new Date(bookingData.dateTime),
      status: bookingData.status || 'pending',
      amount: bookingData.amount ?? bookingData.finalAmount ?? bookingData.servicePrice ?? 0,
      originalAmount: bookingData.originalAmount ?? bookingData.servicePrice ?? bookingData.finalAmount ?? 0,
      discount: bookingData.discountAmount ?? bookingData.discount ?? 0,
      serviceImage: bookingData.serviceImage || bookingData.service?.image || null,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    console.log('💾 Saving booking with userId type:', booking.userId instanceof ObjectId ? 'ObjectId' : typeof booking.userId);

    const result = await db.collection('bookings').insertOne(booking);
    booking._id = result.insertedId;

    console.log('✅ Booking created with ID:', result.insertedId.toString());
    return this.formatBooking(booking);
  }

  // Get user bookings
  static async getUserBookings(userId, page = 1, limit = 10) {
    const db = getDB();
    const collection = db.collection('bookings');

    // Query both ObjectId and string format
    const userIdObj = this.toObjectId(userId);
    const userIdStr = userId.toString();
    
    console.log('🔍 Querying bookings with userId:', userIdStr);

    const skip = (page - 1) * limit;
    const bookings = await collection
      .find({ 
        $or: [
          { userId: userIdObj },
          { userId: userIdStr }
        ]
      })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    console.log('📊 Found', bookings.length, 'bookings in database');

    const total = await collection.countDocuments({ 
      $or: [
        { userId: userIdObj },
        { userId: userIdStr }
      ]
    });

    return {
      bookings: bookings.map(this.formatBooking),
      total,
      pages: Math.ceil(total / limit)
    };
  }

  // Get stylist bookings
  static async getStylistBookings(stylistId, page = 1, limit = 10) {
    const db = getDB();
    const collection = db.collection('bookings');

    // Query both ObjectId and string format
    const stylistIdObj = this.toObjectId(stylistId);
    const stylistIdStr = stylistId.toString();
    
    console.log('🔍 Querying bookings with stylistId:', stylistIdStr);

    const skip = (page - 1) * limit;
    const bookings = await collection
      .find({ 
        $or: [
          { stylistId: stylistIdObj },
          { stylistId: stylistIdStr }
        ]
      })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    console.log('📊 Found', bookings.length, 'bookings for stylist');

    const total = await collection.countDocuments({ 
      $or: [
        { stylistId: stylistIdObj },
        { stylistId: stylistIdStr }
      ]
    });

    return {
      bookings: bookings.map(this.formatBooking),
      total,
      pages: Math.ceil(total / limit)
    };
  }

  // Get booking by ID
  static async getBookingById(bookingId) {
    const db = getDB();
    const booking = await db.collection('bookings').findOne({
      _id: new ObjectId(bookingId)
    });

    if (!booking) {
      throw new Error('Booking not found');
    }

    return this.formatBooking(booking);
  }

  // Update booking
  static async updateBooking(bookingId, updateData) {
    const db = getDB();
    console.log('🔄 Updating booking:', bookingId);
    console.log('📝 Update data:', updateData);

    // Validate ObjectId
    if (!ObjectId.isValid(bookingId)) {
      console.log('❌ Invalid ObjectId format:', bookingId);
      throw new Error('Invalid booking ID format');
    }

    // Convert dateTime string to Date object if present
    if (updateData.dateTime && typeof updateData.dateTime === 'string') {
      updateData.dateTime = new Date(updateData.dateTime);
    }

    // First, try to find the booking to debug
    const existingBooking = await db.collection('bookings').findOne({ _id: new ObjectId(bookingId) });
    console.log('🔍 Found booking:', existingBooking ? 'YES' : 'NO');
    
    if (!existingBooking) {
      // Try with string ID
      const bookingWithStringId = await db.collection('bookings').findOne({ _id: bookingId });
      console.log('🔍 Found with string ID:', bookingWithStringId ? 'YES' : 'NO');
      
      if (bookingWithStringId) {
        // Update using string ID
        const result = await db.collection('bookings').findOneAndUpdate(
          { _id: bookingId },
          { $set: { ...updateData, updatedAt: new Date() } },
          { returnDocument: 'after' }
        );
        console.log('✅ Booking updated successfully (string ID)');
        return this.formatBooking(result.value);
      }
      
      throw new Error('Booking not found');
    }

    // Update with ObjectId
    const result = await db.collection('bookings').findOneAndUpdate(
      { _id: new ObjectId(bookingId) },
      { $set: { ...updateData, updatedAt: new Date() } },
      { returnDocument: 'after' }
    );

    console.log('📦 Update result:', result.value ? 'SUCCESS' : 'NULL');

    if (!result.value) {
      console.log('❌ findOneAndUpdate returned null - debugging...');
      // Fetch the booking again to see current state
      const checkBooking = await db.collection('bookings').findOne({ _id: new ObjectId(bookingId) });
      console.log('🔍 Booking still exists:', checkBooking ? 'YES' : 'NO');
      
      // If it exists, return it with updated fields manually
      if (checkBooking) {
        const updated = { ...checkBooking, ...updateData, updatedAt: new Date() };
        console.log('⚠️ Manual fallback - returning merged data');
        return this.formatBooking(updated);
      }
      
      throw new Error('Booking not found');
    }

    console.log('✅ Booking updated successfully');
    return this.formatBooking(result.value);
  }

  // Cancel booking
  static async cancelBooking(bookingId) {
    const db = getDB();
    console.log('❌ Cancelling booking:', bookingId);

    // Validate ObjectId
    if (!ObjectId.isValid(bookingId)) {
      console.log('❌ Invalid ObjectId format:', bookingId);
      throw new Error('Invalid booking ID format');
    }

    // First, try to find the booking to debug
    const existingBooking = await db.collection('bookings').findOne({ _id: new ObjectId(bookingId) });
    console.log('🔍 Found booking:', existingBooking ? 'YES' : 'NO');
    if (!existingBooking) {
      // Try with string ID
      const bookingWithStringId = await db.collection('bookings').findOne({ _id: bookingId });
      console.log('🔍 Found with string ID:', bookingWithStringId ? 'YES' : 'NO');
      
      if (bookingWithStringId) {
        // Update using string ID
        const result = await db.collection('bookings').findOneAndUpdate(
          { _id: bookingId },
          { $set: { status: 'cancelled', updatedAt: new Date() } },
          { returnDocument: 'after' }
        );
        console.log('✅ Booking cancelled successfully (string ID)');
        return this.formatBooking(result.value);
      }
    }

    const result = await db.collection('bookings').findOneAndUpdate(
      { _id: new ObjectId(bookingId) },
      { $set: { status: 'cancelled', updatedAt: new Date() } },
      { returnDocument: 'after' }
    );

    if (!result.value) {
      console.log('❌ Booking not found in database');
      throw new Error('Booking not found');
    }

    console.log('✅ Booking cancelled successfully');
    return this.formatBooking(result.value);
  }

  // Get bookings by date range
  static async getBookingsByDateRange(startDate, endDate, page = 1, limit = 10) {
    const db = getDB();
    const collection = db.collection('bookings');

    const skip = (page - 1) * limit;
    const bookings = await collection
      .find({
        dateTime: {
          $gte: new Date(startDate),
          $lte: new Date(endDate)
        }
      })
      .sort({ dateTime: 1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    const total = await collection.countDocuments({
      dateTime: {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      }
    });

    return {
      bookings: bookings.map(this.formatBooking),
      total,
      pages: Math.ceil(total / limit)
    };
  }

  // Delete booking (hard delete)
  static async deleteBooking(bookingId) {
    const db = getDB();
    console.log('🗑️  Deleting booking:', bookingId);

    // Validate ObjectId
    if (!ObjectId.isValid(bookingId)) {
      console.log('❌ Invalid ObjectId format:', bookingId);
      throw new Error('Invalid booking ID format');
    }

    const objectId = new ObjectId(bookingId);
    const result = await db.collection('bookings').deleteOne({ _id: objectId });

    if (result.deletedCount === 0) {
      // Try with string ID as fallback
      const stringResult = await db.collection('bookings').deleteOne({ _id: bookingId });
      if (stringResult.deletedCount === 0) {
        throw new Error('Booking not found');
      }
    }

    console.log('✅ Booking deleted successfully');
    return { success: true };
  }
}

module.exports = BookingService;
