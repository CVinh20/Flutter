const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Category = require('../models/Category');
const Service = require('../models/Service');

// Connect to MongoDB
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected successfully');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

// Categories data
const categories = [
  {
    name: 'Cắt tóc',
    description: 'Các dịch vụ cắt tóc chuyên nghiệp',
    image: 'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?w=400',
    order: 1,
    isActive: true
  },
  {
    name: 'Nhuộm tóc',
    description: 'Dịch vụ nhuộm tóc với màu sắc đa dạng',
    image: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
    order: 2,
    isActive: true
  },
  {
    name: 'Uốn tóc',
    description: 'Uốn tóc theo xu hướng mới nhất',
    image: 'https://images.unsplash.com/photo-1522337660859-02fbefca4702?w=400',
    order: 3,
    isActive: true
  },
  {
    name: 'Duỗi tóc',
    description: 'Duỗi tóc bằng công nghệ hiện đại',
    image: 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=400',
    order: 4,
    isActive: true
  },
  {
    name: 'Gội đầu',
    description: 'Dịch vụ gội đầu massage thư giãn',
    image: 'https://images.unsplash.com/photo-1519699047748-de8e457a634e?w=400',
    order: 5,
    isActive: true
  },
  {
    name: 'Tạo kiểu',
    description: 'Tạo kiểu tóc cho các sự kiện đặc biệt',
    image: 'https://images.unsplash.com/photo-1560869713-7d0a29430803?w=400',
    order: 6,
    isActive: true
  }
];

// Services data (will be linked to categories after creation)
const servicesData = [
  // Cắt tóc
  {
    categoryName: 'Cắt tóc',
    name: 'Cắt tóc Nam cơ bản',
    description: 'Cắt tóc nam theo phong cách hiện đại, bao gồm gội đầu',
    price: 100000,
    duration: 30,
    image: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400',
    isFeatured: true
  },
  {
    categoryName: 'Cắt tóc',
    name: 'Cắt tóc Nam cao cấp',
    description: 'Cắt tóc nam cao cấp với stylist giàu kinh nghiệm, bao gồm gội + massage',
    price: 200000,
    duration: 45,
    image: 'https://images.unsplash.com/photo-1605497788044-5a32c7078486?w=400',
    isFeatured: true
  },
  {
    categoryName: 'Cắt tóc',
    name: 'Cắt tóc Nữ',
    description: 'Cắt tóc nữ theo xu hướng, tư vấn kiểu tóc phù hợp',
    price: 150000,
    duration: 45,
    image: 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=400',
    isFeatured: true
  },
  {
    categoryName: 'Cắt tóc',
    name: 'Cắt tóc Trẻ em',
    description: 'Cắt tóc cho trẻ em dưới 12 tuổi',
    price: 80000,
    duration: 20,
    image: 'https://images.unsplash.com/photo-1503951458645-643d53bfd90f?w=400',
    isFeatured: false
  },

  // Nhuộm tóc
  {
    categoryName: 'Nhuộm tóc',
    name: 'Nhuộm tóc 1 màu',
    description: 'Nhuộm tóc 1 màu toàn bộ với thuốc nhuộm cao cấp',
    price: 300000,
    duration: 90,
    image: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
    isFeatured: true
  },
  {
    categoryName: 'Nhuộm tóc',
    name: 'Nhuộm Highlight',
    description: 'Nhuộm highlight tạo điểm nhấn cho mái tóc',
    price: 400000,
    duration: 120,
    image: 'https://images.unsplash.com/photo-1582095133179-bfd08e2fc6b3?w=400',
    isFeatured: true
  },
  {
    categoryName: 'Nhuộm tóc',
    name: 'Nhuộm Ombre',
    description: 'Nhuộm ombre chuyển màu gradient tự nhiên',
    price: 500000,
    duration: 150,
    image: 'https://images.unsplash.com/photo-1522338140262-f46f5913618a?w=400',
    isFeatured: false
  },
  {
    categoryName: 'Nhuộm tóc',
    name: 'Tẩy tóc',
    description: 'Tẩy màu tóc cũ để chuẩn bị nhuộm màu mới',
    price: 250000,
    duration: 90,
    image: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400',
    isFeatured: false
  },

  // Uốn tóc
  {
    categoryName: 'Uốn tóc',
    name: 'Uốn xoăn tự nhiên',
    description: 'Uốn tóc xoăn tự nhiên, giữ form lâu',
    price: 400000,
    duration: 120,
    image: 'https://images.unsplash.com/photo-1522337660859-02fbefca4702?w=400',
    isFeatured: true
  },
  {
    categoryName: 'Uốn tóc',
    name: 'Uốn đuôi',
    description: 'Uốn đuôi tóc tạo phồng, sóng nhẹ',
    price: 300000,
    duration: 90,
    image: 'https://images.unsplash.com/photo-1519699047748-de8e457a634e?w=400',
    isFeatured: false
  },
  {
    categoryName: 'Uốn tóc',
    name: 'Uốn Hàn Quốc',
    description: 'Uốn tóc kiểu Hàn Quốc với sóng tự nhiên',
    price: 600000,
    duration: 150,
    image: 'https://images.unsplash.com/photo-1492106087820-71f1a00d2b11?w=400',
    isFeatured: true
  },

  // Duỗi tóc
  {
    categoryName: 'Duỗi tóc',
    name: 'Duỗi thẳng tự nhiên',
    description: 'Duỗi tóc thẳng tự nhiên không gây hại',
    price: 350000,
    duration: 120,
    image: 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=400',
    isFeatured: true
  },
  {
    categoryName: 'Duỗi tóc',
    name: 'Duỗi phồng',
    description: 'Duỗi tóc tạo độ phồng tự nhiên',
    price: 400000,
    duration: 150,
    image: 'https://images.unsplash.com/photo-1522338242992-e1a54906a8da?w=400',
    isFeatured: false
  },

  // Gội đầu
  {
    categoryName: 'Gội đầu',
    name: 'Gội đầu cơ bản',
    description: 'Gội đầu với dầu gội cao cấp',
    price: 50000,
    duration: 15,
    image: 'https://images.unsplash.com/photo-1519699047748-de8e457a634e?w=400',
    isFeatured: false
  },
  {
    categoryName: 'Gội đầu',
    name: 'Gội đầu Massage',
    description: 'Gội đầu kèm massage thư giãn 30 phút',
    price: 100000,
    duration: 30,
    image: 'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=400',
    isFeatured: true
  },
  {
    categoryName: 'Gội đầu',
    name: 'Gội đầu + Hấp dầu',
    description: 'Gội đầu kèm hấp dầu dưỡng tóc',
    price: 150000,
    duration: 45,
    image: 'https://images.unsplash.com/photo-1560869713-7d0a29430803?w=400',
    isFeatured: true
  },

  // Tạo kiểu
  {
    categoryName: 'Tạo kiểu',
    name: 'Tạo kiểu cơ bản',
    description: 'Tạo kiểu tóc đơn giản cho ngày thường',
    price: 80000,
    duration: 20,
    image: 'https://images.unsplash.com/photo-1560869713-7d0a29430803?w=400',
    isFeatured: false
  },
  {
    categoryName: 'Tạo kiểu',
    name: 'Tạo kiểu dự tiệc',
    description: 'Tạo kiểu tóc cho tiệc cưới, sự kiện',
    price: 300000,
    duration: 60,
    image: 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=400',
    isFeatured: true
  },
  {
    categoryName: 'Tạo kiểu',
    name: 'Tạo kiểu cô dâu',
    description: 'Tạo kiểu tóc cô dâu chuyên nghiệp',
    price: 500000,
    duration: 90,
    image: 'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?w=400',
    isFeatured: true
  }
];

