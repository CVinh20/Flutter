# Hướng dẫn Sửa Lỗi Firebase Storage Upload

## Vấn đề
Lỗi "StorageException: object-not-found" khi upload ảnh lên Firebase Storage

## Nguyên nhân
1. Firebase Storage bucket chưa được khởi tạo
2. Storage rules chưa được cấu hình
3. Quyền truy cập không đủ

## Giải pháp

### Bước 1: Khởi tạo Firebase Storage (Trên Firebase Console)

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Chọn project của bạn: **doanmobile-6c221**
3. Vào menu **Build > Storage**
4. Nhấn **Get Started**
5. Chọn location gần nhất (ví dụ: asia-southeast1)
6. Nhấn **Done**

### Bước 2: Deploy Storage Rules

#### Cách 1: Sử dụng file bat
```bash
# Chạy file bat
deploy-storage-rules.bat
```

#### Cách 2: Command line
```bash
# Deploy storage rules
firebase deploy --only storage
```

#### Cách 3: Thủ công trên Firebase Console
1. Vào **Storage > Rules** tab
2. Copy nội dung từ file `storage.rules`
3. Paste vào editor
4. Nhấn **Publish**

### Bước 3: Verify Storage Rules

Rules mới đã được cấu hình:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to read all files
    match /{allPaths=**} {
      allow read: if request.auth != null;
    }
    
    // Allow authenticated users to upload stylists images
    match /stylists/{imageId} {
      allow write: if request.auth != null 
                   && request.resource.size < 5 * 1024 * 1024 // Max 5MB
                   && request.resource.contentType.matches('image/.*');
    }
    
    // Allow authenticated users to upload employee images
    match /employees/{imageId} {
      allow write: if request.auth != null
                   && request.resource.size < 5 * 1024 * 1024 // Max 5MB
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

### Bước 4: Kiểm tra Code đã được cập nhật

Code upload mới đã được cải thiện với:
- ✅ Kiểm tra file tồn tại
- ✅ Metadata cho file
- ✅ Error handling tốt hơn
- ✅ Loading indicator
- ✅ User-friendly error messages

### Bước 5: Test

1. Đăng nhập vào app với tài khoản admin
2. Vào **Quản lý Stylist**
3. Chọn "Chọn ảnh từ thư viện"
4. Chọn một ảnh từ gallery
5. Nhấn "Thêm mới"
6. Kiểm tra ảnh được upload thành công

## Checklist Troubleshooting

- [ ] Firebase Storage đã được khởi tạo trên Console?
- [ ] Storage rules đã được deploy?
- [ ] Đã đăng nhập với tài khoản có quyền?
- [ ] Ảnh có kích thước < 5MB?
- [ ] Ảnh có định dạng hợp lệ (jpg, png, etc.)?
- [ ] Internet connection ổn định?

## Lỗi thường gặp

### 1. "object-not-found" (404)
**Nguyên nhân**: Storage bucket chưa được khởi tạo  
**Giải pháp**: Làm theo Bước 1

### 2. "unauthorized" (401)
**Nguyên nhân**: Storage rules không cho phép upload  
**Giải pháp**: Làm theo Bước 2

### 3. "quota-exceeded"
**Nguyên nhân**: Đã hết quota miễn phí  
**Giải pháp**: Upgrade plan hoặc xóa ảnh cũ

### 4. "invalid-argument"
**Nguyên nhân**: File không hợp lệ  
**Giải pháp**: Kiểm tra định dạng và kích thước file

## Kiểm tra Storage trên Console

1. Vào **Storage** trên Firebase Console
2. Kiểm tra folder `stylists/`
3. Verify ảnh đã được upload
4. Kiểm tra URL có thể truy cập được

## Code Changes

### Files đã thay đổi:
- ✅ `lib/screens/admin/manage_stylists_screen.dart` - Cải thiện upload logic
- ✅ `storage.rules` - Storage security rules
- ✅ `firebase.json` - Thêm storage config
- ✅ `deploy-storage-rules.bat` - Script deploy rules

### Cải tiến:
1. **Better Error Handling**: Hiển thị lỗi chi tiết cho user
2. **Validation**: Kiểm tra file trước khi upload
3. **Metadata**: Thêm thông tin cho file upload
4. **Loading State**: EasyLoading cho UX tốt hơn
5. **Security**: Rules giới hạn kích thước và loại file

## Next Steps

Sau khi Storage hoạt động:
- [ ] Test upload nhiều ảnh
- [ ] Test edit stylist với ảnh mới
- [ ] Test trên nhiều devices
- [ ] Thêm function xóa ảnh cũ khi update
- [ ] Thêm image compression trước khi upload

---

**Cập nhật**: 11/11/2025  
**Status**: Ready for testing
