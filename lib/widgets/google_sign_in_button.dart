import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final double? width;
  final double height;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.text = 'Đăng nhập với Google',
    this.width,
    this.height = 56,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              )
            : Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://developers.google.com/identity/images/g-logo.png',
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isLoading 
                ? Colors.grey 
                : const Color(0xFF1A1A1A),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A1A),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isLoading 
                ? Colors.grey.shade300 
                : const Color(0xFFD1D5DB), 
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isLoading ? 0 : 1,
          shadowColor: Colors.black.withOpacity(0.1),
        ),
      ),
    );
  }
}

