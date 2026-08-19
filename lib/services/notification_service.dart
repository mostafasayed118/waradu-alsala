import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/app_settings.dart';
import '../utils/app_strings.dart';

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    
    return true;
  }

  Future<void> scheduleIntervalNotification(int intervalMinutes) async {
    await cancelAllNotifications();
    
    if (intervalMinutes <= 0) return;

    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(Duration(minutes: intervalMinutes));

    await _notifications.zonedSchedule(
      0,
      AppStrings.notificationTitle,
      AppStrings.notificationBody,
      scheduledTime,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  Future<void> scheduleDailyNotifications(List<int> times) async {
    await cancelAllNotifications();
    
    if (times.isEmpty) return;

    final details = _details();

    for (int i = 0; i < times.length; i++) {
      final hour = times[i] ~/ 60;
      final minute = times[i] % 60;
      
      await _notifications.zonedSchedule(
        i,
        AppStrings.notificationTitle,
        AppStrings.notificationBody,
        _nextInstanceOfTime(hour, minute),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> showDailyTargetReached() async {
    await _notifications.show(
      _targetReachedNotificationId,
      AppStrings.targetReachedTitle,
      AppStrings.targetReachedBody,
      _details(),
    );
  }

  static const int _targetReachedNotificationId = 9999;

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'salawat_reminder',
          'تذكير بالصلاة على النبي',
          channelDescription: 'تذكير يومي بالصلاة على النبي ﷺ',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<bool> areNotificationsScheduled() async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    return pendingNotifications.isNotEmpty;
  }
}
