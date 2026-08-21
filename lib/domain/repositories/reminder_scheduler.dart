import '../entities/adhkar_counter.dart';
import '../entities/app_settings.dart';

abstract class ReminderScheduler {
  Future<bool> requestPermission();
  Future<void> rescheduleAll(
      List<AdhkarCounter> counters, {AppSettings? settings});
  Future<void> showDailyTargetReached(String counterName);
}
