const { MongoClient } = require('mongodb');
require('dotenv').config();

let cachedClient = null;
let cachedDb = null;

async function connectDB() {
  if (cachedClient && cachedDb) {
    return { client: cachedClient, db: cachedDb };
  }

  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
    
    const client = new MongoClient(mongoUri, {
      retryWrites: true,
      w: 'majority',
      maxPoolSize: 10,
      minPoolSize: 1,
      // SSL options for MongoDB Atlas
      ...(mongoUri.includes('mongodb+srv') && {
        ssl: true,
        tls: true,
        tlsAllowInvalidCertificates: false,
      })
    });
    
    await client.connect();

    const db = client.db('grooming_db');

    // Create collections if they don't exist
    const collections = ['users', 'bookings', 'products', 'services', 'branches', 
                        'categories', 'orders', 'vouchers', 'stylists', 'ratings', 
                        'productCategories', 'userVouchers', 'productReviews'];

    for (const collectionName of collections) {
      const exists = await db.listCollections({ name: collectionName }).hasNext();
      if (!exists) {
        await db.createCollection(collectionName);
        console.log(`✓ Collection '${collectionName}' created`);
      }
    }

    // Create indexes
    await createIndexes(db);

    cachedClient = client;
    cachedDb = db;

    console.log('✅ MongoDB connected successfully');
    return { client, db };
  } catch (error) {
    console.error('❌ MongoDB connection error:', error.message);
    throw error;
  }
}

async function createIndexes(db) {
  try {
    // Users indexes
    await db.collection('users').createIndex({ email: 1 }, { unique: true });
    await db.collection('users').createIndex({ phone: 1 });

    // Products indexes
    await db.collection('products').createIndex({ categoryId: 1 });
    await db.collection('products').createIndex({ name: 'text' });

    // Bookings indexes
    await db.collection('bookings').createIndex({ userId: 1 });
    await db.collection('bookings').createIndex({ stylistId: 1 });
    await db.collection('bookings').createIndex({ date: 1 });

    // Orders indexes
    await db.collection('orders').createIndex({ userId: 1 });
    await db.collection('orders').createIndex({ status: 1 });

    console.log('✓ Indexes created');
  } catch (error) {
    console.log('⚠ Index creation warning:', error.message);
  }
}

function getDB() {
  if (!cachedDb) {
    throw new Error('Database not connected');
  }
  return cachedDb;
}

function getClient() {
  if (!cachedClient) {
    throw new Error('Database client not connected');
  }
  return cachedClient;
}

async function disconnectDB() {
  if (cachedClient) {
    await cachedClient.close();
    cachedClient = null;
    cachedDb = null;
    console.log('✓ MongoDB disconnected');
  }
}

module.exports = { connectDB, getDB, getClient, disconnectDB };
