import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/domain/entities/adhkar_counter.dart';
import 'package:salawat_app/domain/services/stats_calculator.dart';

AdhkarCounter _counter({
  int currentCount = 0,
  DateTime? lastUsedAt,
}) {
  return AdhkarCounter(
    id: 'a',
    name: 'A',
    currentCount: currentCount,
    totalCount: 100,
    lastUsedAt: lastUsedAt,
  );
}

void main() {
  final now = DateTime(2025, 6, 15, 10, 30);

  test('same-day usage returns the counter unchanged', () {
    final counter = _counter(currentCount: 7, lastUsedAt: now);

    final rolled = counter.rolledOver(now);

    expect(identical(rolled, counter), isTrue);
  });

  test('previous-day count is archived into history', () {
    final yesterday = now.subtract(const Duration(days: 1));
    final counter = _counter(currentCount: 33, lastUsedAt: yesterday);

    final rolled = counter.rolledOver(now);

    expect(rolled.currentCount, 0);
    expect(rolled.totalCount, 100);
    expect(rolled.history[dailyKey(yesterday)], 33);
    expect(rolled.lastUsedAt.day, now.day);
  });

  test('a zero previous-day count is not archived', () {
    final yesterday = now.subtract(const Duration(days: 1));
    final counter = _counter(lastUsedAt: yesterday);

    final rolled = counter.rolledOver(now);

    expect(rolled.currentCount, 0);
    expect(rolled.history, isEmpty);
  });
}
