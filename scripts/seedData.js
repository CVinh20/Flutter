const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../backend/.env') });
const bcrypt = require('bcryptjs');

// Import models
const {
  Booking,
  Branch,
  Category,
  User,
  Order,
  ProductCategory,
  Product,
  ProductReview,
  Rating,
  Service,
  Stylist,
  Voucher,
  UserVoucher
} = require('../backend/models');

// Connect to database
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('MongoDB Connected for seeding');
  } catch (error) {
    console.error('Database connection error:', error.message);
    process.exit(1);
  }
};

// Sample data based on your requirements
const sampleData = {
  branches: [
    {
      name: "Gentlemen's Grooming - Thủ Đức",
      address: "test",
      hours: "8:00 - 22:00",
      image: "https://file1.hutech.edu.vn/file/editor/homepage1/944786-dsc01340.jpg",
      latitude: 10.4,
      longitude: 106.1,
      rating: 4.1,
      isActive: true
    }
  ],

  categories: [
    {
      name: "Massage",
      description: "Dịch vụ massage thư giãn",
      isActive: true,
      order: 1
    },
    {
      name: "Combo đặc biệt",
      description: "Các combo dịch vụ đặc biệt",
      isActive: true,
      order: 2
    }
  ],

  users: [
    {
      email: "admin@gmail.com",
      fullName: "Administrator",
      displayName: "Admin",
      role: "admin",
      isActive: true,
      phoneNumber: null,
      photoURL: null
    },
    {
      email: "anbestfizz@gmail.com",
      fullName: "AnNguyen",
      role: "stylist",
      stylistId: "PF4hNCEu0yUAArqk4u1c",
      isActive: true,
      phoneNumber: null,
      photoURL: null
    },
    {
      email: "lionjoki23@gmail.com",
      displayName: "Phèo Chí",
      fullName: "Phèo Chí",
      role: "customer",
      isActive: true,
      favoriteServices: ["J1oQRACWv1GWSA1kJVGQ", "9jsSEd0gOn8m5curZzTa"],
      photoURL: "https://lh3.googleusercontent.com/a/ACg8ocJf7PudT90qP_wdPGgFx5njfwmTdW9kAZ3_TqdosceG0TZNRfbf=s96-c",
      lastLoginAt: new Date("2025-11-11T16:18:45.000Z")
    }
  ],

  productCategories: [
    {
      name: "test",
      description: "test",
      isActive: true,
      imageUrl: null
    }
  ],

  products: [
    {
      name: "test",
      description: "test",
      price: 20000,
      categoryId: "w7w2qMh1IgozAvet1MYo",
      stock: 10,
      isActive: true,
      rating: null,
      reviewCount: 0,
      imageUrl: null
    }
  ],

  services: [
    {
      name: "Combo cướp cô dâu",
      categoryId: "H6kMoU2xX20aIpEbozKm",
      categoryName: "Combo đặc biệt",
      duration: "120",
      price: 300000,
      image: "https://avoonghairsalon.com/wp-content/uploads/2024/08/cat-toc-goi-dau.jpg",
      isFeatured: true,
      featuredOrder: 1,
      rating: 4.9,
      isActive: true
    },
    {
      name: "Combo Vip",
      categoryId: "H6kMoU2xX20aIpEbozKm",
      categoryName: "Combo đặc biệt",
      duration: "40",
      price: 100000,
      isFeatured: false,
      featuredOrder: 0,
      rating: 4.5,
      isActive: true
    }
  ],

  stylists: [
    {
      name: "khoi",
      branchId: "w7WFKfOAVpj2qbCavSHc",
      branchName: "Gentlemen's Grooming - Thủ Đức",
      experience: "2 năm",
      image: null,
      rating: 4.5,
      isActive: true,
      userId: "ew5vGtlHSUmEiLRM0pNg"
    },
    {
      name: "Vinh",
      branchId: "w7WFKfOAVpj2qbCavSHc",
      branchName: "Gentlemen's Grooming - Bình Thạnh",
      experience: "5 năm",
      image: "https://i.pinimg.com/736x/c9/5c/99/c95c993f1fda3cf7b146bd0520e2fb6e.jpg",
      rating: 5,
      isActive: true
    }
  ],

  vouchers: [
    {
      code: "TEST",
      title: "test",
      description: "test",
      type: 0,
      value: 20,
      condition: 0,
      maxUses: 30,
      currentUses: 0,
      startDate: new Date("2025-11-05T02:21:41.000Z"),
      endDate: new Date("2025-12-05T02:21:41.000Z"),
      isActive: true,
      isForNewUser: true,
      minAmount: null,
      specificServiceIds: null,
      imageUrl: null
    }
  ]
};

