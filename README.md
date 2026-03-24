# Gentlemen's Grooming Backend API

Backend API cho ứng dụng Gentlemen's Grooming được xây dựng với Node.js, Express.js và MongoDB.

## 🚀 Tính năng

- **CRUD hoàn chỉnh** cho tất cả collections
- **Validation** dữ liệu với express-validator
- **Error handling** tập trung
- **Pagination** cho các API list
- **Search và Filter** nâng cao
- **Rate limiting** bảo mật
- **CORS** hỗ trợ
- **Logging** với Morgan
- **Database seeding** với dữ liệu mẫu

## 📋 Collections

### Core Collections
- **Bookings** - Quản lý đặt lịch
- **Users** - Quản lý người dùng
- **Services** - Quản lý dịch vụ
- **Stylists** - Quản lý thợ cắt tóc
- **Branches** - Quản lý chi nhánh

### Product Collections
- **Products** - Quản lý sản phẩm
- **ProductCategories** - Danh mục sản phẩm
- **ProductReviews** - Đánh giá sản phẩm
- **Orders** - Đơn hàng

### Support Collections
- **Categories** - Danh mục dịch vụ
- **Vouchers** - Mã giảm giá
- **UserVouchers** - Voucher của người dùng
- **Ratings** - Đánh giá dịch vụ

## 🛠️ Cài đặt

### 1. Clone repository
```bash
git clone <repository-url>
cd grooming-backend
```

### 2. Cài đặt dependencies
```bash
npm install
```

### 3. Cấu hình môi trường
Tạo file `.env` từ `env.example`:
```bash
cp env.example .env
```

Cập nhật các biến môi trường trong `.env`:
```env
# Database
MONGODB_URI=mongodb://localhost:27017/grooming_db

# Server
PORT=5000
NODE_ENV=development

# JWT
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRE=7d

# CORS
CORS_ORIGIN=http://localhost:3000
```

### 4. Khởi động MongoDB
Đảm bảo MongoDB đang chạy trên máy của bạn.

### 5. Seed dữ liệu mẫu (tùy chọn)
```bash
node scripts/seedData.js
```

### 6. Khởi động server
```bash
# Development mode
npm run dev

# Production mode
npm start
```

## 📚 API Documentation

Server sẽ chạy tại `http://localhost:5000`

### Base URLs
- **API Base**: `http://localhost:5000/api`
- **Health Check**: `http://localhost:5000/api/health`
- **API Info**: `http://localhost:5000/api`

### Endpoints chính

#### Bookings
- `GET /api/bookings` - Lấy danh sách booking
- `POST /api/bookings` - Tạo booking mới
- `GET /api/bookings/:id` - Lấy booking theo ID
- `PUT /api/bookings/:id` - Cập nhật booking
- `DELETE /api/bookings/:id` - Xóa booking
- `GET /api/bookings/user/:userId` - Booking theo user
- `GET /api/bookings/stylist/:stylistId` - Booking theo stylist
- `PATCH /api/bookings/:id/status` - Cập nhật trạng thái

#### Users
- `GET /api/users` - Lấy danh sách user
- `POST /api/users` - Tạo user mới
- `GET /api/users/:id` - Lấy user theo ID
- `PUT /api/users/:id` - Cập nhật user
- `GET /api/users/role/:role` - User theo role
- `GET /api/users/email/:email` - User theo email

#### Products
- `GET /api/products` - Lấy danh sách sản phẩm
- `GET /api/products/search` - Tìm kiếm sản phẩm
- `GET /api/products/featured` - Sản phẩm nổi bật
- `GET /api/products/category/:categoryId` - Sản phẩm theo danh mục
- `POST /api/products` - Tạo sản phẩm mới
- `PATCH /api/products/:id/stock` - Cập nhật tồn kho

#### Services
- `GET /api/services` - Lấy danh sách dịch vụ
- `GET /api/services/search` - Tìm kiếm dịch vụ
- `GET /api/services/featured` - Dịch vụ nổi bật
- `GET /api/services/category/:categoryId` - Dịch vụ theo danh mục
- `POST /api/services` - Tạo dịch vụ mới

#### Vouchers
- `GET /api/vouchers/active` - Voucher đang hoạt động
- `POST /api/vouchers/validate` - Validate mã voucher
- `POST /api/vouchers/apply` - Áp dụng voucher
- `GET /api/vouchers/new-user` - Voucher cho user mới

### Query Parameters

#### Pagination
```
?page=1&limit=10
```

#### Search
```
?search=keyword
```

#### Sorting
```
?sort=name,-createdAt
```

#### Filtering
```
?minPrice=10000&maxPrice=50000&category=categoryId
```

## 🔧 Cấu trúc dự án

```
grooming-backend/
├── config/
│   └── database.js          # Cấu hình database
├── controllers/
│   ├── baseController.js    # Base CRUD controller
│   ├── bookingController.js
│   ├── userController.js
│   └── ...                  # Các controller khác
├── middleware/
│   ├── errorHandler.js      # Error handling
│   ├── asyncHandler.js      # Async wrapper
│   └── validation.js        # Validation middleware
├── models/
│   ├── Booking.js
│   ├── User.js
│   └── ...                  # Các model khác
├── routes/
│   ├── bookings.js
│   ├── users.js
│   └── ...                  # Các route khác
├── scripts/
│   └── seedData.js          # Script seed dữ liệu
├── server.js                # Entry point
├── package.json
└── README.md
```

## 🧪 Testing

Bạn có thể test API bằng:

1. **Postman/Insomnia**: Import các endpoint từ documentation
2. **curl**: 
```bash
# Health check
curl http://localhost:5000/api/health

# Get all bookings
curl http://localhost:5000/api/bookings

# Create booking
curl -X POST http://localhost:5000/api/bookings \
  -H "Content-Type: application/json" \
  -d '{"customerName":"Test User","customerPhone":"0123456789",...}'
```

## 🔒 Security Features

- **Helmet.js**: Security headers
- **Rate Limiting**: Giới hạn request
- **CORS**: Cross-origin resource sharing
- **Input Validation**: Validate dữ liệu đầu vào
- **Error Handling**: Không expose sensitive information

## 📊 Monitoring

- **Morgan Logging**: HTTP request logging
- **Error Tracking**: Centralized error handling
- **Health Check**: `/api/health` endpoint

## 🚀 Deployment

### Environment Variables
Đảm bảo set các biến môi trường sau khi deploy:

```env
NODE_ENV=production
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/grooming_db
PORT=5000
JWT_SECRET=your_production_jwt_secret
CORS_ORIGIN=https://yourdomain.com
```

### PM2 (Recommended)
```bash
npm install -g pm2
pm2 start server.js --name "grooming-api"
pm2 startup
pm2 save
```

## 📝 Notes

- Tất cả API responses đều có format chuẩn với `success`, `data`, `error`
- Pagination được implement cho tất cả list endpoints
- Search và filter được hỗ trợ cho các collection chính
- Database indexes được tối ưu cho performance
- Validation được implement ở cả model và route level

## 🤝 Contributing

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📄 License

MIT License