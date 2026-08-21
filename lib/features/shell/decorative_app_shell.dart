import 'package:flutter/material.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/core/l10n/app_strings.dart';
import 'package:salawat_app/core/theme/app_text_styles.dart';
import 'package:salawat_app/shared/widgets/gold_divider.dart';
import 'package:salawat_app/shared/widgets/islamic_pattern.dart';

/// Lets descendant screens (e.g. the adhkar library) switch tabs without
/// touching Navigator: `ShellTabController.of(context)?.notifier.value = 0;`
class ShellTabController extends InheritedWidget {
  const ShellTabController({
    super.key,
    required this.notifier,
    required super.child,
  });

  final ValueNotifier<int> notifier;

  static ShellTabController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellTabController>();

  @override
  bool updateShouldNotify(ShellTabController oldWidget) => false;
}

/// A persistent decorative app shell: custom mihrab-arch header band +
/// 4-tab ornamental pill bottom-nav wrapping an IndexedStack so tabs
/// preserve their state when switching.
class DecorativeAppShell extends StatefulWidget {
  const DecorativeAppShell({super.key, required this.screens});

  /// Exactly 4 widgets: Home, Library, Stats, Settings (in that order).
  final List<Widget> screens;

  /// Caps the bottom-nav pill row so tabs stay grouped and centered on
  /// tablets instead of hugging the far edges. A no-op below this width.
  static const double navMaxWidth = 480;

  @override
  State<DecorativeAppShell> createState() => _DecorativeAppShellState();
}

class _DecorativeAppShellState extends State<DecorativeAppShell> {
  int _index = 0;
  late final ValueNotifier<int> _tabNotifier = ValueNotifier<int>(0);

  static const _tabs = [
    _TabSpec(labelKey: 'homeTab', icon: Icons.mosque),
    _TabSpec(labelKey: 'libraryTab', icon: Icons.menu_book),
    _TabSpec(labelKey: 'statsTab', icon: Icons.bar_chart),
    _TabSpec(labelKey: 'settingsTab', icon: Icons.settings),
  ];

  @override
  void initState() {
    super.initState();
    _tabNotifier.addListener(_onTabNotifierChanged);
  }

  void _onTabNotifierChanged() {
    if (mounted) setState(() => _index = _tabNotifier.value);
  }

  @override
  void dispose() {
    _tabNotifier.removeListener(_onTabNotifierChanged);
    _tabNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHome = _index == 0;
    return Scaffold(
      body: ShellTabController(
        notifier: _tabNotifier,
        child: Column(
          children: [
            _buildHeader(context, isHome),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: widget.screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context, bool isHome) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16, isHome ? 12 : 8, 16, isHome ? 16 : 8,
        ),
        color: Theme.of(context).colorScheme.primary,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Faint 8-point-star pattern behind the header title.
                const SizedBox(
                  height: 48,
                  child: IslamicPattern(opacity: 0.06),
                ),
                Text(
                  isHome
                      ? AppStrings.appName
                      : S.of(context).t(_tabs[_index].labelKey),
                  style: AppTextStyles.display(context).copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const GoldHairlineDivider(indent: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final gold = Theme.of(context).colorScheme.secondary;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: gold, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        // NOTE: deliberately not MaxWidthBox here. MaxWidthBox centers with a
        // plain Center, which expands to fill available height — inside
        // bottomNavigationBar that would claim the whole screen and collapse
        // the body to zero height. heightFactor: 1 sizes to the pill row.
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DecorativeAppShell.navMaxWidth,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavPill(
                      label: S.of(context).t(_tabs[i].labelKey),
                      icon: _tabs[i].icon,
                      selected: i == _index,
                      gold: gold,
                      onTap: () => _tabNotifier.value = i,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({required this.labelKey, required this.icon});
  final String labelKey;
  final IconData icon;
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.gold,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color gold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active tab gets a small gold star node above its label.
            SizedBox(
              height: 8,
              width: 8,
              child: selected
                  ? CustomPaint(painter: _SmallStarPainter(color: gold))
                  : const SizedBox.shrink(),
            ),
            Icon(icon, color: selected ? primary : gold, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'ReemKufi',
                fontSize: 12,
                color: selected ? primary : gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStarPainter extends CustomPainter {
  _SmallStarPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = size.width / 2;
    canvas.drawRect(Rect.fromCircle(center: Offset(r, r), radius: r), paint);
    canvas.save();
    canvas.translate(r, r);
    canvas.rotate(0.785398);
    canvas.drawRect(Rect.fromCircle(center: Offset.zero, radius: r), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SmallStarPainter old) => old.color != color;
}



