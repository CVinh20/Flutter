# Hệ thống Quản lý Nhân viên - Hướng dẫn

## Tổng quan

Hệ thống quản lý nhân viên mới đã được triển khai để thay thế/bổ sung cho quản lý stylist cũ. Hệ thống này cho phép admin đăng ký và quản lý tài khoản của tất cả nhân viên trong salon.

## Các tính năng chính

### 1. Đăng ký tài khoản nhân viên mới

Admin có thể tạo tài khoản mới cho nhân viên trực tiếp từ trang admin với các thông tin:
- **Họ và tên**: Tên đầy đủ của nhân viên
- **Email**: Địa chỉ email (sẽ dùng để đăng nhập)
- **Mật khẩu**: Mật khẩu đăng nhập (tối thiểu 6 ký tự)
- **Số điện thoại**: Số điện thoại liên lạc (tùy chọn)
- **Vai trò**: 
  - Stylist
  - Quản lý
  - Lễ tân
- **Liên kết Stylist**: Nếu vai trò là Stylist, cần chọn liên kết với thông tin stylist nào

### 2. Quản lý nhân viên

- **Xem danh sách**: Hiển thị tất cả nhân viên với trạng thái hoạt động
- **Chỉnh sửa**: Cập nhật thông tin nhân viên (trừ email và mật khẩu)
- **Vô hiệu hóa/Kích hoạt**: Tạm thời vô hiệu hóa hoặc kích hoạt lại tài khoản
- **Xóa**: Xóa hoàn toàn thông tin nhân viên (tài khoản đăng nhập vẫn tồn tại)

### 3. Thống kê

Dashboard admin hiển thị số lượng nhân viên đang hoạt động

## Cấu trúc dữ liệu

### Collection `employees`

```
{
  userId: string,           // ID của user trong collection users
  fullName: string,         // Họ tên đầy đủ
  email: string,            // Email
  phoneNumber?: string,     // Số điện thoại (tùy chọn)
  photoURL?: string,        // URL ảnh đại diện (tùy chọn)
  role: string,             // 'stylist', 'manager', 'receptionist'
  stylistId?: string,       // ID của stylist (nếu là stylist)
  isActive: boolean,        // Trạng thái hoạt động
  createdAt: timestamp,     // Ngày tạo
  updatedAt?: timestamp,    // Ngày cập nhật
  additionalInfo?: object   // Thông tin bổ sung
}
```

### Collection `users`

Khi tạo nhân viên, hệ thống tự động tạo document trong collection `users`:

```
{
  email: string,
  displayName: string,
  isAdmin: false,
  stylistId?: string,       // Liên kết với stylist (nếu có)
  createdAt: timestamp,
  lastLoginAt?: timestamp
}
```

## Các file liên quan

### 1. Model

- **`lib/models/employee.dart`**: Model Employee với các thuộc tính và phương thức

### 2. Service

- **`lib/services/admin_service.dart`**: 
  - `createEmployeeAccount()`: Tạo tài khoản nhân viên
  - `getEmployeesStream()`: Lấy danh sách nhân viên theo thời gian thực
  - `updateEmployee()`: Cập nhật thông tin nhân viên
  - `deactivateEmployee()`: Vô hiệu hóa nhân viên
  - `activateEmployee()`: Kích hoạt lại nhân viên
  - `deleteEmployee()`: Xóa nhân viên
  - `getEmployeeByUserId()`: Lấy thông tin nhân viên theo user ID
  - `getAvailableStylists()`: Lấy danh sách stylist để chọn
  - `getEmployeesCount()`: Đếm số nhân viên

### 3. Screens

- **`lib/screens/admin/manage_employees_screen.dart`**: Màn hình quản lý nhân viên
- **`lib/screens/admin/admin_dashboard.dart`**: Dashboard admin (đã thêm menu Nhân viên)

## Quy trình tạo tài khoản nhân viên

1. Admin vào trang "Quản lý Nhân viên" từ Dashboard
2. Điền form đăng ký với đầy đủ thông tin
3. Nếu chọn vai trò "Stylist", chọn stylist để liên kết
4. Nhấn "Đăng ký"
5. Hệ thống sẽ:
   - Tạo tài khoản Firebase Authentication
   - Lưu thông tin vào collection `users`
   - Lưu thông tin chi tiết vào collection `employees`
   - Liên kết với stylist (nếu có)