// Seed function
const seedDatabase = async () => {
  try {
    console.log('🌱 Starting database seeding...');

    // Clear existing data
    console.log('🗑️  Clearing existing data...');
    await Promise.all([
      Booking.deleteMany({}),
      Branch.deleteMany({}),
      Category.deleteMany({}),
      User.deleteMany({}),
      Order.deleteMany({}),
      ProductCategory.deleteMany({}),
      Product.deleteMany({}),
      ProductReview.deleteMany({}),
      Rating.deleteMany({}),
      Service.deleteMany({}),
      Stylist.deleteMany({}),
      Voucher.deleteMany({}),
      UserVoucher.deleteMany({})
    ]);

    // Insert sample data
    console.log('📝 Inserting sample data...');
    
    const branches = await Branch.insertMany(sampleData.branches);
    console.log(`✅ Inserted ${branches.length} branches`);

    const categories = await Category.insertMany(sampleData.categories);
    console.log(`✅ Inserted ${categories.length} categories`);

    // Hash passwords for users and insert
    const usersWithHashedPasswords = await Promise.all(
      sampleData.users.map(async (user) => {
        const hashedPassword = await bcrypt.hash('@123456', 10); // Default password
        return {
          ...user,
          password: hashedPassword,
          favoriteServices: user.favoriteServices || []
        };
      })
    );
    const users = await User.insertMany(usersWithHashedPasswords);
    console.log(`✅ Inserted ${users.length} users`);

    const productCategories = await ProductCategory.insertMany(sampleData.productCategories);
    console.log(`✅ Inserted ${productCategories.length} product categories`);

    // Update product categoryId to use actual inserted category ID
    const updatedProducts = sampleData.products.map(product => ({
      ...product,
      categoryId: productCategories[0]._id.toString()
    }));
    const products = await Product.insertMany(updatedProducts);
    console.log(`✅ Inserted ${products.length} products`);

    // Update service categoryId to use actual inserted category ID
    const updatedServices = sampleData.services.map(service => ({
      ...service,
      categoryId: categories[1]._id.toString()
    }));
    const services = await Service.insertMany(updatedServices);
    console.log(`✅ Inserted ${services.length} services`);

    // Update stylist branchId to use actual inserted branch ID
    const updatedStylists = sampleData.stylists.map(stylist => ({
      ...stylist,
      branchId: branches[0]._id.toString()
    }));
    const stylists = await Stylist.insertMany(updatedStylists);
    console.log(`✅ Inserted ${stylists.length} stylists`);

    const vouchers = await Voucher.insertMany(sampleData.vouchers);
    console.log(`✅ Inserted ${vouchers.length} vouchers`);

    // Create sample booking
    const sampleBooking = {
      branchName: "Gentlemen's Grooming - Thủ Đức",
      customerName: "Thân Quang Tuân",
      customerPhone: "0911822811",
      dateTime: new Date("2025-10-29T07:46:00.000Z"),
      discountAmount: 20000,
      finalAmount: 80000,
      note: "",
      paymentMethod: "vietqr",
      serviceDuration: "40 phút",
      serviceId: services[1]._id.toString(),
      serviceName: "Combo Vip",
      servicePrice: 100000,
      status: "confirmed",
      stylistId: stylists[0]._id.toString(),
      stylistName: "khoi",
      userId: users[1]._id.toString(),
      voucherId: vouchers[0]._id.toString()
    };

    const booking = await Booking.create(sampleBooking);
    console.log(`✅ Inserted 1 booking`);

    // Create sample order
    const sampleOrder = {
      customerName: "Chú 3 Duy",
      customerPhone: "222",
      customerAddress: "TPHCM",
      userId: users[1]._id.toString(),
      items: [{
        productId: products[0]._id.toString(),
        productName: "test",
        productImageUrl: null,
        price: 20000,
        quantity: 1
      }],
      subtotal: 20000,
      discountAmount: null,
      total: 20000,
      paymentMethod: "VietQR",
      isPaid: false,
      paidAt: null,
      status: "pending",
      voucherCode: null
    };

    const order = await Order.create(sampleOrder);
    console.log(`✅ Inserted 1 order`);

    // Create sample product review
    const sampleProductReview = {
      productId: products[0]._id.toString(),
      userId: users[1]._id.toString(),
      userName: "Chú 3 Duy",
      rating: 5,
      comment: "222"
    };

    const productReview = await ProductReview.create(sampleProductReview);
    console.log(`✅ Inserted 1 product review`);

    // Create sample rating
    const sampleRating = {
      bookingId: booking._id.toString(),
      userId: users[1]._id.toString(),
      userName: "Tuan",
      serviceId: services[1]._id.toString(),
      stylistId: stylists[0]._id.toString(),
      rating: 4.5,
      comment: "Dc"
    };

    const rating = await Rating.create(sampleRating);
    console.log(`✅ Inserted 1 rating`);

    // Create sample user voucher
    const sampleUserVoucher = {
      userId: users[1]._id.toString(),
      voucherId: vouchers[0]._id.toString(),
      claimedAt: new Date("2025-11-03T14:19:19.000Z"),
      isUsed: false,
      usedAt: null,
      usedInBookingId: null
    };

    const userVoucher = await UserVoucher.create(sampleUserVoucher);
    console.log(`✅ Inserted 1 user voucher`);

    console.log('🎉 Database seeding completed successfully!');
    console.log(`
📊 Summary:
- Branches: ${branches.length}
- Categories: ${categories.length}
- Users: ${users.length}
- Product Categories: ${productCategories.length}
- Products: ${products.length}
- Services: ${services.length}
- Stylists: ${stylists.length}
- Vouchers: ${vouchers.length}
- Bookings: 1
- Orders: 1
- Product Reviews: 1
- Ratings: 1
- User Vouchers: 1
    `);

  } catch (error) {
    console.error('❌ Error seeding database:', error);
  } finally {
    mongoose.connection.close();
  }
};

// Run seeding if called directly
if (require.main === module) {
  connectDB().then(seedDatabase);
}

module.exports = { seedDatabase, sampleData };
