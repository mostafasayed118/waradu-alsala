import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/core/theme/app_text_styles.dart';
import 'package:salawat_app/shared/widgets/islamic_pattern.dart';
import 'package:salawat_app/features/counting/screens/widgets/segmented_progress.dart';

class ImmersiveCountView extends StatelessWidget {
  const ImmersiveCountView({
    super.key,
    required this.popAnimation,
    required this.scaleAnimation,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.onCountTap,
    required this.onExit,
  });

  final Animation<double> popAnimation;
  final Animation<double> scaleAnimation;
  final GestureTapDownCallback onTapDown;
  final GestureTapUpCallback onTapUp;
  final GestureTapCancelCallback onTapCancel;
  final Future<void> Function() onCountTap;
  final VoidCallback onExit;

  /// Full-screen count surface: the whole body is the tap target.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      onTap: onCountTap,
      child: Consumer<CountersProvider>(
        builder: (context, counters, _) {
          final counter = counters.activeCounter;
          final target = counter.dailyTarget;
          return Stack(
            children: [
              const Positioned.fill(child: IslamicPattern(opacity: 0.04)),
              SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: IconButton(
                        tooltip: S.of(context).exitFullscreen,
                        onPressed: onExit,
                        icon: Icon(Icons.close,
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                            if (target > 0) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 240,
                                child: SegmentedProgress(
                                  count: counter.currentCount,
                                  target: target,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('${counter.currentCount} / $target',
                                  style: AppTextStyles.bodyArabic(context)
                                      .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ],
                            const SizedBox(height: 24),
                            AnimatedBuilder(
                              animation: scaleAnimation,
                              builder: (context, c) => Transform.scale(
                                scale: scaleAnimation.value,
                                child: c,
                              ),
                              child: Text(S.of(context).tapAnywhereToCount,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.uiLabel(context)
                                      .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
