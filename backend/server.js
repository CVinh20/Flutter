const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

// Load environment variables FIRST - before any other imports
require('dotenv').config({ path: '.env' });

// Verify MongoDB URI is loaded
console.log('🔍 Checking environment:');
console.log('  MONGODB_URI:', process.env.MONGODB_URI ? '✅ Loaded' : '❌ NOT FOUND');
console.log('  PORT:', process.env.PORT || 5000);

// Import Mongoose connection
const { connectMongoose } = require('./config/mongoose');
const { connectDB } = require('./config/database');

// Import middleware
const errorHandler = require('./middleware/errorHandler');

// Import routes
const apiRoutes = require('./routes');

// Create Express app first
const app = express();

// Connect to database - need to await this
async function initializeApp() {
  try {
    // Connect both Mongoose and Native Driver
    await connectMongoose();
    await connectDB();
    console.log('✅ Database initialization completed');
    
    // Start server after DB connection
    const PORT = process.env.PORT || 5000;
    const server = app.listen(PORT, () => {
      console.log(`
🚀 Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}
📚 API Documentation: http://localhost:${PORT}/api
🏥 Health Check: http://localhost:${PORT}/api/health
      `);
    });
    
    // Handle unhandled promise rejections
    process.on('unhandledRejection', (err, promise) => {
      console.log(`Error: ${err.message}`);
      server.close(() => process.exit(1));
    });
    
    // Handle uncaught exceptions
    process.on('uncaughtException', (err) => {
      console.log(`Error: ${err.message}`);
      console.log('Shutting down the server due to Uncaught Exception');
      process.exit(1);
    });
    
  } catch (error) {
    console.error('❌ Failed to connect to database:', error);
    process.exit(1);
  }
}

// Initialize database first, then start server
initializeApp();

// Security middleware
app.use(helmet());

// CORS middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    success: false,
    error: 'Too many requests from this IP, please try again later.'
  }
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Logging middleware
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Serve uploaded files
app.use('/uploads', express.static('uploads'));

// API Routes
app.use('/api', apiRoutes);

// Test email endpoint
app.get('/api/test-email', async (req, res) => {
  try {
    const emailService = require('./services/EmailService');
    const isConnected = await emailService.testConnection();
    
    if (isConnected) {
      res.json({
        success: true,
        message: 'SMTP connection successful! Email service is ready.',
        config: {
          host: process.env.SMTP_HOST,
          port: process.env.SMTP_PORT,
          user: process.env.SMTP_USER,
          secure: process.env.SMTP_SECURE === 'true'
        }
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'SMTP connection failed. Check your .env configuration.',
        hint: 'Make sure SMTP_USER and SMTP_PASS are correct. For Gmail, use App Password.'
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to test email service',
      details: error.message
    });
  }
});

// Welcome route
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Welcome to Gentlemen\'s Grooming API',
    version: '1.0.0',
    documentation: '/api',
    health: '/api/health'
  });
});

// Handle 404 routes
app.all('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: `Route ${req.originalUrl} not found`
  });
});

// Error handling middleware (must be last)
app.use(errorHandler);

module.exports = app;
