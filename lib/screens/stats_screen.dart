import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/counters_provider.dart';
import '../utils/stats.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإحصائيات'),
      ),
      body: Consumer<CountersProvider>(
        builder: (context, counters, child) {
          final counter = counters.activeCounter;
          final counts = lastDaysCounts(
            history: counter.history,
            currentCount: counter.currentCount,
            days: _days,
            today: DateTime.now(),
          );
          final windowSum = counts.fold<int>(0, (sum, c) => sum + c);
          final bestDay = counts.fold<int>(0, (best, c) => c > best ? c : best);
          final target = counter.dailyTarget;
          final current = currentStreak(
            history: counter.history,
            currentCount: counter.currentCount,
            dailyTarget: target,
            today: DateTime.now(),
          );
          final longest = longestStreak(
            history: counter.history,
            currentCount: counter.currentCount,
            dailyTarget: target,
            today: DateTime.now(),
          );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('٧ أيام')),
                    ButtonSegment(value: 30, label: Text('٣٠ يومًا')),
                  ],
                  selected: {_days},
                  onSelectionChanged: (selection) {
                    setState(() => _days = selection.first);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: _buildChart(context, counts),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _totalTile(
                      context,
                      _days == 7 ? 'آخر ٧ أيام' : 'آخر ٣٠ يومًا',
                      windowSum,
                    ),
                    _totalTile(context, 'الإجمالي الكلي', counter.totalCount),
                    _totalTile(context, 'أفضل يوم', bestDay),
                  ],
                ),
                if (target > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _totalTile(context, 'السلسلة الحالية', current),
                      _totalTile(context, 'أطول سلسلة', longest),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<int> counts) {
    final maxCount = counts.fold<int>(0, (m, c) => c > m ? c : m);
    final maxY = maxCount < 1 ? 5.0 : (maxCount * 1.2).ceilToDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < counts.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[i].toDouble(),
                  color: Theme.of(context).colorScheme.primary,
                  width: _days == 30 ? 5 : 14,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _totalTile(BuildContext context, String label, int value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
