// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isGoogleSigningIn = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleSigningIn) return;
    
    setState(() {
      _isGoogleSigningIn = true;
    });
    
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && mounted) {
        EasyLoading.showSuccess('Đăng nhập thành công!');
        await Future.delayed(const Duration(milliseconds: 500));
        // Điều hướng qua AuthWrapper để phân quyền admin/user
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      }
      // Nếu userCredential == null, người dùng đã hủy đăng nhập
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('network')) {
          errorMessage = 'Không có kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.';
        } else if (errorMessage.contains('popup-closed-by-user')) {
          errorMessage = 'Bạn đã hủy đăng nhập.';
        } else if (errorMessage.contains('sign_in_failed')) {
          errorMessage = 'Đăng nhập Google thất bại. Vui lòng thử lại.';
        }
        EasyLoading.showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSigningIn = false;
        });
      }
    }
  }

  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    await EasyLoading.show(
      status: 'Đang đăng nhập...',
      maskType: EasyLoadingMaskType.black,
      dismissOnTap: false,
    );
    try {
      await _authService.signInWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) {
        // Điều hướng qua AuthWrapper để phân quyền admin/user
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      }
    } catch (e) {
      if (mounted) {
        EasyLoading.showError(e.toString());
      }
    } finally {
      await EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0891B2),
              Color(0xFF06B6D4),
              Color(0xFF22D3EE),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Container nhỏ gọn hơn
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/gg.png',
                          width: 70,
                          height: 70,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.content_cut_rounded,
                              size: 60,
                              color: Color(0xFF0891B2),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title gọn hơn
                      Text(
                        'GENTLEMEN\'S GROOMING',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Chào mừng trở lại',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Card Form gọn hơn
                      Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email Field gọn hơn
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'your@email.com',
                                    labelStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0891B2), size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFF0891B2), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  validator: (v) {
                                    final value = v?.trim() ?? '';
                                    if (value.isEmpty) return 'Vui lòng nhập email';
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) 
                                      return 'Email không hợp lệ';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Password Field gọn hơn
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu',
                                    hintText: '••••••••',
                                    labelStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                                    prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF6B7280), size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Color(0xFF6B7280),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword = !_obscurePassword);
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Color(0xFFD1D5DB)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Color(0xFFD1D5DB)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFF0891B2), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                                    if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                
                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context).pushNamed('/forgot-password'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      minimumSize: Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Quên mật khẩu?',
                                      style: TextStyle(
                                        color: Color(0xFF0891B2),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Login Button gọn hơn
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _handleEmailSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0891B2),
                                      foregroundColor: Colors.white,
                                      elevation: 6,
                                      shadowColor: const Color(0xFF0891B2).withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      'Đăng nhập',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 18),
                                
                                // Divider gọn hơn
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Color(0xFFD1D5DB), thickness: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'HOẶC',
                                        style: TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Color(0xFFD1D5DB), thickness: 1)),
                                  ],
                                ),
                                
                                const SizedBox(height: 18),
                                
                                // Google Sign In
                                GoogleSignInButton(
                                  onPressed: _handleGoogleSignIn,
                                  isLoading: _isGoogleSigningIn,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Register Link gọn hơn
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chưa có tài khoản? ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed('/register'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Đăng ký ngay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}