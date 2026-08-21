import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/domain/services/stats_calculator.dart';

void main() {
  test('dailyKey formats as yyyy-MM-dd', () {
    expect(dailyKey(DateTime(2025, 1, 5)), '2025-01-05');
  });

  test('lastDaysCounts returns oldest first with today last', () {
    final today = DateTime(2025, 1, 10);
    final counts = lastDaysCounts(
      history: {'2025-01-08': 3, '2025-01-09': 5},
      currentCount: 7,
      days: 4,
      today: today,
    );

    expect(counts, [0, 3, 5, 7]);
  });

  test('lastDaysCounts fills missing days with zero', () {
    final today = DateTime(2025, 1, 3);
    final counts = lastDaysCounts(
      history: const {},
      currentCount: 2,
      days: 3,
      today: today,
    );

    expect(counts, [0, 0, 2]);
  });

  group('currentStreak', () {
    final today = DateTime(2025, 1, 10);

    test('returns 0 when no target is set', () {
      expect(
        currentStreak(
          history: const {},
          currentCount: 5,
          dailyTarget: 0,
          today: today,
        ),
        0,
      );
    });

    test('counts today when reached', () {
      final history = {'2025-01-07': 10, '2025-01-08': 10, '2025-01-09': 3};
      expect(
        currentStreak(
          history: history,
          currentCount: 10,
          dailyTarget: 5,
          today: today,
        ),
        1,
      );
    });

    test('ends at yesterday when today is not reached', () {
      final history = {'2025-01-08': 10, '2025-01-09': 10};
      expect(
        currentStreak(
          history: history,
          currentCount: 2,
          dailyTarget: 5,
          today: today,
        ),
        2,
      );
    });

    test('chains through consecutive met days', () {
      final history = {'2025-01-07': 10, '2025-01-08': 10, '2025-01-09': 10};
      expect(
        currentStreak(
          history: history,
          currentCount: 10,
          dailyTarget: 5,
          today: today,
        ),
        4,
      );
    });
  });

  group('longestStreak', () {
    final today = DateTime(2025, 1, 10);

    test('returns 0 when no target is set', () {
      expect(
        longestStreak(
          history: const {},
          currentCount: 5,
          dailyTarget: 0,
          today: today,
        ),
        0,
      );
    });

    test('finds the best run across scattered days', () {
      final history = {
        '2025-01-01': 10,
        '2025-01-02': 10,
        '2025-01-05': 10,
        '2025-01-06': 10,
        '2025-01-07': 10,
      };
      expect(
        longestStreak(
          history: history,
          currentCount: 0,
          dailyTarget: 5,
          today: today,
        ),
        3,
      );
    });

    test('includes today when reached', () {
      final history = {'2025-01-08': 10, '2025-01-09': 10};
      expect(
        longestStreak(
          history: history,
          currentCount: 10,
          dailyTarget: 5,
          today: today,
        ),
        3,
      );
    });
  });
}
