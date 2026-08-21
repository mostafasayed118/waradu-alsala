import 'package:flutter/material.dart';

class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({super.key, required this.count, required this.target});
  final int count;
  final int target;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.secondary;
    final segments = target <= 20 ? target : 20;
    final filled = (count / target * segments).floor().clamp(0, segments);
    final done = count >= target;
    return Row(
      children: [
        for (var i = 0; i < segments; i++)
          Expanded(
            child: Container(
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i < filled ? gold : gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
                boxShadow: done && i < filled
                    ? [
                        BoxShadow(
                            color: gold.withValues(alpha: 0.4), blurRadius: 4)
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
