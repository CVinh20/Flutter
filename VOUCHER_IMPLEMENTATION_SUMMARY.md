# Voucher System Implementation Summary

## Overview
Complete voucher system has been implemented with admin management and user application during booking.

## Features Implemented

### 1. Voucher Model (`lib/models/voucher.dart`)
- **Fields:**
  - `id`, `code`, `name`, `description`
  - `discountPercent` - Phần trăm giảm giá
  - `maxDiscount` - Số tiền giảm tối đa
  - `minOrderValue` - Giá trị đơn hàng tối thiểu
  - `validFrom`, `validTo` - Thời gian hiệu lực
  - `quantity`, `usedCount` - Số lượng và đã sử dụng
  - `isActive` - Trạng thái kích hoạt
  - `usedBy` - Danh sách user đã sử dụng

- **Methods:**
  - `isValid` - Kiểm tra voucher còn hiệu lực
  - `remainingQuantity` - Số lượng còn lại
  - `calculateDiscount(orderValue)` - Tính số tiền giảm

### 2. Booking Model Updates (`lib/models/booking.dart`)
- **New Fields:**
  - `voucherCode` (String?) - Mã voucher đã áp dụng
  - `discount` (double?) - Số tiền giảm giá từ voucher
  - `originalAmount` (double?) - Số tiền gốc trước khi giảm

### 3. Firestore Service (`lib/services/firestore_service.dart`)
- **New Methods:**
  - `getVouchers()` - Lấy tất cả voucher
  - `getActiveVouchers()` - Lấy voucher đang hoạt động
  - `getVoucherByCode(code)` - Tìm voucher theo mã
  - `addVoucher(voucher)` - Thêm voucher mới
  - `updateVoucher(voucher)` - Cập nhật voucher
  - `deleteVoucher(id)` - Xóa voucher
  - `applyVoucher(voucherId, userId)` - Áp dụng voucher (tăng usedCount, thêm vào usedBy)

### 4. Admin Management (`lib/screens/admin/manage_vouchers_screen.dart`)
- **Features:**
  - Danh sách tất cả voucher
  - Tạo voucher mới với form đầy đủ
  - Chỉnh sửa voucher hiện có
  - Bật/tắt voucher
  - Xóa voucher
  - Hiển thị trạng thái (Đang hoạt động, Sắp hết hạn, Hết hạn, Hết lượt)
  - Date picker cho validFrom và validTo

- **UI Elements:**
  - Gradient cards cho mỗi voucher
  - Status chips với màu sắc phân biệt
  - Icons cho các hành động (edit, delete, toggle)
  - Dialogs cho add/edit với validation

### 5. Home Screen Integration (`lib/screens/home_screen.dart`)
- **VoucherSection Widget:**
  - Horizontal scrolling voucher cards
  - Gradient backgrounds (pink/yellow)
  - Copy code to clipboard
  - Show expiry date and remaining quantity
  - "Xem tất cả" button to show all vouchers

### 6. Booking Screen Integration (`lib/screens/booking_screen.dart`)
- **Voucher Application:**
  - Input field để nhập mã voucher
  - Nút "Áp dụng" để validate và apply voucher
  - Hiển thị thông báo lỗi nếu voucher không hợp lệ
  - Hiển thị thông tin voucher đã áp dụng
  - Nút xóa voucher đã áp dụng
  
- **Price Summary:**
  - Giá gốc
  - Giảm giá (nếu có voucher)
  - Tổng thanh toán

- **Booking Creation:**
  - Lưu voucherCode, discount, originalAmount vào booking
  - Gọi `applyVoucher()` để tăng usedCount khi booking thành công

### 7. Quick Booking Screen Integration (`lib/screens/quick_booking_screen.dart`)
- Same features as Booking Screen
- Integrated into multi-step booking flow
- Price summary updated in real-time

## Validation Logic

### Voucher Validation
1. **Code exists:** Kiểm tra voucher có tồn tại
2. **Is active:** Voucher phải được kích hoạt
3. **Not expired:** Kiểm tra validTo >= hiện tại
4. **Not started yet:** Kiểm tra validFrom <= hiện tại
5. **Has quantity:** remainingQuantity > 0
6. **Min order value:** orderValue >= minOrderValue
7. **User not used:** userId không có trong usedBy (mỗi user chỉ dùng 1 lần)

