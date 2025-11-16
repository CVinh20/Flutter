# Fix Lỗi Permission và Layout cho Voucher

## 📋 Vấn đề đã gặp

### 1. Lỗi Permission Denied khi lưu voucher
```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

**Nguyên nhân:** Firestore rules chưa có quy tắc cho subcollection `users/{userId}/savedVouchers`

### 2. Lỗi Layout trong SavedVouchersScreen
```
RenderBox was not laid out: RenderFlex
Null check operator used on a null value
```

**Nguyên nhân:** VoucherCard với `isExpanded: true` không xử lý layout đúng cách (thiếu constraints)

---

## ✅ Giải pháp đã áp dụng

### 1. Cập nhật Firestore Rules

**File:** `firestore.rules`

Thêm rules cho subcollection `savedVouchers`:

```javascript
// Rules cho collection users
match /users/{userId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated() && (
    request.auth.uid == userId || 
    isAdmin()
  );
  allow update: if isAuthenticated() && (
    request.auth.uid == userId || 
    isAdmin()
  );
  allow delete: if isAdmin();
  
  // Rules cho subcollection savedVouchers
  match /savedVouchers/{voucherId} {
    // User chỉ có thể đọc/ghi voucher đã lưu của chính mình
    allow read: if isAuthenticated() && request.auth.uid == userId;
    allow create: if isAuthenticated() && request.auth.uid == userId;
    allow update: if isAuthenticated() && request.auth.uid == userId;
    allow delete: if isAuthenticated() && request.auth.uid == userId;
  }
}
```

**Quyền hạn:**
- ✅ User chỉ có thể đọc/ghi voucher của chính mình
- ✅ Không thể truy cập voucher của user khác
- ✅ Phải đăng nhập mới thực hiện được các thao tác

**Deploy rules:**
```bash
firebase deploy --only firestore:rules
# hoặc
.\deploy-firestore-rules.bat
```

### 2. Fix Layout VoucherCard

**File:** `lib/widgets/voucher_section.dart`

**Thay đổi:**

1. **Thêm constraints cho expanded mode:**
```dart
Container(
  width: widget.isExpanded ? double.infinity : 320,
  constraints: widget.isExpanded 
      ? const BoxConstraints(minHeight: 180)
      : null,
  height: widget.isExpanded ? null : 180,
  ...
)
```

2. **Thay đổi Column layout:**
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,  // ← THÊM dòng này
  children: [
    // ... content ...
    
    // Conditional Spacer
    if (!widget.isExpanded) const Spacer(),
    if (widget.isExpanded) const SizedBox(height: 12),
    
    // ... bottom section ...
  ],
)
```

3. **Thêm mainAxisSize cho nested Column:**
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,  // ← THÊM dòng này
  children: [
    // Discount badge, code, info...
  ],
)
```

**Giải thích:**
- `mainAxisSize: MainAxisSize.min` → Column chỉ chiếm không gian tối thiểu cần thiết
- `constraints: BoxConstraints(minHeight: 180)` → Đảm bảo chiều cao tối thiểu khi expanded
- `if (!widget.isExpanded) const Spacer()` → Chỉ dùng Spacer khi không expanded
- `if (widget.isExpanded) const SizedBox(height: 12)` → Dùng spacing cố định khi expanded

---

## 🧪 Kiểm tra sau khi fix

### Test Permission:
1. ✅ User có thể lưu voucher từ home screen
2. ✅ User có thể xem danh sách voucher đã lưu
3. ✅ User có thể bỏ lưu voucher
4. ✅ Không có lỗi permission denied

### Test Layout:
1. ✅ VoucherCard hiển thị đúng ở home screen (không expanded)
2. ✅ VoucherCard hiển thị đúng ở saved vouchers screen (expanded)
3. ✅ Không có lỗi RenderBox
4. ✅ Scroll mượt mà trong ListView

### Test chức năng:
```
[Home Screen] → Tap bookmark icon → Toast "Đã lưu voucher!"
[Account Screen] → Tap "Voucher đã lưu" → Hiển thị danh sách
[Saved Vouchers] → Tap bookmark icon → Toast "Đã bỏ lưu voucher" → Card biến mất
```

---

## 📝 Lưu ý quan trọng

### 1. Firestore Rules Security
- Rules đã được cấu hình để chỉ user chủ sở hữu mới có thể truy cập `savedVouchers`
- Mỗi khi thay đổi rules, phải deploy lại: `firebase deploy --only firestore:rules`

### 2. Layout Best Practices
- Luôn sử dụng `mainAxisSize: MainAxisSize.min` cho Column không có chiều cao cố định
- Tránh dùng `Spacer()` trong Column có `mainAxisSize.min`
- Dùng `constraints` thay vì `height: null` cho Container flexible

### 3. Data Structure
```
users/
  {userId}/
    savedVouchers/
      {voucherId}/
        - voucherId: string
        - savedAt: Timestamp
```

---

## 🔍 Debug Commands

Nếu vẫn gặp lỗi permission:

```bash
# Kiểm tra rules đã deploy chưa
firebase firestore:rules:get

# Xem logs realtime
firebase emulators:start --only firestore

# Test rules locally
firebase emulators:exec --only firestore "flutter test"
```

Nếu vẫn gặp lỗi layout:

```dart
// Thêm debug info vào VoucherCard
print('isExpanded: ${widget.isExpanded}');
print('width: ${MediaQuery.of(context).size.width}');
```

---

## ✨ Kết quả

Sau khi fix:
- ✅ User có thể lưu và xem voucher không có lỗi
- ✅ Layout hiển thị đúng ở cả 2 màn hình
- ✅ Performance tốt, không có warning
- ✅ UI/UX mượt mà và trực quan

---

**Ngày fix:** 11/11/2025  
**Files đã sửa:**
- `firestore.rules`
- `lib/widgets/voucher_section.dart`
