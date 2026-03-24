const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Branch = require('../models/Branch');
const Stylist = require('../models/Stylist');

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

// Branches data
const branches = [
  {
    name: 'Chi nhánh Quận 1',
    address: '123 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM',
    hours: '8:00 - 20:00',
    latitude: 10.7769,
    longitude: 106.7009,
    image: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=600',
    isActive: true,
    rating: 4.8
  },
  {
    name: 'Chi nhánh Quận 3',
    address: '456 Võ Văn Tần, Phường 5, Quận 3, TP.HCM',
    hours: '8:00 - 21:00',
    latitude: 10.7756,
    longitude: 106.6898,
    image: 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=600',
    isActive: true,
    rating: 4.7
  },
  {
    name: 'Chi nhánh Bình Thạnh',
    address: '789 Điện Biên Phủ, Phường 15, Bình Thạnh, TP.HCM',
    hours: '8:00 - 20:00',
    latitude: 10.8015,
    longitude: 106.7132,
    image: 'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=600',
    isActive: true,
    rating: 4.9
  },
  {
    name: 'Chi nhánh Tân Bình',
    address: '321 Cộng Hòa, Phường 13, Tân Bình, TP.HCM',
    hours: '8:00 - 20:00',
    latitude: 10.7991,
    longitude: 106.6443,
    image: 'https://images.unsplash.com/photo-1560869713-7d0a29430803?w=600',
    isActive: true,
    rating: 4.6
  },
  {
    name: 'Chi nhánh Thủ Đức',
    address: '567 Võ Văn Ngân, Phường Linh Chiểu, Thủ Đức, TP.HCM',
    hours: '8:00 - 21:00',
    latitude: 10.8506,
    longitude: 106.7718,
    image: 'https://images.unsplash.com/photo-1519699047748-de8e457a634e?w=600',
    isActive: true,
    rating: 4.8
  }
];

