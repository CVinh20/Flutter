const { ObjectId } = require('mongodb');
const { getDB } = require('../config/database');

class ProductService {
  static toObjectId(id) {
    if (!id) return null;
    if (id instanceof ObjectId) return id;
    if (ObjectId.isValid(id)) return new ObjectId(id);
    return null;
  }

  // Get all products
  static async getAllProducts(page = 1, limit = 10, categoryId = null) {
    const db = getDB();
    const collection = db.collection('products');

    const query = {};
    const categoryObjectId = this.toObjectId(categoryId);
    if (categoryObjectId) {
      query.categoryId = categoryObjectId;
    }
    
    const skip = (page - 1) * limit;
    const products = await collection
      .find(query)
      .skip(skip)
      .limit(limit)
      .toArray();

    const total = await collection.countDocuments(query);

    return {
      products,
      total,
      pages: Math.ceil(total / limit)
    };
  }

  // Get product by ID
  static async getProductById(productId) {
    const db = getDB();
    const product = await db.collection('products').findOne({
      _id: new ObjectId(productId)
    });

    if (!product) {
      throw new Error('Product not found');
    }

    return product;
  }

  // Create product
  static async createProduct(productData) {
    const db = getDB();
    const categoryObjectId = this.toObjectId(productData.categoryId);

    const product = {
      ...productData,
      categoryId: categoryObjectId || productData.categoryId,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    const result = await db.collection('products').insertOne(product);
    product._id = result.insertedId;

    return product;
  }

  // Update product
  static async updateProduct(productId, updateData) {
    const db = getDB();
    
    const update = {
      ...updateData,
      updatedAt: new Date()
    };

    if (updateData.categoryId) {
      const categoryObjectId = this.toObjectId(updateData.categoryId);
      update.categoryId = categoryObjectId || updateData.categoryId;
    }

    const result = await db.collection('products').findOneAndUpdate(
      { _id: new ObjectId(productId) },
      { $set: update },
      { returnDocument: 'after' }
    );

    if (!result.value) {
      throw new Error('Product not found');
    }

    return result.value;
  }

  // Delete product
  static async deleteProduct(productId) {
    const db = getDB();
    const result = await db.collection('products').deleteOne({
      _id: new ObjectId(productId)
    });

    if (result.deletedCount === 0) {
      throw new Error('Product not found');
    }
  }

  // Search products
  static async searchProducts(searchTerm, page = 1, limit = 10) {
    const db = getDB();
    const collection = db.collection('products');

    const query = {
      $or: [
        { name: { $regex: searchTerm, $options: 'i' } },
        { description: { $regex: searchTerm, $options: 'i' } }
      ]
    };

    const skip = (page - 1) * limit;
    const products = await collection
      .find(query)
      .skip(skip)
      .limit(limit)
      .toArray();

    const total = await collection.countDocuments(query);

    return {
      products,
      total,
      pages: Math.ceil(total / limit)
    };
  }
}

module.exports = ProductService;
