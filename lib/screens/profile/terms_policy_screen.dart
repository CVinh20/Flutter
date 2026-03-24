// lib/screens/profile/terms_policy_screen.dart
import 'package:flutter/material.dart';

class TermsPolicyScreen extends StatelessWidget {
  final String mode;

  const TermsPolicyScreen({
    super.key,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTerms = (mode == 'terms');
    final String title = isTerms ? 'Điều kiện giao dịch' : 'Chính sách bảo mật';
    final String content = isTerms
        ? 'Nội dung chi tiết về Điều kiện và Điều khoản giao dịch chung của ứng dụng...'
        : 'Nội dung chi tiết về Chính sách bảo mật thông tin khách hàng, bao gồm việc thu thập, sử dụng và bảo vệ dữ liệu cá nhân...';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}