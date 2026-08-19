import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/adhkar_counter.dart';
import '../utils/app_strings.dart';

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
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

  /// Cancels all scheduled reminders, then schedules each counter whose
  /// reminders are enabled using a distinct id range
  /// (`idBase = 100 + index * 100`).
  Future<void> rescheduleAll(List<AdhkarCounter> counters) async {
    await cancelAllNotifications();

    for (var i = 0; i < counters.length; i++) {
      final counter = counters[i];
      if (!counter.remindersEnabled) continue;

      final idBase = 100 + i * 100;
      if (counter.reminderType == ReminderType.interval) {
        if (counter.reminderIntervalMinutes <= 0) continue;
        final scheduledTime = tz.TZDateTime.now(tz.local)
            .add(Duration(minutes: counter.reminderIntervalMinutes));
        await _notifications.zonedSchedule(
          idBase,
          counter.name,
          AppStrings.reminderBody,
          scheduledTime,
          _details(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
      } else {
        for (var j = 0; j < counter.dailyReminderTimes.length; j++) {
          final time = counter.dailyReminderTimes[j];
          await _notifications.zonedSchedule(
            idBase + j,
            counter.name,
            AppStrings.reminderBody,
            _nextInstanceOfTime(time ~/ 60, time % 60),
            _details(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }
    }
  }

  Future<void> showDailyTargetReached(String counterName) async {
    await _notifications.show(
      _targetReachedNotificationId,
      AppStrings.targetReachedTitle,
      '${AppStrings.targetReachedBody}: $counterName',
      _details(),
    );
  }

  static const int _targetReachedNotificationId = 9999;

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'salawat_reminder',
          'تذكير بالذكر',
          channelDescription: 'تذكير يومي بالذكر',
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
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
