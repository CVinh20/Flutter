// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import '../models/booking.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {},
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
    
    // Request notification permission for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    print('✅ Notification service initialized');
  }

  Future<void> scheduleBookingNotification(Booking booking) async {
    // Thông báo sẽ được gửi trước 30 phút so với lịch hẹn
    final scheduledTime = booking.dateTime.subtract(const Duration(minutes: 30));
    
    print('📅 Booking time: ${booking.dateTime}');
    print('⏰ Notification scheduled for: $scheduledTime');
    print('🕐 Current time: ${DateTime.now()}');
    
    // Đảm bảo không đặt lịch thông báo cho một thời điểm trong quá khứ
    if (scheduledTime.isBefore(DateTime.now())) {
      print("⚠️ Không đặt thông báo vì thời gian đã qua ($scheduledTime)");
      return;
    }

    try {
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      print('🌍 TZ Scheduled time: $tzScheduledTime');
      
      await _notificationsPlugin.zonedSchedule(
        booking.id.hashCode, // ID duy nhất cho mỗi thông báo
        'Lịch hẹn sắp tới!',
        'Bạn có lịch hẹn ${booking.service.name} vào lúc ${DateFormat('HH:mm').format(booking.dateTime)}. Hãy chuẩn bị nhé!',
        tzScheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'booking_channel',
            'Booking Reminders',
            channelDescription: 'Kênh thông báo cho lịch hẹn',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      print("✅ Đã đặt thông báo thành công cho booking ${booking.id} (hashCode: ${booking.id.hashCode})");
    } catch (e) {
      print("❌ Lỗi khi đặt thông báo: $e");
    }
  }

  Future<void> cancelNotification(String bookingId) async {
    await _notificationsPlugin.cancel(bookingId.hashCode);
    print("Đã hủy thông báo cho booking $bookingId");
  }
}