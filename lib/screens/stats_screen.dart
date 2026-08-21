import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/counters_provider.dart';
import '../utils/app_text_styles.dart';
import '../utils/breakpoints.dart';
import '../utils/stats.dart';
import '../widgets/gold_divider.dart';
import '../widgets/islamic_pattern.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    return Consumer<CountersProvider>(
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
          child: SingleChildScrollView(
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
                Stack(
                  children: [
                    const Positioned.fill(
                      child: IslamicPattern(opacity: 0.04),
                    ),
                    SizedBox(
                        height: 220, child: _buildChart(context, counts)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _medallionTile(context,
                        _days == 7 ? 'آخر ٧ أيام' : 'آخر ٣٠ يومًا', windowSum),
                    _medallionTile(
                        context, 'الإجمالي الكلي', counter.totalCount),
                    _medallionTile(context, 'أفضل يوم', bestDay),
                  ],
                ),
                if (target > 0) ...[
                  const GoldHairlineDivider(),
                  Row(
                    children: [
                      _medallionTile(context, 'السلسلة الحالية', current),
                      _medallionTile(context, 'أطول سلسلة', longest),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChart(BuildContext context, List<int> counts) {
    final maxCount = counts.fold<int>(0, (m, c) => c > m ? c : m);
    final maxY = maxCount < 1 ? 5.0 : (maxCount * 1.2).ceilToDouble();
    final gold = Theme.of(context).colorScheme.secondary;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: gold, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: BarChart(
          BarChartData(
            maxY: maxY,
            barTouchData: BarTouchData(enabled: false),
            titlesData: const FlTitlesData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: gold.withOpacity(0.15), strokeWidth: 1),
            ),
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
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _medallionTile(BuildContext context, String label, int value) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gold.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: AppTextStyles.kufiNumber(context)
                    .copyWith(fontSize: 28)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'ReemKufi', fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
