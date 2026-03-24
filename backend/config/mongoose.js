const mongoose = require('mongoose');
require('dotenv').config();

const connectMongoose = async () => {
    try {
        const mongoUri = process.env.MONGODB_URI;

        if (!mongoUri) {
            throw new Error('MONGODB_URI is not defined in environment variables');
        }

        const options = {
            retryWrites: true,
            w: 'majority',
            maxPoolSize: 10,
            minPoolSize: 1,
            serverSelectionTimeoutMS: 5000,
            socketTimeoutMS: 45000,
        };

        await mongoose.connect(mongoUri, options);

        console.log('✅ Mongoose connected successfully to MongoDB');
        console.log(`📦 Database: ${mongoose.connection.db.databaseName}`);

        // Handle connection events
        mongoose.connection.on('error', (err) => {
            console.error('❌ Mongoose connection error:', err);
        });

        mongoose.connection.on('disconnected', () => {
            console.log('⚠️  Mongoose disconnected');
        });

        return mongoose.connection;
    } catch (error) {
        console.error('❌ Mongoose connection failed:', error.message);
        throw error;
    }
};

module.exports = { connectMongoose };
