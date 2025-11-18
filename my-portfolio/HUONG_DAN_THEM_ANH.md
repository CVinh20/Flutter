# 📸 Hướng Dẫn Thêm Ảnh vào Portfolio

## Cách 1: Sử dụng thư mục Public (Đơn giản nhất - Khuyên dùng)

### Bước 1: Đặt ảnh vào thư mục
- Copy ảnh của bạn (ví dụ: `profile.jpg`) vào thư mục `public/`
- Đảm bảo tên file đơn giản, không dấu: `profile.jpg`, `avatar.png`, v.v.

### Bước 2: Sửa file Hero.tsx
Mở file `src/components/Hero.tsx` và thay đổi:

```tsx
// TÌM dòng này (khoảng dòng 42-47):
<div className="profile-placeholder">
  {/* 
    Cách thêm ảnh:
    1. Đặt ảnh vào public/profile.jpg
    2. Bỏ comment dòng dưới và xóa span placeholder:
    <img src="/profile.jpg" alt="Profile" style={{width: '100%', height: '100%', objectFit: 'cover', borderRadius: '50%'}} />
  */}
  <span className="placeholder-text">Thêm Ảnh</span>
</div>

// ĐỔI THÀNH:
<div className="profile-placeholder">
  <img 
    src="/profile.jpg" 
    alt="Profile" 
    style={{
      width: '100%', 
      height: '100%', 
      objectFit: 'cover', 
      borderRadius: '50%'
    }} 
  />
</div>
```

---

## Cách 2: Sử dụng thư mục Assets (Cần import)

### Bước 1: Đặt ảnh vào thư mục
- Copy ảnh vào `src/assets/profile.jpg`

### Bước 2: Import và sử dụng trong Hero.tsx
```tsx
// Thêm import ở đầu file (dòng 1-2):
import { useState, useEffect } from 'react';
import profileImage from './assets/profile.jpg'; // THÊM DÒNG NÀY
import './Hero.css';

// Sau đó trong JSX, thay đổi:
<div className="profile-placeholder">
  <img 
    src={profileImage} 
    alt="Profile" 
    style={{
      width: '100%', 
      height: '100%', 
      objectFit: 'cover', 
      borderRadius: '50%'
    }} 
  />
</div>
```

---

## Cách 3: Sử dụng URL từ Internet

```tsx
<div className="profile-placeholder">
  <img 
    src="https://your-image-url.com/profile.jpg" 
    alt="Profile" 
    style={{
      width: '100%', 
      height: '100%', 
      objectFit: 'cover', 
      borderRadius: '50%'
    }} 
  />
</div>
```

---

## 💡 Lưu ý khi chọn ảnh:

✅ **Nên:**
- Ảnh chân dung, mặt rõ ràng
- Kích thước: tối thiểu 500x500px
- Định dạng: JPG, PNG, WebP
- Dung lượng: < 500KB (nén ảnh tại tinypng.com)
- Ảnh chuyên nghiệp, trang phục lịch sự

❌ **Không nên:**
- Ảnh mờ, tối, chất lượng kém
- Ảnh selfie góc kỳ lạ
- Ảnh có nhiều người
- Ảnh có nội dung không phù hợp

---

## 🎨 Tùy chỉnh thêm

Nếu muốn thêm hiệu ứng hover cho ảnh, sửa file `Hero.css`:

```css
.profile-placeholder img {
  transition: transform 0.3s ease;
}

.profile-placeholder:hover img {
  transform: scale(1.05);
}
```

---

## 🔧 Nếu gặp lỗi:

**Lỗi: Ảnh không hiển thị**
- Kiểm tra đường dẫn file
- Xóa cache trình duyệt (Ctrl + Shift + R)
- Kiểm tra console trong DevTools (F12)

**Lỗi: Ảnh bị méo**
- Đảm bảo thuộc tính `objectFit: 'cover'`
- Kiểm tra ảnh gốc có tỷ lệ vuông không

**Lỗi: Import không tìm thấy file**
- Kiểm tra đường dẫn relative path
- Đảm bảo tên file khớp (phân biệt hoa/thường)
