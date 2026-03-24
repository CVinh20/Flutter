const mongoose = require('mongoose');
require('dotenv').config();
const bcrypt = require('bcryptjs');

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('✅ Connected to MongoDB');
    
    const User = require('../models/User');
    
    // Tạo user mới với ObjectId đúng format
    const existingUser = await User.findOne({ email: 'test@example.com' });
    
    if (existingUser) {
      console.log('User already exists:', existingUser._id.toString());
    } else {
      const hashedPassword = await bcrypt.hash('123456', 10);
      const newUser = await User.create({
        email: 'test@example.com',
        password: hashedPassword,
        fullName: 'Test User',
        phoneNumber: '0123456789',
        role: 'customer',
        isActive: true,
        favoriteServices: []
      });
      
      console.log('✅ Created new user:', newUser._id.toString());
      console.log('Email: test@example.com');
      console.log('Password: 123456');
    }
    
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Error:', err);
    process.exit(1);
  });
