import 'package:adhan/adhan.dart';

/// The five daily prayer names in schedule order.
const List<String> prayerNames = [
  'fajr',
  'dhuhr',
  'asr',
  'maghrib',
  'isha',
];

DateTime _prayerTime(PrayerTimes times, String name) => switch (name) {
      'fajr' => times.fajr,
      'dhuhr' => times.dhuhr,
      'asr' => times.asr,
      'maghrib' => times.maghrib,
      _ => times.isha,
    };

CalculationParameters _parameters(String method) {
  final m = CalculationMethod.values.firstWhere(
    (m) => m.name == method,
    orElse: () => CalculationMethod.muslim_world_league,
  );
  return m.getParameters();
}

/// Builds the upcoming explicit reminder instants for a
/// [ReminderType.prayer] counter: each of the five prayers over the next
/// [days] days, shifted by [offsetMinutes], with everything at or before
/// [now] dropped. Times come back sorted ascending.
List<DateTime> prayerReminderTimes({
  required double latitude,
  required double longitude,
  required String method,
  required int offsetMinutes,
  required DateTime now,
  int days = 3,
}) {
  final coordinates = Coordinates(latitude, longitude);
  final parameters = _parameters(method);
  final result = <DateTime>[];

  for (var dayOffset = 0; dayOffset < days; dayOffset++) {
    final date = now.add(Duration(days: dayOffset));
    final times =
        PrayerTimes(coordinates, DateComponents.from(date), parameters);
    for (final name in prayerNames) {
      result.add(_prayerTime(times, name).add(Duration(minutes: offsetMinutes)));
    }
  }

  return result.where((t) => t.isAfter(now)).toList()..sort();
}

