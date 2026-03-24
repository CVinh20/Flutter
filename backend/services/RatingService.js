const { ObjectId } = require('mongodb');
const { getDB } = require('../config/database');

class RatingService {
  // Create rating
  static async createRating(ratingData) {
    const db = getDB();
    const rating = {
      ...ratingData,
      userId: new ObjectId(ratingData.userId),
      stylistId: new ObjectId(ratingData.stylistId),
      bookingId: new ObjectId(ratingData.bookingId),
      createdAt: new Date(),
      updatedAt: new Date()
    };

    const result = await db.collection('ratings').insertOne(rating);
    rating._id = result.insertedId;

    return rating;
  }

  // Get stylist ratings
  static async getStylistRatings(stylistId, page = 1, limit = 10) {
    const db = getDB();
    const collection = db.collection('ratings');

    const skip = (page - 1) * limit;
    const ratings = await collection
      .find({ stylistId: new ObjectId(stylistId) })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    const total = await collection.countDocuments({ stylistId: new ObjectId(stylistId) });

    return {
      ratings,
      total,
      pages: Math.ceil(total / limit)
    };
  }

  // Get average rating for stylist
  static async getAverageStylistRating(stylistId) {
    const db = getDB();
    const result = await db.collection('ratings').aggregate([
      { $match: { stylistId: new ObjectId(stylistId) } },
      {
        $group: {
          _id: '$stylistId',
          averageRating: { $avg: '$rating' },
          count: { $sum: 1 }
        }
      }
    ]).toArray();

    if (result.length === 0) {
      return { averageRating: 0, count: 0 };
    }

    return result[0];
  }

  // Get rating by ID
  static async getRatingById(ratingId) {
    const db = getDB();
    const rating = await db.collection('ratings').findOne({
      _id: new ObjectId(ratingId)
    });

    if (!rating) {
      throw new Error('Rating not found');
    }

    return rating;
  }

  // Update rating
  static async updateRating(ratingId, updateData) {
    const db = getDB();

    const result = await db.collection('ratings').findOneAndUpdate(
      { _id: new ObjectId(ratingId) },
      { $set: { ...updateData, updatedAt: new Date() } },
      { returnDocument: 'after' }
    );

    if (!result.value) {
      throw new Error('Rating not found');
    }

    return result.value;
  }

  // Delete rating
  static async deleteRating(ratingId) {
    const db = getDB();
    const result = await db.collection('ratings').deleteOne({
      _id: new ObjectId(ratingId)
    });

    if (result.deletedCount === 0) {
      throw new Error('Rating not found');
    }
  }
}

module.exports = RatingService;
