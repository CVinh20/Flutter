# Hướng dẫn khắc phục lỗi Permission cho Stylist

## Vấn đề
Stylist không thể cập nhật trạng thái dịch vụ và ghi chú do lỗi permission.

## Đã thực hiện
1. ✅ Đã cập nhật Firestore rules để cho phép stylist update bookings
2. ✅ Đã deploy Firestore rules lên Firebase
3. ✅ Đã cải thiện error handling trong code

## Kiểm tra và khắc phục

### Bước 1: Kiểm tra User có stylistId
1. Vào Firebase Console → Firestore Database
2. Mở collection `users`
3. Tìm user của stylist (theo email hoặc UID)
4. Kiểm tra xem có field `stylistId` không
5. Nếu chưa có, thêm field `stylistId` với giá trị là ID của stylist trong collection `stylists`

### Bước 2: Kiểm tra Booking có stylistId
1. Vào collection `bookings`
2. Tìm booking cần kiểm tra
3. Kiểm tra xem có field `stylistId` không
4. Đảm bảo `stylistId` trong booking khớp với `stylistId` trong user document

### Bước 3: Đảm bảo Firestore Rules đã được deploy
Firestore rules đã được deploy, nhưng nếu vẫn gặp lỗi:
1. Chạy lại: `firebase deploy --only firestore:rules`
2. Đợi vài phút để rules được áp dụng
3. Refresh lại ứng dụng

### Bước 4: Kiểm tra lại
1. Đăng xuất và đăng nhập lại bằng tài khoản stylist
2. Thử cập nhật trạng thái dịch vụ
3. Thử lưu ghi chú

## Format số tiền
- Số tiền sẽ hiển thị đúng định dạng: `50.000đ` thay vì `500.000 ₫`
- Format: Số với dấu chấm phân cách hàng nghìn + đơn vị "đ"

## Lưu ý
- Firestore rules có thể cần vài phút để áp dụng sau khi deploy
- Đảm bảo user document có field `stylistId` được set đúng
- Đảm bảo booking document có field `stylistId` khớp với user

