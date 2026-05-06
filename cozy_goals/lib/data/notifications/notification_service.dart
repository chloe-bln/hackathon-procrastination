import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const linux = LinuxInitializationSettings(defaultActionName: 'Open Cozy Goals');
    const settings = InitializationSettings(linux: linux);
    await _plugin.initialize(settings);
  }

  Future<void> showEncouragement(String message) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Cozy Goals',
      message,
      NotificationDetails(
        linux: LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.normal,
          timeout: LinuxNotificationTimeout.fromDuration(const Duration(seconds: 5)),
        ),
      ),
    );
  }

  Future<void> showDailyReminder({required int completed}) async {
    final body = completed < 3
        ? 'You have completed $completed / 3 goals. A tiny push keeps the streak warm 🌷'
        : 'Your daily streak is safe. Enjoy the calm ✨';
    await _plugin.show(
      3001,
      'Gentle evening reminder',
      body,
      NotificationDetails(
        linux: LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.normal,
          timeout: LinuxNotificationTimeout.fromDuration(const Duration(seconds: 8)),
        ),
      ),
    );
  }
}
