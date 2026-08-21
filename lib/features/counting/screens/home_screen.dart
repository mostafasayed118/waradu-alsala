import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/features/settings/settings_provider.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/core/theme/app_text_styles.dart';
import 'package:salawat_app/core/utils/breakpoints.dart';
import 'package:salawat_app/shared/widgets/max_width_box.dart';
import 'package:salawat_app/domain/services/stats_calculator.dart';
import 'package:salawat_app/shared/widgets/gold_divider.dart';
import 'package:salawat_app/shared/widgets/celebration_burst.dart';
import 'package:salawat_app/shared/widgets/islamic_pattern.dart';
import 'package:salawat_app/shared/widgets/mihrab_arch.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _popController;
  late Animation<double> _popAnimation;

  bool _immersive = false;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Brief count pop on each increment.
    _popController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _popAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _popController.dispose();
    if (_immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _enterImmersive() {
    setState(() => _immersive = true);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitImmersive() {
    setState(() => _immersive = false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  Future<void> _onCountTap() async {
    final counters = context.read<CountersProvider>();
    final settings = context.read<SettingsProvider>().settings;
    if (settings.vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
    if (settings.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    final before = counters.activeCounter.currentCount;
    final target = counters.activeCounter.dailyTarget;
    await counters.increment();
    _popController.forward(from: 0).then((_) => _popController.reverse());
    if (target > 0 &&
        before < target &&
        counters.activeCounter.currentCount >= target) {
      await counters.notifyDailyTargetReached();
      if (mounted) setState(() => _celebrating = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (!_celebrating) return body;
    return Stack(
      children: [
        body,
        Positioned.fill(
          child: CelebrationBurst(
            onDone: () {
              if (mounted) setState(() => _celebrating = false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = Breakpoints.isCompact(width) ? 16.0 : 24.0;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: _immersive
          ? _buildImmersiveBody(context)
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(hPad),
                child: MaxWidthBox(
                  maxWidth: Breakpoints.homeMaxWidth,
                  child: Column(
                    children: [
                      // Bismillah band
                      Text(S.of(context).bismillah,
                          style: AppTextStyles.bismillah(context),
                          textAlign: TextAlign.center),
                      const GoldHairlineDivider(),
                      const SizedBox(height: 8),

                      // Counter switcher (medallion chips)
                      const _CounterSwitcher(),
                      const SizedBox(height: 24),

                      // Counter card (centerpiece) with mihrab arch + pattern
                      _CounterCard(popAnimation: _popAnimation),
                      const SizedBox(height: 32),

                      // Tap-to-count button
                      GestureDetector(
                        onTapDown: _onTapDown,
                        onTapUp: _onTapUp,
                        onTapCancel: _onTapCancel,
                        onTap: _onCountTap,
                        child: AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, c) => Transform.scale(
                            scale: _scaleAnimation.value,
                            child: c,
                          ),
                          child: const _CountButtonFace(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Undo / Reset outlined gold text-buttons — Wrap prevents overflow at 320dp
                      const _UndoResetRow(),
                      const SizedBox(height: 8),

                      TextButton.icon(
                        onPressed: _enterImmersive,
                        icon: Icon(Icons.fullscreen,
                            color:
                                Theme.of(context).colorScheme.secondary),
                        label: Text(S.of(context).fullscreen,
                            style: TextStyle(
                              fontFamily: 'ReemKufi',
                              color:
                                  Theme.of(context).colorScheme.secondary,
                            )),
                      ),
                      const SizedBox(height: 24),

                      const _LastUsedText(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Full-screen count surface: the whole body is the tap target.
  Widget _buildImmersiveBody(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onCountTap,
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
                        onPressed: _exitImmersive,
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
                              animation: _popAnimation,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('${counter.currentCount}',
                                    style: AppTextStyles.kufiNumber(context)),
                              ),
                              builder: (context, child) => Transform.scale(
                                scale: _popAnimation.value,
                                child: child,
                              ),
                            ),
                            if (target > 0) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 240,
                                child: _SegmentedProgress(
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
                              animation: _scaleAnimation,
                              builder: (context, c) => Transform.scale(
                                scale: _scaleAnimation.value,
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

class _CounterSwitcher extends StatelessWidget {
  const _CounterSwitcher();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Consumer<CountersProvider>(
        builder: (context, counters, _) {
          final active = counters.activeCounter;
          return ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final c in counters.counters)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _MedallionChip(
                    label: c.name,
                    selected: c.id == active.id,
                    onSelected: (_) => counters.setActive(c.id),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(S.of(context).add),
                  onPressed: () =>
                      showAddCounterDialog(context, context.read<CountersProvider>()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({required this.popAnimation});

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
                      _SegmentedProgress(
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

class _CountButtonFace extends StatelessWidget {
  const _CountButtonFace();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(S.of(context).tapToCount,
          textAlign: TextAlign.center,
          style: AppTextStyles.uiLabel(context)),
    );
  }
}

class _UndoResetRow extends StatelessWidget {
  const _UndoResetRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Selector<CountersProvider, bool>(
          selector: (_, counters) => counters.canUndo,
          builder: (context, canUndo, _) => TextButton.icon(
            onPressed: canUndo
                ? () async {
                    final counters = context.read<CountersProvider>();
                    if (context
                        .read<SettingsProvider>()
                        .settings
                        .vibrationEnabled) {
                      HapticFeedback.selectionClick();
                    }
                    await counters.undo();
                  }
                : null,
            icon: const Icon(Icons.undo),
            label: Text(S.of(context).undo),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.secondary,
              side: BorderSide(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () =>
              showResetConfirmation(context, context.read<CountersProvider>()),
          icon: const Icon(Icons.refresh),
          label: Text(S.of(context).reset),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.secondary,
            side: BorderSide(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
      ],
    );
  }
}

class _LastUsedText extends StatelessWidget {
  const _LastUsedText();

  @override
  Widget build(BuildContext context) {
    return Selector<CountersProvider, DateTime>(
      selector: (_, counters) => counters.activeCounter.lastUsedAt,
      builder: (context, lastUsedAt, _) => Text(
        S.of(context).lastUsed(DateFormat('dd/MM/yyyy HH:mm').format(lastUsedAt)),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
      ),
    );
  }
}

void showResetConfirmation(BuildContext context, CountersProvider counters) {
  final s = S.of(context);
  var includeTotal = false;
  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(s.resetCounterTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.resetConfirmBody),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: Text(s.resetAlsoTotal),
              value: includeTotal,
              onChanged: (value) {
                setDialogState(() {
                  includeTotal = value ?? false;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () async {
              await counters.reset(includeTotal: includeTotal);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(s.confirm, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ),
  );
}

void showAddCounterDialog(BuildContext context, CountersProvider counters) {
  final s = S.of(context);
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(s.addCounterTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: s.dhikrNameLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(s.cancel),
        ),
        TextButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              await counters.addCounter(name);
            }
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
          },
          child: Text(s.add),
        ),
      ],
    ),
  );
}

class _MedallionChip extends StatelessWidget {
  const _MedallionChip(
      {required this.label, required this.selected, required this.onSelected});
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.secondary;
    final primary = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontFamily: 'ReemKufi',
              color: selected ? Colors.white : gold)),
      selected: selected,
      onSelected: onSelected,
      selectedColor: primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(color: gold, width: selected ? 2 : 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({required this.count, required this.target});
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


