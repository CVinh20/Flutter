const { ObjectId } = require('mongodb');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getDB } = require('../config/database');
const emailService = require('./EmailService');

class AuthService {
  // Register user
  static async register(userData) {
    const db = getDB();
    const usersCollection = db.collection('users');

    // Check if user exists
    const existingUser = await usersCollection.findOne({ email: userData.email });
    if (existingUser) {
      throw new Error('User already exists with that email');
    }

    // Check if stylistId already has an account
    if (userData.stylistId) {
      const existingStylistUser = await usersCollection.findOne({ stylistId: userData.stylistId });
      if (existingStylistUser) {
        throw new Error('This stylist already has an account');
      }
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(userData.password, 10);

    // Create user object
    const user = {
      ...userData,
      password: hashedPassword,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
      lastLoginAt: null,
      favoriteServices: []
    };

    // Insert user
    const result = await usersCollection.insertOne(user);

    // If stylistId provided, update stylist with userId
    if (userData.stylistId) {
      const stylistsCollection = db.collection('stylists');
      await stylistsCollection.updateOne(
        { _id: new ObjectId(userData.stylistId) },
        { $set: { userId: result.insertedId.toString() } }
      );
    }

    // Generate token
    const token = AuthService.generateToken({
        _id: result.insertedId,
        role: user.role
    });

    // Return user without password
    return {
      _id: result.insertedId,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      stylistId: user.stylistId,
      token
    };
  }

  // Login user
  static async login(email, password) {
    const db = getDB();
    const usersCollection = db.collection('users');

    // Find user
    const user = await usersCollection.findOne({ email });
    if (!user) {
      throw new Error('Invalid email or password');
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new Error('Invalid email or password');
    }

    // Check if user is active
    if (!user.isActive) {
      throw new Error('User account is deactivated');
    }

    // Update last login
    await usersCollection.updateOne(
      { _id: user._id },
      { $set: { lastLoginAt: new Date() } }
    );

    // Generate token
    const token = AuthService.generateToken(user);

    return {
      _id: user._id,
      email: user.email,
      fullName: user.fullName,
      displayName: user.displayName || user.fullName,
      phoneNumber: user.phoneNumber,
      role: user.role,
      stylistId: user.stylistId,
      isActive: user.isActive,
      favoriteServices: user.favoriteServices || [],
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      lastLoginAt: user.lastLoginAt,
      token
    };
  }

  // Google Sign In
  static async googleSignIn({ idToken, email, displayName, photoUrl }) {
    const db = getDB();
    const usersCollection = db.collection('users');

    // Note: For production, verify idToken with Google OAuth library
    // For now, we trust the client (should add google-auth-library verification)
    
    console.log('🔵 Google Sign In:', { email, displayName });

    // Find existing user by email
    let user = await usersCollection.findOne({ email });

    if (user) {
      // Existing user - update last login and Google info
      console.log('✅ Existing user found:', user._id);
      
      await usersCollection.updateOne(
        { _id: user._id },
        { 
          $set: { 
            lastLoginAt: new Date(),
            photoURL: photoUrl || user.photoURL,
            displayName: displayName || user.displayName
          } 
        }
      );
    } else {
      // New user - create account
      console.log('🆕 Creating new user for:', email);
      
      const newUser = {
        email,
        fullName: displayName || email.split('@')[0],
        displayName: displayName || email.split('@')[0],
        photoURL: photoUrl,
        password: await bcrypt.hash(Math.random().toString(36), 10), // Random password for Google users
        role: 'customer',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
        lastLoginAt: new Date(),
        favoriteServices: [],
        googleSignIn: true
      };

      const result = await usersCollection.insertOne(newUser);
      user = { ...newUser, _id: result.insertedId };
      console.log('✅ New user created:', user._id);
    }

    // Check if user is active
    if (!user.isActive) {
      throw new Error('User account is deactivated');
    }

    // Generate token
    const token = AuthService.generateToken(user);

    return {
      _id: user._id,
      email: user.email,
      fullName: user.fullName,
      displayName: user.displayName,
      photoURL: user.photoURL,
      phoneNumber: user.phoneNumber,
      role: user.role,
      stylistId: user.stylistId,
      isActive: user.isActive,
      favoriteServices: user.favoriteServices || [],
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      lastLoginAt: user.lastLoginAt,
      token
    };
  }

  // Get current user
  static async getCurrentUser(userId) {
    const db = getDB();
    const usersCollection = db.collection('users');

    const user = await usersCollection.findOne(
      { _id: new ObjectId(userId) },
      { projection: { password: 0 } }
    );

    if (!user) {
      throw new Error('User not found');
    }

    return user;
  }

  // Update profile
  static async updateProfile(userId, updateData) {
    const db = getDB();
    const usersCollection = db.collection('users');

    // Remove sensitive fields
    delete updateData.password;
    delete updateData.email;
    delete updateData.role;

    const result = await usersCollection.findOneAndUpdate(
      { _id: new ObjectId(userId) },
      { $set: { ...updateData, updatedAt: new Date() } },
      { returnDocument: 'after' }
    );

    if (!result.value) {
      // Fallback: Find and merge manually
      const user = await usersCollection.findOne({ _id: new ObjectId(userId) });
      if (!user) {
        throw new Error('User not found');
      }
      
      // Update manually
      await usersCollection.updateOne(
        { _id: new ObjectId(userId) },
        { $set: { ...updateData, updatedAt: new Date() } }
      );
      
      // Fetch updated user
      const updatedUser = await usersCollection.findOne({ _id: new ObjectId(userId) });
      return updatedUser;
    }

    return result.value;
  }

  // Change password
  static async changePassword(userId, currentPassword, newPassword) {
    const db = getDB();
    const usersCollection = db.collection('users');

    const user = await usersCollection.findOne({ _id: new ObjectId(userId) });
    if (!user) {
      throw new Error('User not found');
    }

    // Verify current password
    const isPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isPasswordValid) {
      throw new Error('Current password is incorrect');
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password
    await usersCollection.updateOne(
      { _id: new ObjectId(userId) },
      { $set: { password: hashedPassword, updatedAt: new Date() } }
    );
  }

  // Send password reset email
  static async sendPasswordResetEmail(email) {
    const db = getDB();
    const usersCollection = db.collection('users');

    // Check if user exists
    const user = await usersCollection.findOne({ email });
    if (!user) {
      throw new Error('No account found with that email address');
    }

    // Generate reset token (valid for 1 hour)
    const resetToken = jwt.sign(
      { userId: user._id.toString(), type: 'password_reset' },
      process.env.JWT_SECRET || 'your_jwt_secret_key',
      { expiresIn: '1h' }
    );

    // Store reset token in database
    await usersCollection.updateOne(
      { _id: user._id },
      { 
        $set: { 
          resetPasswordToken: resetToken,
          resetPasswordExpires: new Date(Date.now() + 3600000), // 1 hour
          updatedAt: new Date()
        } 
      }
    );

    // Log reset link ra console (không gửi email)
    const resetLink = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?token=${resetToken}`;
    console.log('📧 Password Reset Link:', resetLink);
    console.log('📧 Reset token for', user.email, ':', resetToken);

    return { message: 'Password reset link generated. Check console for link.' };
  }

  // Reset password with token
  static async resetPassword(resetToken, newPassword) {
    const db = getDB();
    const usersCollection = db.collection('users');

    // Verify token
    let decoded;
    try {
      decoded = jwt.verify(resetToken, process.env.JWT_SECRET || 'your_jwt_secret_key');
      if (decoded.type !== 'password_reset') {
        throw new Error('Invalid token type');
      }
    } catch (error) {
      throw new Error('Invalid or expired reset token');
    }

    // Find user with valid reset token
    const user = await usersCollection.findOne({
      _id: new ObjectId(decoded.userId),
      resetPasswordToken: resetToken,
      resetPasswordExpires: { $gt: new Date() }
    });

    if (!user) {
      throw new Error('Invalid or expired reset token');
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password and clear reset token
    await usersCollection.updateOne(
      { _id: user._id },
      { 
        $set: { 
          password: hashedPassword,
          updatedAt: new Date()
        },
        $unset: {
          resetPasswordToken: '',
          resetPasswordExpires: ''
        }
      }
    );
  }

  // Generate JWT token
  static generateToken(user) {
  return jwt.sign(
    {
      id: user._id.toString(),
      role: user.role,        
    },
    process.env.JWT_SECRET || 'your_jwt_secret_key',
    { expiresIn: process.env.JWT_EXPIRE || '7d' }
  );
}

  // Verify JWT token
  static verifyToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret_key');
    } catch (error) {
      throw new Error('Invalid token');
    }
  }
}

module.exports = AuthService;
