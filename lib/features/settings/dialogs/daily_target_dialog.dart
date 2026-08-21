import 'package:flutter/material.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';

void showDailyTargetDialog(BuildContext context, CountersProvider counters) {
  final counter = counters.activeCounter;
  showDialog(
    context: context,
    builder: (dialogContext) => DailyTargetDialog(
      counters: counters,
      counterId: counter.id,
      initialValue: counter.dailyTarget,
    ),
  );
}

class DailyTargetDialog extends StatefulWidget {
  const DailyTargetDialog({
    super.key,
    required this.counters,
    required this.counterId,
    required this.initialValue,
  });

  final CountersProvider counters;
  final String counterId;
  final int initialValue;

  @override
  State<DailyTargetDialog> createState() => _DailyTargetDialogState();
}

class _DailyTargetDialogState extends State<DailyTargetDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue > 0 ? '${widget.initialValue}' : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = int.tryParse(_controller.text.trim()) ?? 0;
    await widget.counters.setDailyTarget(widget.counterId, value < 0 ? 0 : value);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s.dailyTargetLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: s.timesCountLabel,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [33, 100, 500, 1000]
                .map(
                  (value) => ActionChip(
                    label: Text('$value'),
                    onPressed: () => _controller.text = '$value',
                  ),
                )
                .toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(s.save),
        ),
      ],
    );
  }
}
