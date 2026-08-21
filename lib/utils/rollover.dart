import '../models/adhkar_counter.dart';
import 'stats.dart';

/// Archives a previous day's count into history and resets the daily count
/// when [counter] was last used before [now]'s day. Returns the counter
/// unchanged when it was already used today.
AdhkarCounter rollOverCounter(AdhkarCounter counter, DateTime now) {
  final last = counter.lastUsedAt;
  if (last.year == now.year &&
      last.month == now.month &&
      last.day == now.day) {
    return counter;
  }
  final history = Map<String, int>.from(counter.history);
  if (counter.currentCount > 0) {
    history[dailyKey(last)] = counter.currentCount;
  }
  return counter.copyWith(
    currentCount: 0,
    history: history,
    lastUsedAt: now,
    lastResetAt: now,
  );
}

