// lib/screens/profile/help_support_screen.dart
import 'package:flutter/material.dart';
import 'about_us_screen.dart';
import 'terms_policy_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin hỗ trợ khách hàng')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Cam kết 30Shine Care'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _navigateTo(context, const CareCommitmentScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Về chúng tôi'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _navigateTo(context, const AboutUsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.sync_alt_outlined),
            title: const Text('Điều kiện giao dịch chung'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _navigateTo(context, const TermsPolicyScreen(mode: 'terms')),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Chính sách bảo mật thông tin'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _navigateTo(context, const TermsPolicyScreen(mode: 'privacy')),
          ),
        ],
      ),
    );
  }
}

// Màn hình con cho "Cam kết 30Shine Care"
class CareCommitmentScreen extends StatelessWidget {
  const CareCommitmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cam kết 30Shine Care')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.network('https://i.imgur.com/G4T7v9J.png'),
            const SizedBox(height: 16),
            const Text(
              '7 ngày chỉnh sửa tóc miễn phí\n\nNếu anh chưa hài lòng về kiểu tóc sau khi về nhà vì bất kỳ lý do gì, 30Shine sẽ hỗ trợ anh sửa lại mái tóc đó hoàn toàn miễn phí trong vòng 7 ngày...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}