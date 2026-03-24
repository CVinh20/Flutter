// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../services/mongodb_auth_service.dart';
import '../models/user.dart';
import '../main.dart';
import 'admin/admin_dashboard.dart';
import 'stylist/stylist_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;

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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

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

  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    await EasyLoading.show(
      status: 'Đang đăng nhập...',
      maskType: EasyLoadingMaskType.black,
      dismissOnTap: false,
    );

    try {
      final result = await MongoDBAuthService.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // result: { success, user: UserModel, token: ... }
      final user = result['user'] as UserModel;

      if (!mounted) return;

      EasyLoading.showSuccess('Đăng nhập thành công!');
      await Future.delayed(const Duration(milliseconds: 400));

      // Điều hướng theo role
      Widget next;
      if (user.isAdmin) {
        next = const AdminDashboard();
      } else if (user.isStylist) {
        next = const StylistDashboardScreen();
      } else {
        next = const MainScreen();
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => next),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        EasyLoading.showError('Lỗi đăng nhập: $e');
      }
    } finally {
      await EasyLoading.dismiss();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await EasyLoading.show(
      status: 'Đang đăng nhập bằng Google...',
      maskType: EasyLoadingMaskType.black,
      dismissOnTap: false,
    );

    try {
      final result = await MongoDBAuthService.signInWithGoogle();
      final user = result['user'] as UserModel;

      if (!mounted) return;

      EasyLoading.showSuccess('Đăng nhập thành công!');
      await Future.delayed(const Duration(milliseconds: 400));

      Widget next;
      if (user.isAdmin) {
        next = const AdminDashboard();
      } else if (user.isStylist) {
        next = const StylistDashboardScreen();
      } else {
        next = const MainScreen();
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => next),
        (route) => false,
      );
    } catch (e) {
      print('❌ Google Sign In error: $e');
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
            colors: [Color(0xFF0891B2), Color(0xFF06B6D4), Color(0xFF22D3EE)],
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
                      // Logo
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
                            return const Icon(
                              Icons.content_cut_rounded,
                              size: 60,
                              color: Color(0xFF0891B2),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'GENTLEMEN\'S GROOMING',
                        style: TextStyle(
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

                      // Card form
                      Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
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
                                // Email
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'your@email.com',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 14,
                                    ),
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 14,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF0891B2),
                                      size: 20,
                                    ),
                                  ),
                                  validator: (v) {
                                    final value = v?.trim() ?? '';
                                    if (value.isEmpty) {
                                      return 'Vui lòng nhập email';
                                    }
                                    if (!RegExp(
                                      r'^[^@]+@[^@]+\.[^@]+$',
                                    ).hasMatch(value)) {
                                      return 'Email không hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu',
                                    hintText: '••••••••',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 14,
                                    ),
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 14,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF6B7280),
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: const Color(0xFF6B7280),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu';
                                    }
                                    if (v.length < 6) {
                                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.of(
                                      context,
                                    ).pushNamed('/forgot-password'),
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

                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _handleEmailSignIn,
                                    child: const Text(
                                      'Đăng nhập',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Divider
                                Row(
                                  children: [
                                    const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'HOẶC',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Google Sign In Button
                                SizedBox(
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: _handleGoogleSignIn,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/google_logo.png',
                                          height: 20,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.g_mobiledata,
                                              size: 28,
                                              color: Color(0xFF4285F4),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Đăng nhập bằng Google',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

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
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/register'),
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