### Discount Calculation
```dart
discount = min(orderValue * discountPercent / 100, maxDiscount)
finalAmount = orderValue - discount
```

## User Flow

### Admin Flow:
1. Admin → Dashboard → "Quản lý voucher"
2. Xem danh sách voucher hiện có
3. Nhấn "+" để tạo voucher mới
4. Điền thông tin: code, tên, mô tả, %, max discount, min order, số lượng, thời gian
5. Lưu voucher
6. Có thể edit, toggle active/inactive, hoặc delete voucher

### User Flow:
1. User mở Home Screen
2. Xem voucher section, copy mã voucher
3. Vào Booking Screen hoặc Quick Booking
4. Chọn dịch vụ
5. Nhập mã voucher vào ô "Mã giảm giá"
6. Nhấn "Áp dụng"
7. Hệ thống validate và hiển thị giảm giá
8. Xem tổng thanh toán đã giảm
9. Hoàn tất booking
10. Voucher usedCount tăng lên, userId được thêm vào usedBy

## Files Modified/Created

### Created:
- `lib/models/voucher.dart`
- `lib/screens/admin/manage_vouchers_screen.dart`
- `lib/widgets/voucher_section.dart`

### Modified:
- `lib/models/booking.dart` - Added voucher fields
- `lib/services/firestore_service.dart` - Added voucher methods
- `lib/screens/admin/admin_dashboard.dart` - Added voucher menu item
- `lib/screens/home_screen.dart` - Added voucher section
- `lib/screens/booking_screen.dart` - Added voucher application
- `lib/screens/quick_booking_screen.dart` - Added voucher application

## Firebase Firestore Structure

### Collection: `vouchers`
```json
{
  "id": "auto-generated",
  "code": "SUMMER2024",
  "name": "Giảm giá mùa hè",
  "description": "Giảm 20% tối đa 50k cho đơn từ 200k",
  "discountPercent": 20,
  "maxDiscount": 50000,
  "minOrderValue": 200000,
  "validFrom": Timestamp,
  "validTo": Timestamp,
  "quantity": 100,
  "usedCount": 15,
  "isActive": true,
  "usedBy": ["userId1", "userId2"]
}
```

### Collection: `bookings` (updated)
```json
{
  "id": "auto-generated",
  "serviceId": "...",
  "stylistId": "...",
  "dateTime": Timestamp,
  "status": "Chờ xác nhận",
  "customerName": "...",
  "customerPhone": "...",
  "branchName": "...",
  "paymentMethod": "...",
  "amount": 160000,          // Final amount after discount
  "originalAmount": 200000,  // Original price
  "discount": 40000,         // Discount amount
  "voucherCode": "SUMMER2024",
  "isPaid": false
}
```

## Testing Checklist

### Admin:
- [x] Create voucher with all fields
- [x] Edit existing voucher
- [x] Toggle voucher active/inactive
- [x] Delete voucher
- [x] View voucher list with correct status

### User:
- [x] See vouchers on home screen
- [x] Copy voucher code
- [x] Apply valid voucher in booking screen
- [x] See error for invalid voucher
- [x] See error for expired voucher
- [x] See error for min order not met
- [x] See correct discount calculation
- [x] Remove applied voucher
- [x] Complete booking with voucher
- [x] Verify voucher usedCount increased

### Edge Cases:
- [ ] Voucher already used by user
- [ ] Voucher out of quantity
- [ ] Multiple users using same voucher simultaneously
- [ ] Applying voucher then changing service
- [ ] Booking cancellation with voucher (revert usage?)

## Future Enhancements
1. Voucher usage history
2. Personal vouchers (specific to user)
3. Category-specific vouchers
4. First-time user vouchers
5. Referral vouchers
6. Voucher stacking (multiple vouchers)
7. Auto-apply best voucher
8. Voucher notifications
9. Revert voucher usage on booking cancellation
10. Analytics dashboard for voucher performance
