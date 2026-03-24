// lib/services/mongodb_auth_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import 'api_service.dart';

class MongoDBAuthService {
  // Đang test trên Android emulator → backend: 10.0.2.2
  // Nếu chạy Web trên PC thì nên tách baseUrl, nhưng tạm thời để thế này cho dễ debug.
  static const String _baseUrl = 'http://10.0.2.2:5000/api/auth';

  static String? _token;
  static UserModel? _currentUser;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static String? get token => _token;
  static UserModel? get currentUser => _currentUser;

  /// Khởi tạo - tải token từ SharedPreferences
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      
      // Sync token với ApiService
      if (_token != null) {
        await ApiService.setToken(_token!);
        print('🔑 Token loaded and synced: ${_token!.substring(0, 20)}...');
      } else {
        print('⚠️ No token found during initialization');
      }

      // Load current user info từ cache
      final userJson = prefs.getString('current_user_json');
      if (userJson != null) {
        try {
          _currentUser = UserModel.fromJson(jsonDecode(userJson));
          print('✅ Current user loaded: ${_currentUser!.email}');
        } catch (e) {
          print('Lỗi decode current user: $e');
        }
      }
    } catch (e) {
      print('Lỗi khởi tạo auth: $e');
    }
  }

  /// Lưu token vào SharedPreferences
  static Future<void> _saveToken(String token) async {
    _token = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      print('Lỗi lưu token: $e');
    }
  }

  /// Lưu current user vào SharedPreferences
  static Future<void> _saveCurrentUser(UserModel user) async {
    _currentUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_json', jsonEncode(user.toJson()));
    } catch (e) {
      print('Lỗi lưu current user: $e');
    }
  }

  /// Xóa current user từ cache
  static Future<void> _clearCurrentUser() async {
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_json');
    } catch (e) {
      print('Lỗi xóa current user: $e');
    }
  }

  /// Helper: parse response của backend, lấy token + user
  static Map<String, dynamic> _parseAuthResponse(String body) {
    final decoded = jsonDecode(body);

    // hỗ trợ 2 kiểu:
    // 1) { success, token, data: {...user...} }
    // 2) { success, data: { token, ...userFields } }
    final data = decoded['data'];

    String? token;
    Map<String, dynamic>? userMap;

    if (data is Map && data['token'] != null) {
      // kiểu 2
      token = data['token'];
      userMap = Map<String, dynamic>.from(data)..remove('token');
    } else {
      // kiểu 1
      token = decoded['token'];
      if (data is Map) {
        userMap = Map<String, dynamic>.from(data);
      }
    }

    if (token == null || userMap == null) {
      throw 'Response không chứa token hoặc data user';
    }

    return {'token': token, 'user': userMap};
  }

  /// Đăng ký người dùng mới
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String role = 'customer',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
        final parsed = _parseAuthResponse(response.body);
        final token = parsed['token'] as String;
        final userMap = parsed['user'] as Map<String, dynamic>;

        await _saveToken(token);
        await ApiService.setToken(token); // Sync token với ApiService

        // Lưu user info để dùng sau
        final user = UserModel.fromJson(userMap);
        await _saveCurrentUser(user);

        return {'success': true, 'user': user, 'token': token};
      } else {
        final error = jsonDecode(response.body);
        throw error['error'] ?? error['message'] ?? 'Đăng ký thất bại';
      }
    } catch (e) {
      throw 'Lỗi đăng ký: $e';
    }
  }

  /// Đăng nhập
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final parsed = _parseAuthResponse(response.body);
        final token = parsed['token'] as String;
        final userMap = parsed['user'] as Map<String, dynamic>;

        await _saveToken(token);
        await ApiService.setToken(token); // Sync token với ApiService

        // Lưu user info để dùng sau
        final user = UserModel.fromJson(userMap);
        await _saveCurrentUser(user);

        print('✅ Login successful. Token: ${token.substring(0, 20)}...');
        print('✅ User ID: ${user.id}');

        return {'success': true, 'user': user, 'token': token};
      } else {
        final error = jsonDecode(response.body);
        throw error['error'] ?? error['message'] ?? 'Đăng nhập thất bại';
      }
    } catch (e) {
      throw 'Lỗi đăng nhập: $e';
    }
  }

  /// Lấy thông tin user hiện tại
  static Future<UserModel> getCurrentUser() async {
    try {
      if (_token == null) {
        throw 'Chưa đăng nhập';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw error['error'] ?? 'Lỗi lấy thông tin user';
      }
    } catch (e) {
      throw 'Lỗi: $e';
    }
  }

  /// Cập nhật profile
  static Future<UserModel> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (_token == null) {
        throw 'Chưa đăng nhập';
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'displayName': displayName,
          'photoURL': photoURL,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedUser = UserModel.fromJson(data['data']);
        await _saveCurrentUser(updatedUser);
        return updatedUser;
      } else {
        final error = jsonDecode(response.body);
        throw error['error'] ?? 'Lỗi cập nhật profile';
      }
    } catch (e) {
      throw 'Lỗi: $e';
    }
  }

  /// Đổi mật khẩu
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_token == null) {
        throw 'Chưa đăng nhập';
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw error['error'] ?? error['message'] ?? 'Lỗi đổi mật khẩu';
      }
    } catch (e) {
      throw 'Lỗi: $e';
    }
  }

  /// Gửi email reset password
  static Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw error['error'] ?? error['message'] ?? 'Gửi email thất bại';
      }
    } catch (e) {
      throw 'Lỗi: $e';
    }
  }

  /// Đăng xuất
  static Future<void> logout() async {
    try {
      if (_token != null) {
        await http.post(
          Uri.parse('$_baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );
      }

      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      _token = null;
      await _clearCurrentUser();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      // Dù sao cũng xoá token local
      _token = null;
      await _clearCurrentUser();
      await ApiService.removeToken(); // Xóa token khỏi ApiService

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('Lỗi logout (nhưng đã xoá token local): $e');
    }
  }

  /// Đăng nhập bằng Google
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign In...');
      
      // Sign out first to ensure fresh login
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw 'Đăng nhập Google bị hủy';
      }

      print('✅ Google user: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Không lấy được ID token từ Google';
      }

      print('🔑 Got Google ID token');

      // Send to backend
      final response = await http.post(
        Uri.parse('$_baseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'email': googleUser.email,
          'displayName': googleUser.displayName ?? googleUser.email.split('@')[0],
          'photoUrl': googleUser.photoUrl,
        }),
      );

      if (response.statusCode == 200) {
        final parsed = _parseAuthResponse(response.body);
        final token = parsed['token'] as String;
        final userMap = parsed['user'] as Map<String, dynamic>;

        await _saveToken(token);
        await ApiService.setToken(token);

        final user = UserModel.fromJson(userMap);
        await _saveCurrentUser(user);

        print('✅ Google sign in successful');
        return {'success': true, 'user': user, 'token': token};
      } else {
        final error = jsonDecode(response.body);
        throw error['error'] ?? error['message'] ?? 'Đăng nhập Google thất bại';
      }
    } catch (e) {
      print('❌ Google sign in error: $e');
      throw 'Lỗi đăng nhập Google: $e';
    }
  }

  /// Set token thủ công (nếu cần)
  static void setToken(String token) {
    _token = token;
  }
}
