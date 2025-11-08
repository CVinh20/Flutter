# Hướng Dẫn Sửa Lỗi Permission Denied cho Voucher

## Vấn đề
Lỗi: `[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation`

Lỗi này xảy ra vì Firestore Rules chưa có quy tắc cho collection `vouchers`.

## Giải pháp

### Cách 1: Deploy Firestore Rules từ Terminal

1. Mở Terminal/PowerShell
2. Di chuyển đến thư mục project:
   ```
   cd c:\Mobile\map\NguyenAnhKhoi
   ```

3. Deploy Firestore rules:
   ```
   firebase deploy --only firestore:rules
   ```

4. Đợi deployment hoàn tất (khoảng 30 giây)

### Cách 2: Cập nhật trực tiếp trên Firebase Console (KHUYẾN NGHỊ)

1. Mở Firebase Console: https://console.firebase.google.com/
2. Chọn project của bạn
3. Vào **Firestore Database** → **Rules** (tab ở trên)
4. Thêm rules sau vào phần rules (sau phần categories):

```javascript
// Rules cho collection vouchers
match /vouchers/{voucherId} {
  allow read: if true;  // Cho phép đọc công khai
  allow write: if isAdmin();  // Chỉ admin mới có thể tạo/sửa/xóa voucher
}
```

5. Click **Publish** để áp dụng rules mới

### Cách 3: Copy toàn bộ Firestore Rules

Nếu cách 1 và 2 không hoạt động, copy toàn bộ rules sau vào Firebase Console:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Kiểm tra xem user đã đăng nhập chưa
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Kiểm tra xem user có phải là admin không
    function isAdmin() {
      return isAuthenticated() && 
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Kiểm tra xem user có phải là chủ của payment không
    function isPaymentOwner(paymentData) {
      return isAuthenticated() && paymentData.userId == request.auth.uid;
    }
    
    // Rules cho collection users
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isAuthenticated() && (request.auth.uid == userId || isAdmin());
      allow delete: if isAdmin();
    }
    
    // Rules cho collection bookings
    match /bookings/{bookingId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        resource.data.userId == request.auth.uid || isAdmin()
      );
      allow delete: if isAdmin();
    }
    
    // Rules cho collection services
    match /services/{serviceId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Rules cho collection branches
    match /branches/{branchId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Rules cho collection stylists
    match /stylists/{stylistId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Rules cho collection categories
    match /categories/{categoryId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // **THÊM MỚI** - Rules cho collection vouchers
    match /vouchers/{voucherId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Rules cho collection payments
    match /payments/{paymentId} {
      allow read: if isAuthenticated() && (
        resource.data.userId == request.auth.uid || isAdmin()
      );
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isAuthenticated() && (
        resource.data.userId == request.auth.uid || isAdmin()
      );
      allow delete: if isAdmin();
    }

    // Rules cho collection transactions
    match /transactions/{transactionId} {
      allow read: if isAuthenticated() && (
        resource.data.userId == request.auth.uid || isAdmin()
      );
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isAuthenticated() && (
        resource.data.userId == request.auth.uid || isAdmin()
      );
      allow delete: if isAdmin();
    }

    // Rules cho collection paymentMethods
    match /paymentMethods/{methodId} {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
}
```

## Kiểm tra sau khi cập nhật

1. Đăng nhập vào app với tài khoản admin
2. Vào Admin Dashboard → Quản lý Voucher
3. Thử tạo voucher mới
4. Nếu vẫn lỗi, kiểm tra:
   - Tài khoản đăng nhập có `isAdmin: true` trong Firestore không?
   - Rules đã được publish chưa?
   - Có lỗi nào trong Firebase Console không?

## Kiểm tra quyền Admin

1. Mở Firebase Console
2. Vào Firestore Database
3. Mở collection `users`
4. Tìm document của user đang đăng nhập
5. Kiểm tra field `isAdmin` phải là `true`
6. Nếu chưa có hoặc `false`, sửa thành `true`

## Lưu ý quan trọng

- Sau khi cập nhật rules, đợi 30-60 giây để rules được áp dụng
- Nếu đang test trên emulator, restart emulator
- Clear cache của app nếu cần
- Đăng xuất và đăng nhập lại

## Nếu vẫn lỗi

Kiểm tra console trong app (Run với `flutter run -v`) để xem chi tiết lỗi:
```
flutter run -v
```

Hoặc xem logs trong Firebase Console:
- Firebase Console → Firestore Database → Rules → View logs
