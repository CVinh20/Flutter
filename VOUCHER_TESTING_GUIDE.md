# Voucher System Testing Guide

## Prerequisites
Ensure you have:
- Firebase project configured
- Flutter app running
- Admin account

## Test Steps

### 1. Admin - Create Voucher
1. Login as admin
2. Go to Admin Dashboard
3. Click "Quản lý voucher"
4. Click "+" button to create new voucher
5. Fill in:
   - **Mã voucher**: SUMMER2024
   - **Tên voucher**: Giảm giá mùa hè
   - **Mô tả**: Giảm 20% tối đa 50k
   - **Phần trăm giảm**: 20
   - **Giảm tối đa**: 50000
   - **Đơn tối thiểu**: 200000
   - **Số lượng**: 100
   - **Ngày bắt đầu**: Today
   - **Ngày kết thúc**: +30 days
6. Click "Lưu"
7. Verify voucher appears in list with "Đang hoạt động" status

### 2. User - View Vouchers on Home Screen
1. Logout and login as regular user
2. Go to Home Screen
3. Scroll down to "Voucher Ưu Đãi" section
4. Verify voucher card displays:
   - Voucher name
   - Discount percentage
   - Code
   - Expiry date
   - Remaining quantity
5. Click on voucher code to copy
6. Verify "Đã sao chép!" toast appears

### 3. User - Apply Voucher in Booking
1. From Home Screen, select a service (price >= 200,000đ)
2. On Booking Screen, scroll to "Mã giảm giá" section
3. Paste or type voucher code: SUMMER2024
4. Click "Áp dụng"
5. Verify:
   - Success message appears: "Áp dụng voucher thành công! Giảm XXXđ"
   - Voucher info displays with green checkmark
   - Price summary shows:
     - Giá gốc: (original price)
     - Giảm giá: -(discount amount)
     - Tổng thanh toán: (final amount)
6. Complete booking by filling:
   - Customer name, phone
   - Branch
   - Stylist
   - Date & time
7. Click "Xác nhận đặt lịch"
8. Verify booking created successfully

### 4. Verify Voucher Usage Updated
1. Go back to Admin Dashboard → Quản lý voucher
2. Find SUMMER2024 voucher
3. Verify:
   - "Đã dùng" count increased by 1
   - Remaining quantity decreased by 1

### 5. User - Try to Use Same Voucher Again
1. Create another booking with same user account
2. Try to apply same voucher code
3. Verify error message (user already used this voucher)

### 6. Test Voucher Validations

#### 6.1 Expired Voucher
1. Admin: Edit voucher, set validTo to yesterday
2. User: Try to apply voucher
3. Verify error: "Mã voucher đã hết hạn hoặc không khả dụng"

#### 6.2 Inactive Voucher
1. Admin: Toggle voucher to inactive (gray switch)
2. User: Try to apply voucher
3. Verify error: "Mã voucher đã hết hạn hoặc không khả dụng"

#### 6.3 Invalid Code
1. User: Enter random code: "INVALID123"
2. Click "Áp dụng"
3. Verify error: "Mã voucher không tồn tại"

#### 6.4 Minimum Order Not Met
1. Admin: Create voucher with minOrderValue = 500,000đ
2. User: Select service with price < 500,000đ
3. Try to apply voucher
4. Verify error: "Đơn hàng tối thiểu 500000đ"

#### 6.5 Out of Quantity
1. Admin: Create voucher with quantity = 1
2. User 1: Apply and complete booking
3. User 2: Try to apply same voucher
4. Verify error: Voucher shows "Hết lượt" status

### 7. Test Quick Booking Screen
1. Go to Quick Booking tab
2. Select service
3. Enter voucher code in "Mã giảm giá" section
4. Click "Áp dụng"
5. Verify same behavior as Booking Screen
6. Complete booking
7. Verify voucher applied correctly

### 8. Admin - Edit Voucher
1. Admin Dashboard → Quản lý voucher
2. Click edit icon on a voucher
3. Modify:
   - Name, description
   - Discount percent or max discount
   - Dates
4. Click "Cập nhật"
5. Verify changes saved

### 9. Admin - Delete Voucher
1. Click delete icon on a voucher
2. Confirm deletion
3. Verify voucher removed from list

### 10. Edge Cases

#### 10.1 Remove Applied Voucher
1. User: Apply voucher in booking
2. Click X button to remove voucher
3. Verify:
   - Voucher code cleared
   - Price summary shows original price
   - Can apply again

#### 10.2 Change Service After Applying Voucher
1. Apply voucher to service A (price = 300k)
2. Change to service B (price = 100k, below minOrderValue)
3. Verify discount calculation updates or shows error

#### 10.3 Multiple Users Same Time
1. User A: Apply voucher (quantity = 1)
2. User B: Apply same voucher simultaneously
3. One should succeed, other should fail

## Expected Results

### Successful Voucher Application
- ✅ Green success message
- ✅ Voucher info displayed with checkmark
- ✅ Correct discount calculation
- ✅ Final amount = originalAmount - discount
- ✅ Booking saved with voucherCode, discount, originalAmount
- ✅ Voucher usedCount incremented
- ✅ User added to usedBy array

### Failed Voucher Application
- ❌ Red error message displayed
- ❌ No discount applied
- ❌ Original price remains
- ❌ Voucher usage not incremented

## Database Verification

Check Firestore Console:

### Vouchers Collection
```
vouchers/
  {voucherId}/
    - code: "SUMMER2024"
    - usedCount: 1
    - usedBy: ["userId1"]
```

### Bookings Collection
```
bookings/
  {bookingId}/
    - amount: 240000 (after discount)
    - originalAmount: 300000
    - discount: 60000
    - voucherCode: "SUMMER2024"
```

## Performance Checks
- [ ] Voucher list loads quickly
- [ ] Voucher validation is instant
- [ ] Booking creation with voucher < 3 seconds
- [ ] No UI freezing during operations

## Common Issues & Solutions

### Issue: Voucher not showing on home screen
**Solution:** Check voucher is active and validTo >= now

### Issue: "Mã voucher không tồn tại" for valid code
**Solution:** Check code is exact match (case-sensitive), no spaces

### Issue: Discount calculation wrong
**Solution:** Verify formula: min(price * percent / 100, maxDiscount)

### Issue: Same user can use voucher multiple times
**Solution:** Check applyVoucher() is called after booking creation

### Issue: Voucher count not updating
**Solution:** Verify Firestore rules allow write to vouchers collection

## Cleanup After Testing
1. Delete test vouchers
2. Delete test bookings
3. Reset test user data if needed