// Stylists data (will be linked to branches after creation)
const stylistsData = [
  // Quận 1
  {
    branchName: 'Chi nhánh Quận 1',
    name: 'Anh Tuấn',
    phone: '0912345678',
    email: 'anhtuan@hairsalon.vn',
    specialties: ['Cắt tóc Nam', 'Tạo kiểu'],
    experience: 8,
    bio: 'Stylist giàu kinh nghiệm với hơn 8 năm trong nghề. Chuyên về các kiểu tóc nam hiện đại.',
    avatar: 'https://i.pravatar.cc/300?img=33',
    rating: 4.9,
    reviewCount: 234,
    isActive: true,
    isFeatured: true
  },
  {
    branchName: 'Chi nhánh Quận 1',
    name: 'Chị Lan',
    phone: '0912345679',
    email: 'lan@hairsalon.vn',
    specialties: ['Nhuộm tóc', 'Uốn tóc', 'Cắt tóc Nữ'],
    experience: 10,
    bio: 'Chuyên gia nhuộm và uốn tóc với hơn 10 năm kinh nghiệm. Luôn cập nhật xu hướng mới nhất.',
    avatar: 'https://i.pravatar.cc/300?img=47',
    rating: 5.0,
    reviewCount: 312,
    isActive: true,
    isFeatured: true
  },
  {
    branchName: 'Chi nhánh Quận 1',
    name: 'Anh Minh',
    phone: '0912345680',
    email: 'minh@hairsalon.vn',
    specialties: ['Cắt tóc Nam', 'Duỗi tóc'],
    experience: 6,
    bio: 'Stylist trẻ năng động, sáng tạo với phong cách hiện đại.',
    avatar: 'https://i.pravatar.cc/300?img=12',
    rating: 4.7,
    reviewCount: 156,
    isActive: true,
    isFeatured: false
  },

  // Quận 3
  {
    branchName: 'Chi nhánh Quận 3',
    name: 'Anh Hùng',
    phone: '0912345681',
    email: 'hung@hairsalon.vn',
    specialties: ['Cắt tóc Nam', 'Cắt tóc Nữ', 'Tạo kiểu'],
    experience: 12,
    bio: 'Master stylist với 12 năm kinh nghiệm. Đã từng làm việc tại Hàn Quốc.',
    avatar: 'https://i.pravatar.cc/300?img=15',
    rating: 4.9,
    reviewCount: 445,
    isActive: true,
    isFeatured: true
  },
  {
    branchName: 'Chi nhánh Quận 3',
    name: 'Chị Hương',
    phone: '0912345682',
    email: 'huong@hairsalon.vn',
    specialties: ['Nhuộm tóc', 'Highlight', 'Ombre'],
    experience: 9,
    bio: 'Chuyên gia nhuộm màu sáng tạo, luôn mang đến những màu sắc độc đáo.',
    avatar: 'https://i.pravatar.cc/300?img=45',
    rating: 4.8,
    reviewCount: 267,
    isActive: true,
    isFeatured: true
  },
  {
    branchName: 'Chi nhánh Quận 3',
    name: 'Anh Khoa',
    phone: '0912345683',
    email: 'khoa@hairsalon.vn',
    specialties: ['Cắt tóc Nam', 'Gội đầu'],
    experience: 5,
    bio: 'Stylist nhiệt tình, chu đáo với khách hàng.',
    avatar: 'https://i.pravatar.cc/300?img=60',
    rating: 4.6,
    reviewCount: 134,
    isActive: true,
    isFeatured: false
  },

  // Bình Thạnh
  {
    branchName: 'Chi nhánh Bình Thạnh',
    name: 'Anh Phong',
    phone: '0912345684',
    email: 'phong@hairsalon.vn',
    specialties: ['Cắt tóc Nam', 'Uốn tóc', 'Tạo kiểu'],
    experience: 11,
    bio: 'Stylist hàng đầu chuyên về tạo kiểu cho sự kiện. Từng làm việc cho nhiều người nổi tiếng.',
    avatar: 'https://i.pravatar.cc/300?img=68',
    rating: 5.0,
    reviewCount: 523,
    isActive: true,
    isFeatured: true
  },
  {
    branchName: 'Chi nhánh Bình Thạnh',
    name: 'Chị Mai',
    phone: '0912345685',
    email: 'mai@hairsalon.vn',
    specialties: ['Cắt tóc Nữ', 'Duỗi tóc', 'Hấp dầu'],
    experience: 8,
    bio: 'Chuyên gia chăm sóc tóc với kỹ thuật duỗi phục hồi không gây hại.',
    avatar: 'https://i.pravatar.cc/300?img=48',
    rating: 4.9,
    reviewCount: 298,
    isActive: true,
    isFeatured: true
  },
  {
    branchName: 'Chi nhánh Bình Thạnh',
    name: 'Chị Thu',
    phone: '0912345686',
    email: 'thu@hairsalon.vn',
    specialties: ['Nhuộm tóc', 'Uốn tóc'],
    experience: 7,
    bio: 'Stylist tận tâm với khách hàng, luôn tư vấn nhiệt tình.',
    avatar: 'https://i.pravatar.cc/300?img=23',
    rating: 4.7,
    reviewCount: 189,
    isActive: true,
    isFeatured: false
  },

  // Tân Bình
  {
    branchName: 'Chi nhánh Tân Bình',
    name: 'Anh Tài',
    phone: '0912345687',
    email: 'tai@hairsalon.vn',
    specialties: ['Cắt tóc Nam', 'Cắt tóc Nữ'],
    experience: 9,
    bio: 'Stylist all-round với khả năng cắt tạo mọi kiểu tóc.',
    avatar: 'https://i.pravatar.cc/300?img=52',
    rating: 4.8,
    reviewCount: 276,
    isActive: true,
    isFeatured: true
  },
  {
    branchName: 'Chi nhánh Tân Bình',
    name: 'Chị Nga',
    phone: '0912345688',
    email: 'nga@hairsalon.vn',
    specialties: ['Nhuộm tóc', 'Tạo kiểu'],
    experience: 6,
    bio: 'Stylist sáng tạo với những ý tưởng màu tóc độc đáo.',
    avatar: 'https://i.pravatar.cc/300?img=44',
    rating: 4.7,
    reviewCount: 198,
    isActive: true,
    isFeatured: false
  },

  // Thủ Đức
  {
    branchName: 'Chi nhánh Thủ Đức',
    name: 'Anh Long',
    phone: '0912345689',
    email: 'long@hairsalon.vn',
    specialties: ['Cắt tóc Nam', 'Uốn tóc'],
    experience: 10,
    bio: 'Stylist chuyên nghiệp với kỹ thuật cắt chính xác và nhanh chóng.',
    avatar: 'https://i.pravatar.cc/300?img=56',
    rating: 4.9,
    reviewCount: 334,
    isActive: true,
    isFeatured: true
  },
  {
    branchName: 'Chi nhánh Thủ Đức',
    name: 'Chị Linh',
    phone: '0912345690',
    email: 'linh@hairsalon.vn',
    specialties: ['Cắt tóc Nữ', 'Nhuộm tóc', 'Duỗi tóc'],
    experience: 8,
    bio: 'Stylist đa năng, luôn tạo ra những kiểu tóc đẹp và phù hợp.',
    avatar: 'https://i.pravatar.cc/300?img=26',
    rating: 4.8,
    reviewCount: 245,
    isActive: true,
    isFeatured: true
  },
  {
    branchName: 'Chi nhánh Thủ Đức',
    name: 'Anh Nam',
    phone: '0912345691',
    email: 'nam@hairsalon.vn',
    specialties: ['Cắt tóc Nam', 'Gội đầu'],
    experience: 4,
    bio: 'Stylist trẻ năng động, nhiệt huyết với nghề.',
    avatar: 'https://i.pravatar.cc/300?img=70',
    rating: 4.6,
    reviewCount: 112,
    isActive: true,
    isFeatured: false
  }
];

