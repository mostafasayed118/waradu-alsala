import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/features/settings/settings_provider.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/features/counting/screens/dialogs/reset_confirmation_dialog.dart';

class UndoResetRow extends StatelessWidget {
  const UndoResetRow({super.key});

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