## Phân biệt với Quản lý Stylist cũ

### Quản lý Stylist (manage_stylists_screen.dart)
- Quản lý thông tin hiển thị của stylist (tên, ảnh, đánh giá, kinh nghiệm)
- Có chức năng tạo/liên kết tài khoản cho stylist
- Dùng cho việc hiển thị stylist cho khách hàng

### Quản lý Nhân viên (manage_employees_screen.dart) - MỚI
- Quản lý TÀI KHOẢN của nhân viên
- Đăng ký tài khoản mới cho nhân viên
- Quản lý vai trò và quyền hạn
- Liên kết với stylist (nếu là stylist)
- Quản lý trạng thái hoạt động

## Lợi ích

1. **Quản lý tập trung**: Tất cả tài khoản nhân viên được quản lý ở một nơi
2. **Phân quyền rõ ràng**: Dễ dàng phân loại theo vai trò
3. **Linh hoạt**: Có thể tạo nhân viên không phải stylist (lễ tân, quản lý)
4. **Bảo mật**: Admin kiểm soát việc tạo tài khoản
5. **Theo dõi**: Biết được trạng thái hoạt động của từng nhân viên

## Hướng dẫn sử dụng

### Đăng ký nhân viên mới

1. Vào Admin Dashboard
2. Chọn "Nhân viên" (icon badge màu tím)
3. Điền form "Đăng ký Tài khoản Nhân viên":
   - Họ và tên
   - Email (phải là email hợp lệ)
   - Mật khẩu (tối thiểu 6 ký tự)
   - Số điện thoại (không bắt buộc)
   - Chọn vai trò
   - Nếu là Stylist, chọn stylist để liên kết
4. Nhấn "Đăng ký"

### Chỉnh sửa thông tin nhân viên

1. Tìm nhân viên trong danh sách
2. Nhấn icon "Chỉnh sửa" (màu xanh)
3. Cập nhật thông tin cần thiết
4. Nhấn "Cập nhật"

### Vô hiệu hóa nhân viên

1. Nhấn icon "Block" (màu vàng) trên nhân viên
2. Nhân viên sẽ chuyển sang trạng thái "Vô hiệu"
3. Tài khoản không thể đăng nhập

### Kích hoạt lại nhân viên

1. Nhấn icon "Check" (màu xanh lá) trên nhân viên bị vô hiệu hóa
2. Nhân viên sẽ chuyển sang trạng thái "Hoạt động"

### Xóa nhân viên

1. Nhấn icon "Delete" (màu đỏ)
2. Xác nhận xóa
3. Lưu ý: Tài khoản đăng nhập vẫn tồn tại trong Firebase Auth

## Lưu ý quan trọng

1. **Email không thể thay đổi** sau khi tạo (Firebase Auth constraint)
2. **Mật khẩu** chỉ có thể đặt khi tạo mới, không thể chỉnh sửa từ admin panel
3. **Xóa nhân viên** chỉ xóa document trong collection `employees`, không xóa tài khoản Firebase Auth
4. **Vai trò Stylist** bắt buộc phải liên kết với một stylist trong collection `stylists`
5. **Admin không thể tự vô hiệu hóa tài khoản của mình**

## Phát triển trong tương lai

- [ ] Thêm chức năng reset mật khẩu cho nhân viên
- [ ] Thêm phân quyền chi tiết theo vai trò
- [ ] Thêm lịch sử hoạt động của nhân viên
- [ ] Thêm báo cáo hiệu suất làm việc
- [ ] Thêm quản lý ca làm việc
- [ ] Thêm thông báo cho nhân viên

## Troubleshooting

### Lỗi "Email đã được sử dụng"
- Email đã tồn tại trong Firebase Auth
- Sử dụng email khác hoặc xóa tài khoản cũ

### Lỗi "Chỉ admin mới có thể tạo tài khoản"
- Đảm bảo đang đăng nhập bằng tài khoản admin
- Kiểm tra field `isAdmin` trong collection `users`

### Không thể chọn stylist
- Kiểm tra collection `stylists` có dữ liệu
- Refresh trang nếu vừa thêm stylist mới

### Nhân viên không thể đăng nhập
- Kiểm tra trạng thái `isActive`
- Kiểm tra email và mật khẩu
- Kiểm tra Firebase Auth có tài khoản

---

**Ngày tạo**: 11 tháng 11, 2025
**Phiên bản**: 1.0.0
