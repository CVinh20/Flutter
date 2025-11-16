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
  }

  Future<void> scheduleBookingNotification(Booking booking) async {
    // Thông báo sẽ được gửi trước 1 giờ so với lịch hẹn
    final scheduledTime = booking.dateTime.subtract(const Duration(hours: 1));
    
    // Đảm bảo không đặt lịch thông báo cho một thời điểm trong quá khứ
    if (scheduledTime.isBefore(DateTime.now())) {
      print("Không đặt thông báo vì thời gian đã qua.");
      return;
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        booking.id.hashCode, // ID duy nhất cho mỗi thông báo
        'Lịch hẹn sắp tới!',
        'Bạn có lịch hẹn ${booking.service.name} vào lúc ${DateFormat('HH:mm').format(booking.dateTime)}. Hãy chuẩn bị nhé!',
        tz.TZDateTime.from(scheduledTime, tz.local),
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
      print("Đã đặt thông báo thành công cho booking ${booking.id}");
    } catch (e) {
      print("Lỗi khi đặt thông báo: $e");
    }
  }

  Future<void> cancelNotification(String bookingId) async {
    await _notificationsPlugin.cancel(bookingId.hashCode);
    print("Đã hủy thông báo cho booking $bookingId");
  }
}