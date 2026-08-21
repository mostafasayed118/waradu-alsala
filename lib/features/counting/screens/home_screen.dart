import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/features/settings/settings_provider.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/core/theme/app_text_styles.dart';
import 'package:salawat_app/core/utils/breakpoints.dart';
import 'package:salawat_app/shared/widgets/max_width_box.dart';
import 'package:salawat_app/shared/widgets/gold_divider.dart';
import 'package:salawat_app/shared/widgets/celebration_burst.dart';
import 'package:salawat_app/features/counting/screens/widgets/counter_switcher.dart';
import 'package:salawat_app/features/counting/screens/widgets/counter_card.dart';
import 'package:salawat_app/features/counting/screens/widgets/count_button.dart';
import 'package:salawat_app/features/counting/screens/widgets/immersive_count_view.dart';
import 'package:salawat_app/features/counting/screens/widgets/undo_reset_row.dart';
import 'package:salawat_app/features/counting/screens/widgets/last_used_text.dart';

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
          ? ImmersiveCountView(
              popAnimation: _popAnimation,
              scaleAnimation: _scaleAnimation,
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onCountTap: _onCountTap,
              onExit: _exitImmersive,
            )
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
                      const CounterSwitcher(),
                      const SizedBox(height: 24),

                      // Counter card (centerpiece) with mihrab arch + pattern
                      CounterCard(popAnimation: _popAnimation),
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
                          child: const CountButtonFace(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Undo / Reset outlined gold text-buttons — Wrap prevents overflow at 320dp
                      const UndoResetRow(),
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

                      const LastUsedText(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
