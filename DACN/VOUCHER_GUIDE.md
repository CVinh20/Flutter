# Hướng dẫn sử dụng Voucher System

## 🎯 Tính năng đã hoàn thành

### 1. Hiển thị Voucher trên Home Screen
- ✅ Section "Ưu đãi đặc biệt" hiển thị voucher đang hoạt động
- ✅ Hiển thị tối đa 5 voucher trên carousel
- ✅ Nút "Xem tất cả" để xem toàn bộ voucher
- ✅ Loading state khi đang tải dữ liệu
- ✅ Empty state đẹp mắt khi chưa có voucher

### 2. Lưu Voucher
- ✅ Nút bookmark trên mỗi voucher card
- ✅ Icon bookmark đầy khi đã lưu, rỗng khi chưa lưu
- ✅ Toast notification khi lưu/bỏ lưu thành công

### 3. Truy cập Voucher đã lưu
- ✅ **Cách 1**: Home Screen → Nút "Đã lưu" (top buttons - màu hồng)
- ✅ **Cách 2**: Account Screen → "Voucher đã lưu"

### 4. Màn hình Voucher đã lưu
- ✅ Hiển thị tất cả voucher đã lưu
- ✅ Tự động ẩn voucher hết hạn
- ✅ Có thể sao chép mã voucher
- ✅ Có thể bỏ lưu trực tiếp từ màn hình này

## 📝 Cách tạo Voucher mới (dành cho Admin)

### Bước 1: Đăng nhập Admin
1. Login với tài khoản admin: `admin@gmail.com` / `@123456`
2. Vào Admin Dashboard

### Bước 2: Tạo Voucher
1. Chọn "Quản lý Voucher"
2. Điền thông tin voucher:
   - **Code**: Mã voucher (VD: SUMMER2024, NEWYEAR50)
   - **Tên**: Tên hiển thị (VD: "Giảm 50% mừng năm mới")
   - **Mô tả**: Mô tả chi tiết
   - **Giảm giá**: % giảm (0-100)
   - **Giảm tối đa**: Số tiền giảm tối đa (tùy chọn)
   - **Giá trị đơn tối thiểu**: Giá trị đơn hàng tối thiểu để áp dụng
   - **Ngày bắt đầu**: Ngày có hiệu lực (phải <= ngày hiện tại để hiển thị)
   - **Ngày kết thúc**: Ngày hết hạn (phải > ngày hiện tại)
   - **Tổng số lượng**: Số lượng voucher có sẵn
   - **Trạng thái**: Bật/Tắt

### Bước 3: Kiểm tra
1. Đăng xuất admin
2. Đăng nhập user thường
3. Vào Home Screen → Xem section "Ưu đãi đặc biệt"
4. Nhấn bookmark để lưu voucher
5. Vào "Đã lưu" hoặc Account → "Voucher đã lưu"

## 🎨 Cấu trúc UI

```
Home Screen
├── Header (Search, Avatar, Notifications)
├── Top Buttons
│   ├── Ưu đãi
│   ├── Đã lưu ← Click để xem voucher đã lưu
│   ├── Cam kết
│   └── Chi nhánh
├── Ưu đãi đặc biệt (VoucherSection)
│   ├── Voucher 1 [🔖 Lưu]
│   ├── Voucher 2 [🔖 Lưu]
│   └── ... (tối đa 5)
└── Dịch vụ theo danh mục

Account Screen
├── Thông tin cá nhân
│   ├── Thông tin cá nhân
│   ├── Dịch vụ yêu thích
│   ├── Voucher đã lưu ← Click để xem voucher đã lưu
│   └── Lịch sử giao dịch
└── ...
```

## 🔧 Cấu trúc Database

### Collection: `vouchers`
```javascript
{
  code: "SUMMER2024",
  name: "Giảm 50% mùa hè",
  description: "Giảm giá 50% cho tất cả dịch vụ",
  discount: 50,
  maxDiscount: 100000,
  minOrderValue: 200000,
  validFrom: Timestamp,
  validTo: Timestamp,
  totalQuantity: 100,
  usedQuantity: 0,
  isActive: true,
  imageUrl: null,
  usedBy: []
}
```

### Collection: `users/{userId}/savedVouchers/{voucherId}`
```javascript
{
  voucherId: "voucher_id",
  savedAt: Timestamp
}
```

## ⚠️ Lưu ý quan trọng

### Voucher sẽ KHÔNG hiển thị nếu:
1. ❌ `isActive = false`
2. ❌ `validFrom > ngày hiện tại` (chưa đến ngày có hiệu lực)
3. ❌ `validTo < ngày hiện tại` (đã hết hạn)
4. ❌ `usedQuantity >= totalQuantity` (hết số lượng)

### Để voucher hiển thị ngay:
- ✅ `isActive = true`
- ✅ `validFrom <= ngày hiện tại`
- ✅ `validTo > ngày hiện tại`
- ✅ `usedQuantity < totalQuantity`

## 📱 Test Flow

### Test 1: Xem voucher
1. Mở app → Home Screen
2. Scroll xuống section "Ưu đãi đặc biệt"
3. Kiểm tra voucher có hiển thị đúng không

### Test 2: Lưu voucher
1. Nhấn icon bookmark trên voucher card
2. Kiểm tra icon chuyển từ rỗng sang đầy
3. Kiểm tra toast "Đã lưu voucher!"

### Test 3: Xem voucher đã lưu
1. **Cách 1**: Nhấn nút "Đã lưu" ở top buttons
2. **Cách 2**: Account → "Voucher đã lưu"
3. Kiểm tra voucher vừa lưu có trong danh sách

### Test 4: Bỏ lưu voucher
1. Vào "Voucher đã lưu"
2. Nhấn lại icon bookmark trên voucher
3. Kiểm tra voucher biến mất khỏi danh sách

### Test 5: Sao chép mã
1. Nhấn vào box chứa mã voucher (VD: SUMMER2024)
2. Kiểm tra toast "Đã sao chép mã: SUMMER2024"
3. Paste vào booking để kiểm tra

## 🐛 Troubleshooting

### Không thấy voucher trên Home Screen?
1. Kiểm tra có voucher trong database chưa
2. Kiểm tra `validFrom` và `validTo`
3. Kiểm tra `isActive = true`
4. Kiểm tra console có lỗi không

### Không lưu được voucher?
1. Kiểm tra đã đăng nhập chưa
2. Kiểm tra Firebase Auth rules
3. Kiểm tra Firestore rules cho collection `savedVouchers`

### Voucher đã lưu không hiển thị?
1. Voucher có thể đã hết hạn (tự động ẩn)
2. Kiểm tra Firestore rules
3. Xóa cache app và thử lại

## 📊 Firestore Rules đã cấu hình

```javascript
// users/{userId}/savedVouchers/{voucherId}
match /users/{userId}/savedVouchers/{voucherId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

## 🎉 Demo Voucher

Tạo voucher test với thông tin sau:
```
Code: WELCOME50
Tên: Giảm 50% cho khách hàng mới
Mô tả: Giảm 50% cho lần đặt lịch đầu tiên
Giảm giá: 50%
Giảm tối đa: 100,000đ
Đơn tối thiểu: 100,000đ
Ngày bắt đầu: 01/01/2025
Ngày kết thúc: 31/12/2025
Số lượng: 100
Trạng thái: Bật
```

---

**Tác giả**: GitHub Copilot
**Ngày cập nhật**: 11/11/2025
