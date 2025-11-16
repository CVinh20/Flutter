Để debug vấn đề voucher không hiển thị, hãy làm theo các bước sau:

## Bước 1: Chạy app và xem Console

```bash
# Terminal sẽ hiển thị:
=== FIRESTORE QUERY DEBUG ===
Querying active vouchers at: 2025-11-11 ...
Query returned X total documents
Document voucher_id_1:
  - isActive: true/false
  - validFrom: ...
  - validTo: ...
...
```

## Bước 2: Kiểm tra dữ liệu voucher trong Admin

Đảm bảo voucher có:
- ✅ `isActive: true`
- ✅ `validFrom`: <= ngày hiện tại
- ✅ `validTo`: > ngày hiện tại
- ✅ `totalQuantity`: > 0
- ✅ `usedQuantity`: < totalQuantity

## Bước 3: Kiểm tra Firestore Rules

Mở Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Vouchers - READ only (public)
    match /vouchers/{voucherId} {
      allow read: if true;  // Cho phép đọc public
      allow write: if request.auth != null && 
                   get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

## Bước 4: Nếu vẫn không thấy

Có thể do composite index chưa được tạo. Firestore sẽ báo lỗi trong console với link tạo index.

Hoặc thử query đơn giản hơn (đã cập nhật trong code - fetch tất cả và filter ở client).

## Bước 5: Test thủ công

1. Mở Firebase Console
2. Vào Firestore
3. Xem collection `vouchers`
4. Kiểm tra các field của 2 voucher bạn đã tạo
5. Screenshot và báo lại nếu cần
