import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/adhkar_library.dart';
import '../models/dhikr_item.dart';
import '../providers/counters_provider.dart';
import '../utils/app_localizations.dart';
import '../utils/app_text_styles.dart';
import '../utils/breakpoints.dart';
import '../widgets/decorative_app_shell.dart';
import '../widgets/gold_divider.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = Breakpoints.isCompact(width) ? 16.0 : 24.0;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hPad),
        child: MaxWidthBox(
          maxWidth: Breakpoints.homeMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final category in DhikrCategory.values) ...[
                _SectionHeader(category: category),
                const GoldHairlineDivider(),
                const SizedBox(height: 8),
                for (final item in adhkarLibrary)
                  if (item.category == category)
                    _DhikrCard(item: item),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _categoryTitle(S s, DhikrCategory category) => switch (category) {
      DhikrCategory.morning => s.morningSection,
      DhikrCategory.evening => s.eveningSection,
      DhikrCategory.general => s.generalSection,
    };

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.category});

  final DhikrCategory category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(_categoryTitle(S.of(context), category),
          style: AppTextStyles.display(context)),
    );
  }
}

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({required this.item});

  final DhikrItem item;

  Future<void> _countThis(BuildContext context) async {
    final counters = context.read<CountersProvider>();
    final shell = ShellTabController.of(context);
    await counters.ensureCounterNamed(item.name);
    shell?.notifier.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _countThis(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: gold.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.name,
                        style: AppTextStyles.bodyArabic(context)
                            .copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Icon(Icons.touch_app, size: 18, color: gold),
                ],
              ),
              const SizedBox(height: 6),
              Text(item.text,
                  style: AppTextStyles.bismillah(context).copyWith(
                    fontSize:
                        AppTextStyles.bismillah(context).fontSize! * 0.82,
                    fontWeight: FontWeight.w400,
                    height: 1.9,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  )),
              if (item.recommendedCount != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gold.withValues(alpha: 0.5)),
                    ),
                    child: Text('× ${item.recommendedCount}',
                        style: TextStyle(
                          fontFamily: 'ReemKufi',
                          fontSize: 13,
                          color: gold,
                        )),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

