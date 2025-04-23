import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);
  }

  static Future showSimpleNotification(String title) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails('channelId', 'channelName'),
    );
    await _notifications.show(0, title, 'Не забудь про задачу!', details);
  }
}
