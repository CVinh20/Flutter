// lib/services/auth_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/google_signin_config.dart';
import 'admin_service.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: GoogleSignInConfig.webClientId, // Sử dụng web client ID làm server client ID
  );
  final AdminService _adminService = AdminService();

  /// Lắng nghe sự thay đổi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng nhập bằng Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Kiểm tra kết nối mạng trước khi đăng nhập
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Người dùng đã hủy

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Kiểm tra token có hợp lệ không
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw 'Không thể lấy thông tin xác thực từ Google. Vui lòng thử lại.';
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      // Đồng bộ thông tin user vào Firestore sau khi đăng nhập
      await _adminService.updateUserAfterLogin();
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on Exception catch (e) {
      if (e.toString().contains('network')) {
        throw 'Không có kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.';
      } else if (e.toString().contains('sign_in_failed')) {
        throw 'Đăng nhập Google thất bại. Vui lòng thử lại.';
      } else if (e.toString().contains('popup_closed_by_user')) {
        throw 'Bạn đã hủy đăng nhập.';
      }
      throw 'Lỗi đăng nhập Google: ${e.toString()}';
    } catch (e) {
      throw 'Lỗi đăng nhập Google: ${e.toString()}';
    }
  }

  /// Đăng nhập bằng Email & Password
  Future<UserCredential> signInWithEmail({required String email, required String password}) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Cập nhật thông tin user sau khi đăng nhập
      await _adminService.updateUserAfterLogin();
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Đăng ký bằng Email & Password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(username);
      await userCredential.user?.sendEmailVerification();
      
      // Lưu thông tin user vào Firestore
      await _adminService.updateUserAfterLogin();
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Gửi email quên mật khẩu
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      // Bỏ qua lỗi nếu có
      print("Lỗi khi đăng xuất: $e");
    }
  }

  /// Kiểm tra quyền admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      return await _adminService.isAdmin(user.uid);
    } catch (e) {
      print("Lỗi khi kiểm tra quyền admin: $e");
      return false;
    }
  }

  /// Lấy thông tin user hiện tại
  Future<UserModel?> getCurrentUser() async {
    return await _adminService.getCurrentUser();
  }

  // Hàm private để xử lý lỗi
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Không có kết nối mạng, vui lòng thử lại.';
      case 'popup-closed-by-user':
        return 'Bạn đã đóng cửa sổ đăng nhập.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hoá.';
      case 'account-exists-with-different-credential':
        return 'Email này đã được liên kết với một nhà cung cấp khác.';
      case 'invalid-credential':
      case 'wrong-password':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'user-not-found':
        return 'Không tìm thấy người dùng với email này.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng bởi một tài khoản khác.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này không được phép.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      case 'invalid-verification-code':
        return 'Mã xác thực không hợp lệ.';
      case 'invalid-verification-id':
        return 'ID xác thực không hợp lệ.';
      case 'credential-already-in-use':
        return 'Thông tin đăng nhập này đã được sử dụng.';
      default:
        return 'Lỗi xác thực: ${e.message ?? e.code}';
    }
  }
}