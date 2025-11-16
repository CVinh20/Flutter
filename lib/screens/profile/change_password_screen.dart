// lib/screens/profile/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart'; // Thêm import AuthService
import '../login_screen.dart'; // Thêm import LoginScreen

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Khởi tạo AuthService để sử dụng hàm signOut
  final _authService = AuthService();

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    // Kiểm tra user và email để tránh lỗi null
    if (user == null || user.email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy thông tin người dùng.'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
      return;
    }

    final cred = EmailAuthProvider.credential(
      email: user.email!, 
      password: _currentPasswordController.text
    );

    try {
      // Xác thực lại người dùng với mật khẩu hiện tại
      await user.reauthenticateWithCredential(cred);
      // Nếu thành công, cập nhật mật khẩu mới
      await user.updatePassword(_newPasswordController.text);
      
      if (mounted) {
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.'), backgroundColor: Colors.green));
        
        // *** PHẦN SỬA LỖI QUAN TRỌNG NHẤT ***
        // Gọi hàm đăng xuất
        await _authService.signOut();

        // Điều hướng người dùng về màn hình đăng nhập và xóa hết các màn hình cũ
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final message = e.code == 'wrong-password' 
            ? 'Mật khẩu hiện tại không đúng.' 
            : 'Lỗi: ${e.message ?? 'Vui lòng thử lại.'}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } finally {
      // Đảm bảo loading indicator luôn được tắt
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới', border: OutlineInputBorder()),
                validator: (v) {
                  if (v!.isEmpty) return 'Không được để trống';
                  if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới', border: OutlineInputBorder()),
                validator: (v) {
                  if (v != _newPasswordController.text) return 'Mật khẩu không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)
                ),
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) 
                    : const Text('Xác nhận'),
              )
            ],
          ),
        ),
      ),
    );
  }
}