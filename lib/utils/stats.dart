import 'package:intl/intl.dart';

/// Formats a date as a stable daily key (yyyy-MM-dd) used for history storage.
String dailyKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

/// Returns counts for the last [days] days, oldest first, with today's live
/// [currentCount] as the final element.
List<int> lastDaysCounts({
  required Map<String, int> history,
  required int currentCount,
  required int days,
  required DateTime today,
}) {
  final counts = <int>[];
  for (var offset = days - 1; offset >= 1; offset--) {
    final date = today.subtract(Duration(days: offset));
    counts.add(history[dailyKey(date)] ?? 0);
  }
  counts.add(currentCount);
  return counts;
}

/// Consecutive days hitting the target, ending today (today counts only once
/// it has reached the target; otherwise the run ends at yesterday).
int currentStreak({
  required Map<String, int> history,
  required int currentCount,
  required int dailyTarget,
  required DateTime today,
}) {
  if (dailyTarget <= 0) return 0;

  var streak = 0;
  if (currentCount >= dailyTarget) {
    streak = 1;
  }

  var day = DateTime(today.year, today.month, today.day - 1);
  while (true) {
    final count = history[dailyKey(day)] ?? 0;
    if (count < dailyTarget) break;
    streak++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return streak;
}

/// Longest run of target-met days in history, plus today if already reached.
int longestStreak({
  required Map<String, int> history,
  required int currentCount,
  required int dailyTarget,
  required DateTime today,
}) {
  if (dailyTarget <= 0) return 0;

  final metDays = <DateTime>[];
  history.forEach((key, count) {
    if (count >= dailyTarget) {
      metDays.add(_parseDay(key));
    }
  });
  if (currentCount >= dailyTarget) {
    metDays.add(DateTime(today.year, today.month, today.day));
  }
  metDays.sort();

  var longest = 0;
  var run = 0;
  DateTime? previous;
  for (final day in metDays) {
    if (previous != null && _isNextDay(previous, day)) {
      run++;
    } else {
      run = 1;
    }
    if (run > longest) longest = run;
    previous = day;
  }
  return longest;
}

DateTime _parseDay(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

bool _isNextDay(DateTime a, DateTime b) {
  final next = DateTime(a.year, a.month, a.day + 1);
  return next.year == b.year && next.month == b.month && next.day == b.day;
}

