import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/utils/prayer_schedule.dart';

void main() {
  // Makkah, fixed instant: 2025-06-15 10:00 local.
  const lat = 21.4225;
  const lng = 39.8262;
  final now = DateTime(2025, 6, 15, 10, 0);

  group('prayerReminderTimes', () {
    test('returns sorted upcoming times with the offset applied', () {
      final times = prayerReminderTimes(
        latitude: lat,
        longitude: lng,
        method: 'muslim_world_league',
        offsetMinutes: 10,
        now: now,
        days: 2,
      );

      expect(times, isNotEmpty);
      for (var i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isTrue);
      }
      for (final t in times) {
        expect(t.isAfter(now), isTrue);
      }
    });

    test('offset shifts every reminder by exactly that amount', () {
      final withOffset = prayerReminderTimes(
        latitude: lat,
        longitude: lng,
        method: 'muslim_world_league',
        offsetMinutes: 10,
        now: now,
        days: 2,
      );
      final withoutOffset = prayerReminderTimes(
        latitude: lat,
        longitude: lng,
        method: 'muslim_world_league',
        offsetMinutes: 0,
        now: now,
        days: 2,
      );

      expect(withOffset.length, withoutOffset.length);
      for (var i = 0; i < withOffset.length; i++) {
        expect(
          withOffset[i].difference(withoutOffset[i]),
          const Duration(minutes: 10),
        );
      }
    });

    test('drops prayers already past within the first day', () {
      // Late evening: only Isha (+offset) should remain from day one.
      final lateNow = DateTime(2025, 6, 15, 23, 0);
      final times = prayerReminderTimes(
        latitude: lat,
        longitude: lng,
        method: 'muslim_world_league',
        offsetMinutes: 10,
        now: lateNow,
        days: 2,
      );

      // Day one has at most the isha reminder left; day two adds 5 more.
      expect(times.length, lessThanOrEqualTo(6));
      expect(times.first.day, anyOf(lateNow.day, lateNow.day + 1));
    });

    test('produces five reminders per full day', () {
      final times = prayerReminderTimes(
        latitude: lat,
        longitude: lng,
        method: 'muslim_world_league',
        offsetMinutes: 10,
        now: DateTime(2025, 6, 15, 0, 30),
        days: 1,
      );

      expect(times.length, 5);
    });
  });
}
