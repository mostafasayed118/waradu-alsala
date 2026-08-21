import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/counters_provider.dart';
import '../utils/app_localizations.dart';
import '../utils/app_text_styles.dart';
import '../utils/breakpoints.dart';
import '../utils/stats.dart';
import '../widgets/gold_divider.dart';
import '../widgets/islamic_pattern.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  /// Marks the two-pane (tablet) layout container so tests can assert on it.
  static const Key twoPaneKey = Key('stats-two-pane');

  /// Chart height for a single-column layout at the given surface width.
  /// The two-pane layout uses [twoPaneChartHeight] instead.
  static double chartHeightFor(double width) {
    if (Breakpoints.isCompact(width)) return 180;
    if (Breakpoints.isMedium(width)) return 220;
    return 260;
  }

  /// Chart height when the chart sits beside the tiles on a tablet.
  static const double twoPaneChartHeight = 320;

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

        final width = MediaQuery.sizeOf(context).width;
        final rangeSelector = SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 7, label: Text(S.of(context).seg7)),
            ButtonSegment(value: 30, label: Text(S.of(context).seg30)),
            ButtonSegment(value: 90, label: Text(S.of(context).seg90)),
          ],
          selected: {_days},
          onSelectionChanged: (selection) {
            setState(() => _days = selection.first);
          },
        );

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Breakpoints.useTwoPane(width)
              ? _buildTwoPane(
                  context: context,
                  rangeSelector: rangeSelector,
                  counts: counts,
                  windowSum: windowSum,
                  totalCount: counter.totalCount,
                  bestDay: bestDay,
                  target: target,
                  current: current,
                  longest: longest,
                )
              : _buildSingleColumn(
                  context: context,
                  rangeSelector: rangeSelector,
                  counts: counts,
                  width: width,
                  windowSum: windowSum,
                  totalCount: counter.totalCount,
                  bestDay: bestDay,
                  target: target,
                  current: current,
                  longest: longest,
                ),
        );
      },
    );
  }

  /// Phone / medium layout: chart stacked above the medallion tiles.
  Widget _buildSingleColumn({
    required BuildContext context,
    required Widget rangeSelector,
    required List<int> counts,
    required double width,
    required int windowSum,
    required int totalCount,
    required int bestDay,
    required int target,
    required int current,
    required int longest,
  }) {
    final s = S.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          rangeSelector,
          const SizedBox(height: 24),
          _chartPane(context, counts, StatsScreen.chartHeightFor(width)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _medallionTile(context, s.windowLabel(_days), windowSum),
              ),
              Expanded(
                child: _medallionTile(context, s.totalAllTime, totalCount),
              ),
              Expanded(
                child: _medallionTile(context, s.bestDay, bestDay),
              ),
            ],
          ),
          if (target > 0) ...[
            const GoldHairlineDivider(),
            Row(
              children: [
                Expanded(
                  child: _medallionTile(context, s.currentStreakLabel, current),
                ),
                Expanded(
                  child: _medallionTile(context, s.longestStreakLabel, longest),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Tablet layout: chart on one side, medallion tiles flowing beside it.
  Widget _buildTwoPane({
    required BuildContext context,
    required Widget rangeSelector,
    required List<int> counts,
    required int windowSum,
    required int totalCount,
    required int bestDay,
    required int target,
    required int current,
    required int longest,
  }) {
    return Column(
      key: StatsScreen.twoPaneKey,
      children: [
        rangeSelector,
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child:
                    _chartPane(context, counts, StatsScreen.twoPaneChartHeight),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: _tilesGrid(
                    context: context,
                    windowSum: windowSum,
                    totalCount: totalCount,
                    bestDay: bestDay,
                    target: target,
                    current: current,
                    longest: longest,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The chart with its faint star-pattern backdrop at a given height.
  Widget _chartPane(BuildContext context, List<int> counts, double height) {
    return Stack(
      children: [
        const Positioned.fill(child: IslamicPattern(opacity: 0.04)),
        SizedBox(height: height, child: _buildChart(context, counts)),
      ],
    );
  }

  /// Tiles laid out as a flowing grid for the two-pane right column.
  Widget _tilesGrid({
    required BuildContext context,
    required int windowSum,
    required int totalCount,
    required int bestDay,
    required int target,
    required int current,
    required int longest,
  }) {
    final s = S.of(context);
    const tileWidth = 160.0;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: tileWidth,
          child: _medallionTile(context, s.windowLabel(_days), windowSum),
        ),
        SizedBox(
          width: tileWidth,
          child: _medallionTile(context, s.totalAllTime, totalCount),
        ),
        SizedBox(
          width: tileWidth,
          child: _medallionTile(context, s.bestDay, bestDay),
        ),
        if (target > 0) ...[
          SizedBox(
            width: tileWidth,
            child: _medallionTile(context, s.currentStreakLabel, current),
          ),
          SizedBox(
            width: tileWidth,
            child: _medallionTile(context, s.longestStreakLabel, longest),
          ),
        ],
      ],
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
                  FlLine(color: gold.withValues(alpha: 0.15), strokeWidth: 1),
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
                      width: _days >= 30 ? 5 : 14,
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

  /// A single stat medallion. Flex-agnostic: callers wrap it in [Expanded]
  /// inside a Row, or in a sized box inside a Wrap.
  Widget _medallionTile(BuildContext context, String label, int value) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text('$value',
              style: AppTextStyles.kufiNumber(context).copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'ReemKufi', fontSize: 12)),
        ],
      ),
    );
  }
}