// Seed function
const seedData = async () => {
  try {
    console.log('🌱 Starting seed process...');

    // Clear existing data
    console.log('🗑️  Clearing existing categories and services...');
    await Category.deleteMany({});
    await Service.deleteMany({});
    console.log('✅ Cleared old data');

    // Create categories
    console.log('📝 Creating categories...');
    const createdCategories = await Category.insertMany(categories);
    console.log(`✅ Created ${createdCategories.length} categories`);

    // Create a map of category names to IDs
    const categoryMap = {};
    createdCategories.forEach(cat => {
      categoryMap[cat.name] = cat._id;
    });

    // Create services with category references
    console.log('📝 Creating services...');
    const servicesWithCategoryIds = servicesData.map(service => {
      const categoryId = categoryMap[service.categoryName];
      return {
        name: service.name,
        description: service.description,
        price: service.price,
        duration: service.duration.toString(), // Convert to string as per schema
        image: service.image,
        isFeatured: service.isFeatured,
        categoryId: categoryId.toString(), // Store as string
        categoryName: service.categoryName, // Keep categoryName
        isActive: true,
        rating: 0,
        reviewCount: 0,
        featuredOrder: service.isFeatured ? 1 : 0
      };
    });

    const createdServices = await Service.insertMany(servicesWithCategoryIds);
    console.log(`✅ Created ${createdServices.length} services`);

    // Print summary
    console.log('\n📊 SEED SUMMARY:');
    console.log('================');
    console.log(`Categories: ${createdCategories.length}`);
    createdCategories.forEach(cat => {
      const serviceCount = servicesWithCategoryIds.filter(s => s.categoryId === cat._id.toString()).length;
      console.log(`  - ${cat.name}: ${serviceCount} services`);
    });
    console.log(`\nTotal Services: ${createdServices.length}`);
    console.log(`Featured Services: ${createdServices.filter(s => s.isFeatured).length}`);

    console.log('\n✅ Seed completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Seed error:', error);
    process.exit(1);
  }
};

// Run seed
connectDB().then(seedData);
