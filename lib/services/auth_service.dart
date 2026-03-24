// lib/services/auth_service.dart
import 'dart:convert';
import 'mongodb_auth_service.dart';
import '../models/user.dart';

class AuthService {
  /// Vì dùng token nên không cần stream auth thực,
  /// giữ lại cho tương thích code cũ
  Stream<UserModel?> get authStateChanges => Stream.value(null);

  /// Đăng nhập bằng Email & Password (MongoDB)
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await MongoDBAuthService.login(
        email: email,
        password: password,
      );
      return result; // { success, user, token }
    } catch (e) {
      throw 'Lỗi đăng nhập: $e';
    }
  }

  /// Đăng ký bằng Email & Password (MongoDB)
  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    String role = 'customer',
  }) async {
    try {
      final result = await MongoDBAuthService.register(
        fullName: username,
        email: email,
        password: password,
        role: role,
      );
      return result;
    } catch (e) {
      throw 'Lỗi đăng ký: $e';
    }
  }

  /// Gửi email quên mật khẩu (chưa làm)
  Future<void> sendPasswordResetEmail({required String email}) async {
    throw 'Tính năng này sẽ được triển khai sau';
  }

  /// Đăng xuất
  Future<void> signOut() async {
    try {
      await MongoDBAuthService.logout();
    } catch (e) {
      print("Lỗi khi đăng xuất: $e");
    }
  }

  /// Kiểm tra quyền admin bằng cách decode JWT token
  Future<bool> isAdmin() async {
    final rawToken = MongoDBAuthService.token;
    if (rawToken == null) return false;

    try {
      final parts = rawToken.split('.');
      if (parts.length != 3) return false;

      // payload là phần thứ 2
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final Map<String, dynamic> data = jsonDecode(payload);

      final role = data['role'];
      return role == 'admin';
    } catch (e) {
      print('Lỗi decode token: $e');
      return false;
    }
  }

  /// Lấy thông tin user hiện tại
  Future<UserModel?> getCurrentUser() async {
    try {
      return await MongoDBAuthService.getCurrentUser();
    } catch (e) {
      print("Lỗi lấy thông tin user: $e");
      return null;
    }
  }

  /// Lấy token hiện tại
  String? getToken() => MongoDBAuthService.token;

  /// Khởi tạo - tải token từ storage
  Future<void> initialize() async {
    await MongoDBAuthService.initialize();
  }
}
