import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/features/counting/screens/dialogs/add_counter_dialog.dart';

class CounterSwitcher extends StatelessWidget {
  const CounterSwitcher({super.key});

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
