import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import 'package:salawat_app/domain/entities/adhkar_counter.dart';
import 'package:salawat_app/domain/entities/app_settings.dart';
import 'package:salawat_app/domain/repositories/reminder_scheduler.dart';
import 'package:salawat_app/core/l10n/app_strings.dart';
import 'package:salawat_app/data/notifications/prayer_schedule.dart';

class NotificationService implements ReminderScheduler {
  NotificationService();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initFuture;

  /// Idempotent and safe to call before use; starts init once and returns
  /// the same future on repeat calls.
  Future<void> init() {
    if (_initialized) return Future.value();
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
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

    await _notifications.initialize(settings: initSettings);
    _initialized = true;
  }

  /// Ensures init has started/completed before any plugin or tz usage.
  Future<void> _ensureInitialized() {
    if (_initialized) return Future.value();
    return init();
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
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
  ///
  /// [ReminderType.prayer] counters need [settings] with a configured
  /// location; solar times drift daily, so a rolling window of the next few
  /// days is scheduled explicitly and refreshed on every app open.
  @override
  Future<void> rescheduleAll(
    List<AdhkarCounter> counters, {
    AppSettings? settings,
  }) async {
    await _ensureInitialized();
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
          id: idBase,
          title: counter.name,
          body: AppStrings.reminderBody,
          scheduledDate: scheduledTime,
          notificationDetails: _details(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else if (counter.reminderType == ReminderType.prayer) {
        final lat = settings?.latitude;
        final lng = settings?.longitude;
        if (lat == null || lng == null) continue;
        final times = prayerReminderTimes(
          latitude: lat,
          longitude: lng,
          method: settings?.calculationMethod ?? 'muslim_world_league',
          offsetMinutes: counter.prayerOffsetMinutes,
          now: DateTime.now(),
        );
        for (var j = 0; j < times.length && j < _maxPrayerNotifications; j++) {
          await _notifications.zonedSchedule(
            id: idBase + j,
            title: counter.name,
            body: AppStrings.reminderBody,
            scheduledDate: tz.TZDateTime.from(times[j], tz.local),
            notificationDetails: _details(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      } else {
        for (var j = 0; j < counter.dailyReminderTimes.length; j++) {
          final time = counter.dailyReminderTimes[j];
          await _notifications.zonedSchedule(
            id: idBase + j,
            title: counter.name,
            body: AppStrings.reminderBody,
            scheduledDate: _nextInstanceOfTime(time ~/ 60, time % 60),
            notificationDetails: _details(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }
    }
  }

  @override
  Future<void> showDailyTargetReached(String counterName) async {
    await _ensureInitialized();
    await _notifications.show(
      id: _targetReachedNotificationId,
      title: AppStrings.targetReachedTitle,
      body: '${AppStrings.targetReachedBody}: $counterName',
      notificationDetails: _details(),
    );
  }

  static const int _targetReachedNotificationId = 9999;

  /// Cap per prayer counter (5 prayers × 3 days = 15; headroom for edge
  /// cases) so a misconfigured device clock cannot flood the alarm manager.
  static const int _maxPrayerNotifications = 16;

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
    await _ensureInitialized();
    await _notifications.cancelAll();
  }
}

