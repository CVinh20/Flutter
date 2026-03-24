// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../services/mongodb_auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sending = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    await EasyLoading.show(
      status: 'Đang gửi email...',
      maskType: EasyLoadingMaskType.black,
    );

    try {
      await MongoDBAuthService.sendPasswordResetEmail(
        email: _emailCtrl.text.trim(),
      );

      if (!mounted) return;

      // Show success dialog
      await EasyLoading.dismiss();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Email đã gửi!',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          content: Text(
            'Chúng tôi đã gửi link đặt lại mật khẩu đến email:\n\n${_emailCtrl.text.trim()}\n\nVui lòng kiểm tra hộp thư (kể cả thư spam) và làm theo hướng dẫn.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to login
              },
              child: const Text(
                'Đã hiểu',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        EasyLoading.showError(e.toString());
      }
    } finally {
      setState(() => _sending = false);
      await EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0891B2), Color(0xFF06B6D4), Color(0xFF22D3EE)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Back Button
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Main Content
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon
                          Container(
                            padding: EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.lock_reset_rounded,
                              size: 80,
                              color: Color(0xFF0891B2),
                            ),
                          ),
                          SizedBox(height: 40),

                          // Title
                          Text(
                            'QUÊN MẬT KHẨU',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Nhập email để đặt lại mật khẩu',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          SizedBox(height: 48),

                          // Form Card
                          Container(
                            constraints: BoxConstraints(maxWidth: 420),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(28),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _emailCtrl,
                                      keyboardType: TextInputType.emailAddress,
                                      style: TextStyle(fontSize: 16),
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        hintText: 'your@email.com',
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: Color(0xFF0891B2),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF0891B2),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 18,
                                        ),
                                      ),
                                      validator: (v) {
                                        final value = v?.trim() ?? '';
                                        if (value.isEmpty)
                                          return 'Vui lòng nhập email';
                                        final ok = RegExp(
                                          r'^[^@]+@[^@]+\.[^@]+$',
                                        ).hasMatch(value);
                                        if (!ok) return 'Email không hợp lệ';
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton.icon(
                                        onPressed: _sending
                                            ? null
                                            : _sendResetEmail,
                                        icon: _sending
                                            ? SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : Icon(
                                                Icons.send_rounded,
                                                size: 22,
                                              ),
                                        label: Text(
                                          _sending
                                              ? 'Đang gửi...'
                                              : 'Gửi email đặt lại',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF0891B2),
                                          foregroundColor: Colors.white,
                                          elevation: 4,
                                          shadowColor: Color(
                                            0xFF0891B2,
                                          ).withOpacity(0.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          disabledBackgroundColor:
                                              Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 32),

                          // Info Text
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Email có thể mất vài phút để đến. Hãy kiểm tra cả hộp thư spam.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
