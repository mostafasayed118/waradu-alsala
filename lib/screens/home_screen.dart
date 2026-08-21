import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/counters_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_text_styles.dart';
import '../utils/breakpoints.dart';
import '../utils/stats.dart';
import '../widgets/gold_divider.dart';
import '../widgets/islamic_pattern.dart';
import '../widgets/mihrab_arch.dart';

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
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return Consumer2<CountersProvider, SettingsProvider>(
      builder: (context, counters, settings, child) {
        final counter = counters.activeCounter;
        final target = counter.dailyTarget;
        final streak = currentStreak(
          history: counter.history,
          currentCount: counter.currentCount,
          dailyTarget: target,
          today: DateTime.now(),
        );
        final width = MediaQuery.sizeOf(context).width;
        final hPad = Breakpoints.isCompact(width) ? 16.0 : 24.0;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(hPad),
              child: MaxWidthBox(
                maxWidth: Breakpoints.homeMaxWidth,
                child: Column(
                children: [
                  // Bismillah band
                  Text('بسم الله الرحمن الرحيم',
                      style: AppTextStyles.bismillah(context),
                      textAlign: TextAlign.center),
                  const GoldHairlineDivider(),
                  const SizedBox(height: 8),

                  // Counter switcher (medallion chips)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final c in counters.counters)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _MedallionChip(
                              label: c.name,
                              selected: c.id == counter.id,
                              onSelected: (_) => counters.setActive(c.id),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ActionChip(
                            avatar: const Icon(Icons.add, size: 18),
                            label: const Text('إضافة'),
                            onPressed: () =>
                                _showAddCounterDialog(context, counters),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Counter card (centerpiece) with mihrab arch + pattern
                  Stack(
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
                                animation: _popAnimation,
                                builder: (context, c) => Transform.scale(
                                  scale: _popAnimation.value,
                                  child: c,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('${counter.currentCount}',
                                      style: AppTextStyles.kufiNumber(context)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('اليوم',
                                  style: AppTextStyles.bodyArabic(context)),
                              const SizedBox(height: 4),
                              Text('الإجمالي: ${counter.totalCount}',
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
                                  _TargetBadge(),
                                ],
                                const SizedBox(height: 12),
                                _StreakPill(streak: streak),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Tap-to-count button
                  GestureDetector(
                    onTapDown: _onTapDown,
                    onTapUp: _onTapUp,
                    onTapCancel: _onTapCancel,
                    onTap: () async {
                      if (settings.settings.vibrationEnabled) {
                        HapticFeedback.lightImpact();
                      }
                      final before = counter.currentCount;
                      await counters.increment();
                      _popController.forward(from: 0).then(
                          (_) => _popController.reverse());
                      if (target > 0 &&
                          before < target &&
                          counters.activeCounter.currentCount >= target) {
                        await counters.notifyDailyTargetReached();
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, c) => Transform.scale(
                        scale: _scaleAnimation.value,
                        child: c,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.8),
                          ]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text('اضغط للعد',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.uiLabel(context)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Undo / Reset outlined gold text-buttons — Wrap prevents overflow at 320dp
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: counters.canUndo
                            ? () async {
                                if (settings.settings.vibrationEnabled) {
                                  HapticFeedback.selectionClick();
                                }
                                await counters.undo();
                              }
                            : null,
                        icon: const Icon(Icons.undo),
                        label: const Text('تراجع'),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          side: BorderSide(
                              color:
                                  Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _showResetConfirmation(context, counters),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة تعيين'),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          side: BorderSide(
                              color:
                                  Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'آخر استخدام: ${DateFormat('dd/MM/yyyy HH:mm').format(counter.lastUsedAt)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  void _showResetConfirmation(BuildContext context, CountersProvider counters) {
    var includeTotal = false;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('إعادة تعيين العداد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('هل أنت متأكد من إعادة تعيين العداد؟'),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('إعادة تعيين العدد التراكمي أيضاً'),
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
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                await counters.reset(includeTotal: includeTotal);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('تأكيد', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCounterDialog(BuildContext context, CountersProvider counters) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة عداد'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'اسم الذكر'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
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
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
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
                color: i < filled ? gold : gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(5),
                boxShadow: done && i < filled
                    ? [
                        BoxShadow(
                            color: gold.withOpacity(0.4), blurRadius: 4)
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
  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: gold, size: 16),
          const SizedBox(width: 4),
          Text('تم الهدف',
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
        border: Border.all(color: gold.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: gold, size: 18),
          const SizedBox(width: 4),
          Text('$streak يوم متتالي',
              style: TextStyle(fontFamily: 'ReemKufi', color: gold)),
        ],
      ),
    );
  }
}
