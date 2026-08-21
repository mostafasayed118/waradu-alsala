import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/core/theme/app_text_styles.dart';
import 'package:salawat_app/domain/services/stats_calculator.dart';
import 'package:salawat_app/shared/widgets/islamic_pattern.dart';
import 'package:salawat_app/shared/widgets/mihrab_arch.dart';
import 'package:salawat_app/features/counting/screens/widgets/segmented_progress.dart';

class CounterCard extends StatelessWidget {
  const CounterCard({super.key, required this.popAnimation});

  final Animation<double> popAnimation;

  @override
  Widget build(BuildContext context) {
    return Consumer<CountersProvider>(
      builder: (context, counters, _) {
        final counter = counters.activeCounter;
        final target = counter.dailyTarget;
        final s = S.of(context);
        final streak = currentStreak(
          history: counter.history,
          currentCount: counter.currentCount,
          dailyTarget: target,
          today: DateTime.now(),
        );
        return Stack(
          children: [
            const Positioned.fill(
              child: IslamicPattern(opacity: 0.04),
            ),
            MihrabArch(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    Text(counter.name,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display(context)),
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: popAnimation,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('${counter.currentCount}',
                            style: AppTextStyles.kufiNumber(context)),
                      ),
                      builder: (context, child) => Transform.scale(
                        scale: popAnimation.value,
                        child: child,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(s.today,
                        style: AppTextStyles.bodyArabic(context)),
                    const SizedBox(height: 4),
                    Text(s.totalLabel(counter.totalCount),
                        style: AppTextStyles.bodyArabic(context)
                            .copyWith(
                          color:
                              Theme.of(context).colorScheme.secondary,
                        )),
                    if (target > 0) ...[
                      const SizedBox(height: 16),
                      SegmentedProgress(
                        count: counter.currentCount,
                        target: target,
                      ),
                      const SizedBox(height: 8),
                      Text('${counter.currentCount} / $target',
                          style: AppTextStyles.bodyArabic(context)
                              .copyWith(
                            color:
                                Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          )),
                      if (counter.currentCount >= target) ...[
                        const SizedBox(height: 8),
                        const _TargetBadge(),
                      ],
                      const SizedBox(height: 12),
                      _StreakPill(streak: streak),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TargetBadge extends StatelessWidget {
  const _TargetBadge();

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: gold, size: 16),
          const SizedBox(width: 4),
          Text(S.of(context).targetDone,
              style: TextStyle(color: gold, fontFamily: 'ReemKufi')),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: gold, size: 18),
          const SizedBox(width: 4),
          Text(S.of(context).streakDays(streak),
              style: TextStyle(fontFamily: 'ReemKufi', color: gold)),
        ],
      ),
    );
  }
}
