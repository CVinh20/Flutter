// lib/screens/profile/notifications_screen.dart
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _promoNotifications = true;
  bool _bookingNotifications = true;
  bool _appUpdates = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt thông báo')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNotificationSwitch(
            title: 'Khuyến mãi và ưu đãi',
            subtitle: 'Nhận thông tin về các chương trình giảm giá',
            value: _promoNotifications,
            onChanged: (val) => setState(() => _promoNotifications = val),
          ),
          _buildNotificationSwitch(
            title: 'Lịch hẹn',
            subtitle: 'Nhận thông báo nhắc nhở lịch hẹn sắp tới',
            value: _bookingNotifications,
            onChanged: (val) => setState(() => _bookingNotifications = val),
          ),
          _buildNotificationSwitch(
            title: 'Cập nhật ứng dụng',
            subtitle: 'Thông báo khi có phiên bản mới',
            value: _appUpdates,
            onChanged: (val) => setState(() => _appUpdates = val),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
}