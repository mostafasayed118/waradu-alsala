import 'package:flutter/material.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';
import 'gold_divider.dart';
import 'islamic_pattern.dart';

/// A persistent decorative app shell: custom mihrab-arch header band +
/// 3-tab ornamental pill bottom-nav wrapping an IndexedStack so tabs
/// preserve their state when switching.
class DecorativeAppShell extends StatefulWidget {
  const DecorativeAppShell({super.key, required this.screens});

  /// Exactly 3 widgets: Home, Stats, Settings (in that order).
  final List<Widget> screens;

  /// Caps the bottom-nav pill row so tabs stay grouped and centered on
  /// tablets instead of hugging the far edges. A no-op below this width.
  static const double navMaxWidth = 480;

  @override
  State<DecorativeAppShell> createState() => _DecorativeAppShellState();
}

class _DecorativeAppShellState extends State<DecorativeAppShell> {
  int _index = 0;

  static const _tabs = [
    _TabSpec(label: 'الرئيسية', icon: Icons.mosque),
    _TabSpec(label: 'الإحصائيات', icon: Icons.bar_chart),
    _TabSpec(label: 'الإعدادات', icon: Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final isHome = _index == 0;
    return Scaffold(
      body: Column(
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
                  isHome ? AppStrings.appName : _tabs[_index].label,
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
                  _NavPill(
                    label: _tabs[i].label,
                    icon: _tabs[i].icon,
                    selected: i == _index,
                    gold: gold,
                    onTap: () => setState(() => _index = i),
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
  const _TabSpec({required this.label, required this.icon});
  final String label;
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
