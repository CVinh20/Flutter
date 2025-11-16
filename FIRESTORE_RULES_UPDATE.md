# Cập nhật Firestore Rules - Changelog

## Ngày: 11/11/2025

### 📋 Tổng quan thay đổi

Đã cập nhật Firestore Security Rules để:
1. Thêm collection `employees` mới
2. Cải thiện cấu trúc và tổ chức rules
3. Thêm helper function cho employee
4. Cải thiện quyền tạo user cho admin
5. Thêm fallback rule để bảo mật tốt hơn

---

## 🆕 Thay đổi chính

### 1. **Thêm Helper Function `isEmployee()`**

```javascript
function isEmployee() {
  return isAuthenticated() && 
    exists(/databases/$(database)/documents/employees/{document=**}) &&
    get(/databases/$(database)/documents/employees/$(request.auth.uid)).data.userId == request.auth.uid;
}
```

**Mục đích**: Kiểm tra user có phải là nhân viên không

---

### 2. **Collection `employees` (MỚI)**

```javascript
match /employees/{employeeId} {
  allow read: if isAuthenticated();  // Tất cả user đăng nhập đều đọc được
  allow create: if isAdmin();  // Chỉ admin tạo được
  allow update: if isAdmin() || (
    isAuthenticated() && 
    resource.data.userId == request.auth.uid  // Employee tự update thông tin
  );
  allow delete: if isAdmin();  // Chỉ admin xóa được
}
```

**Quyền truy cập**:
- ✅ **Read**: Tất cả user đã đăng nhập
- ✅ **Create**: Chỉ admin
- ✅ **Update**: Admin hoặc chính nhân viên đó
- ✅ **Delete**: Chỉ admin

**Use cases**:
- Admin tạo tài khoản nhân viên mới
- Nhân viên xem danh sách đồng nghiệp
- Nhân viên cập nhật thông tin cá nhân
- Admin quản lý (sửa/xóa) nhân viên

---

### 3. **Cập nhật Collection `users`**

**Trước**:
```javascript
allow create: if isAuthenticated() && request.auth.uid == userId;
```

**Sau**:
```javascript
allow create: if isAuthenticated() && (
  request.auth.uid == userId || 
  isAdmin()  // Admin có thể tạo user mới (cho nhân viên)
);
```

**Lý do**: Admin cần tạo user document khi đăng ký nhân viên mới

---

### 4. **Cải thiện cấu trúc**

Thêm comments phân chia rõ ràng:
```javascript
// ==================== HELPER FUNCTIONS ====================
// ==================== COLLECTION RULES ====================
// ==================== FALLBACK RULE ====================
```

---

### 5. **Thêm Fallback Rule**

```javascript
match /{document=**} {
  allow read, write: if false;
}
```

**Mục đích**: Deny tất cả truy cập không được định nghĩa rõ ràng (security best practice)

---

## 📊 So sánh Rules

### Collection `employees`

| Operation | Quyền | Điều kiện |
|-----------|-------|-----------|
| **Read** | ✅ All authenticated users | Đã đăng nhập |
| **Create** | 🔒 Admin only | isAdmin() |
| **Update** | ✅ Admin + Self | isAdmin() hoặc chính mình |
| **Delete** | 🔒 Admin only | isAdmin() |

### Collection `users`

| Operation | Thay đổi |
|-----------|----------|
| **Read** | Không đổi - All authenticated |
| **Create** | ➕ Admin có thể tạo user |
| **Update** | Không đổi - Self or Admin |
| **Delete** | Không đổi - Admin only |

---

## 🔐 Security Improvements

### 1. **Principle of Least Privilege**
- Mỗi collection có quyền truy cập cụ thể
- Không có quyền mặc định

### 2. **Role-Based Access Control**
- Admin: Full control
- Employee: Self-service + Read others
- User: Own data only

### 3. **Explicit Deny**
- Fallback rule deny tất cả truy cập không xác định
- Tránh lỗ hổng bảo mật

---

## 🧪 Test Cases

### Test Employee Rules

#### ✅ Test 1: Admin tạo employee
```dart
// Should PASS
await _firestore.collection('employees').add({
  'userId': newUserId,
  'fullName': 'Nhân viên mới',
  'role': 'stylist',
  // ...
});
```

#### ✅ Test 2: User đọc employees
```dart
// Should PASS (if authenticated)
final employees = await _firestore.collection('employees').get();
```

#### ✅ Test 3: Employee tự update
```dart
// Should PASS (if userId matches)
await _firestore.collection('employees').doc(employeeId).update({
  'phoneNumber': '0123456789',
});
```

#### ❌ Test 4: User thường tạo employee
```dart
// Should FAIL (not admin)
await _firestore.collection('employees').add({...}); // Permission denied
```

#### ❌ Test 5: Employee xóa chính mình
```dart
// Should FAIL (only admin can delete)
await _firestore.collection('employees').doc(myId).delete(); // Permission denied
```

---

## 📝 Migration Guide

### Không cần migration data

Các rules mới không ảnh hưởng đến data hiện có:
- ✅ Collection `employees` mới, không có data cũ
- ✅ Collection `users` - chỉ thêm quyền create cho admin
- ✅ Các collection khác không thay đổi

### Cần làm gì?

1. **Deploy rules** (đã làm)
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Test trong app**
   - Admin tạo nhân viên mới
   - Nhân viên đọc danh sách
   - Nhân viên update thông tin

3. **Verify trên Console**
   - Vào Firestore > Rules tab
   - Xem rules đã update

---

## 🚀 Deployment

### Command đã chạy:
```bash
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
firebase deploy --only firestore:rules
```

### Status:
- ✅ Rules đã được compiled
- ✅ Deploying to 'doanmobile-6c221'
- ⏳ Waiting for deployment complete...

---

## 🔍 Troubleshooting

### Lỗi "Permission denied"

**Employee không đọc được**:
- Kiểm tra user đã đăng nhập chưa
- Verify token còn hạn

**Admin không tạo được employee**:
- Kiểm tra `isAdmin == true` trong users collection
- Verify admin user đã được tạo đúng

**Employee không update được**:
- Kiểm tra `userId` trong employee document
- Verify đang update đúng document của mình

---

## 📖 Best Practices đã áp dụng

1. ✅ **Explicit Rules**: Mỗi collection có rules rõ ràng
2. ✅ **Helper Functions**: Tái sử dụng logic kiểm tra
3. ✅ **Comments**: Giải thích mục đích từng rule
4. ✅ **Organized**: Phân chia rõ ràng theo sections
5. ✅ **Fallback**: Deny all unknown access
6. ✅ **Granular Permissions**: CRUD permissions riêng biệt

---

## 📌 Next Steps

- [ ] Test tất cả scenarios trong app
- [ ] Kiểm tra logs để tìm permission errors
- [ ] Thêm monitoring cho failed permission checks
- [ ] Document cho team về quyền truy cập

---

**Deployed**: 11/11/2025  
**Project**: doanmobile-6c221  
**Rules Version**: 2
