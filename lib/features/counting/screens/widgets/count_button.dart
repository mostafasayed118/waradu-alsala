import 'package:flutter/material.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/core/theme/app_text_styles.dart';

class CountButtonFace extends StatelessWidget {
  const CountButtonFace({super.key});

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
