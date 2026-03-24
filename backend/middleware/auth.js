const jwt = require('jsonwebtoken');
const { ObjectId } = require('mongodb');
const asyncHandler = require('./asyncHandler');
const { getDB } = require('../config/database');

// Protect routes - check if user is authenticated
const protect = asyncHandler(async (req, res, next) => {
  let token;

  // Check for token in headers
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  // Make sure token exists
  if (!token) {
    console.log('❌ No token provided in request');
    return res.status(401).json({
      success: false,
      error: 'Not authorized to access this route'
    });
  }

  try {
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret_key');
    console.log('✅ Token verified for user:', decoded.id);

    // Get user from MongoDB database
    const db = getDB();
    const usersCollection = db.collection('users');
    
    const user = await usersCollection.findOne(
      { _id: new ObjectId(decoded.id) },
      { projection: { password: 0 } }
    );

    if (!user) {
      console.log('❌ User not found:', decoded.id);
      return res.status(401).json({
        success: false,
        error: 'User not found'
      });
    }

    if (!user.isActive) {
      console.log('❌ User inactive:', decoded.id);
      return res.status(401).json({
        success: false,
        error: 'User account is deactivated'
      });
    }

    req.user = user;
    next();
  } catch (error) {
    console.log('❌ Token verification failed:', error.message);
    return res.status(401).json({
      success: false,
      error: 'Not authorized to access this route'
    });
  }
});

// Grant access to specific roles
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: `User role ${req.user.role} is not authorized to access this route`
      });
    }
    next();
  };
};

// Optional auth - don't fail if no token, but set user if token exists
const optionalAuth = asyncHandler(async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (token) {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret_key');
      
      // Get user from MongoDB database
      const db = getDB();
      const usersCollection = db.collection('users');
      
      req.user = await usersCollection.findOne(
        { _id: new ObjectId(decoded.id) },
        { projection: { password: 0 } }
      );
    } catch (error) {
      // Token invalid, but continue without user
      req.user = null;
    }
  }

  next();
});

module.exports = {
  protect,
  authorize,
  optionalAuth
};
