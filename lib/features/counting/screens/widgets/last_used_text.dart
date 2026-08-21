import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';

class LastUsedText extends StatelessWidget {
  const LastUsedText({super.key});

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