// Seed function
const seedData = async () => {
  try {
    console.log('🌱 Starting seed process...');

    // Clear existing data
    console.log('🗑️  Clearing existing branches and stylists...');
    await Branch.deleteMany({});
    await Stylist.deleteMany({});
    console.log('✅ Cleared old data');

    // Create branches
    console.log('📝 Creating branches...');
    const createdBranches = await Branch.insertMany(branches);
    console.log(`✅ Created ${createdBranches.length} branches`);

    // Create a map of branch names to IDs
    const branchMap = {};
    createdBranches.forEach(branch => {
      branchMap[branch.name] = branch._id;
    });

    // Create stylists with branch references
    console.log('📝 Creating stylists...');
    const stylistsWithBranchIds = stylistsData.map(stylist => {
      const branchId = branchMap[stylist.branchName];
      return {
        name: stylist.name,
        specialties: stylist.specialties,
        experience: `${stylist.experience} năm`, // Convert to string with "năm"
        image: stylist.avatar, // Map avatar to image
        rating: stylist.rating,
        reviewCount: stylist.reviewCount,
        branchId: branchId.toString(),
        branchName: stylist.branchName,
        isActive: stylist.isActive
      };
    });

    const createdStylists = await Stylist.insertMany(stylistsWithBranchIds);
    console.log(`✅ Created ${createdStylists.length} stylists`);

    // Print summary
    console.log('\n📊 SEED SUMMARY:');
    console.log('================');
    console.log(`Branches: ${createdBranches.length}`);
    createdBranches.forEach(branch => {
      const stylistCount = stylistsWithBranchIds.filter(s => s.branchId === branch._id.toString()).length;
      console.log(`  - ${branch.name}: ${stylistCount} stylists`);
    });
    console.log(`\nTotal Stylists: ${createdStylists.length}`);

    console.log('\n✅ Seed completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Seed error:', error);
    process.exit(1);
  }
};

// Run seed
connectDB().then(seedData);
