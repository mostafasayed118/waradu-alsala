import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatsChart extends StatelessWidget {
  const StatsChart({super.key, required this.counts});

  final List<int> counts;

  @override
  Widget build(BuildContext context) {
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
                      width: counts.length >= 30 ? 5 : 14,
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
}
