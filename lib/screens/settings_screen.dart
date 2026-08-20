import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/adhkar_counter.dart';
import '../providers/counters_provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';
import '../utils/stats.dart';
import '../widgets/gold_divider.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CountersProvider, SettingsProvider>(
      builder: (context, counters, settings, child) {
        final counter = counters.activeCounter;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Active counter section
            _buildSectionTitle(context, 'العداد الحالي'),
            ListTile(
              leading: _medallionIcon(context, Icons.edit),
              title: const Text('الاسم'),
              subtitle: Text(counter.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showRenameDialog(context, counters),
            ),
            ListTile(
              leading: _medallionIcon(context, Icons.flag),
              title: const Text('الهدف اليومي'),
              subtitle: Text(
                counter.dailyTarget > 0
                    ? '${counter.dailyTarget} مرة'
                    : 'غير محدد',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDailyTargetDialog(context, counters),
            ),
            SwitchListTile(
              secondary: _medallionIcon(context, Icons.notifications_active),
              title: const Text('التذكيرات'),
              subtitle: const Text('استلام تذكيرات لهذا الذكر'),
              value: counter.remindersEnabled,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) async {
                final enabled =
                    await counters.setRemindersEnabled(counter.id, value);
                if (value && !enabled && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لم يتم منح إذن الإشعارات'),
                    ),
                  );
                }
              },
            ),

            if (counter.remindersEnabled) ...[
              ListTile(
                title: const Text('نوع التذكير'),
                subtitle: Text(
                  counter.reminderType == ReminderType.interval
                      ? 'تذكير متكرر كل مدة محددة'
                      : 'تذكير في أوقات يومية',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showReminderTypeDialog(context, counters),
              ),
              if (counter.reminderType == ReminderType.interval)
                ListTile(
                  title: const Text('فاصل التذكير'),
                  subtitle:
                      Text(_getIntervalText(counter.reminderIntervalMinutes)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showIntervalDialog(context, counters),
                ),
              if (counter.reminderType == ReminderType.daily)
                ListTile(
                  title: const Text('أوقات التذكير اليومية'),
                  subtitle: Text(
                    counter.dailyReminderTimes.isEmpty
                        ? 'لم يتم تحديد أوقات'
                        : '${counter.dailyReminderTimes.length} أوقات محددة',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDailyTimesDialog(context, counters),
                ),
            ],
            if (counters.counters.length > 1)
              ListTile(
                leading: _medallionIcon(context, Icons.delete,
                    iconColor: Colors.red),
                title: const Text(
                  'حذف العداد',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _showDeleteDialog(context, counters),
              ),

            // Vibration section
            _buildSectionTitle(context, 'الاستجابة'),
            SwitchListTile(
              secondary: _medallionIcon(context, Icons.vibration),
              title: const Text('الاهتزاز'),
              subtitle: const Text('اهتزاز خفيف عند الضغط على زر العدد'),
              value: settings.settings.vibrationEnabled,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) async {
                await settings.toggleVibration(value);
              },
            ),

            // Appearance section
            _buildSectionTitle(context, 'المظهر'),
            SwitchListTile(
              secondary: _medallionIcon(context, Icons.dark_mode),
              title: const Text('الوضع الداكن'),
              subtitle: const Text('استخدام ألوان داكنة للتطبيق'),
              value: settings.settings.isDarkMode,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) async {
                await settings.toggleDarkMode(value);
              },
            ),

            // Backup section
            _buildSectionTitle(context, AppStrings.backupSectionTitle),
            ListTile(
              leading: _medallionIcon(context, Icons.ios_share),
              title: const Text(AppStrings.exportData),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showExportSheet(context),
            ),
            ListTile(
              leading: _medallionIcon(context, Icons.restore),
              title: const Text(AppStrings.restoreBackup),
              onTap: () => _showRestoreFlow(context),
            ),

            // About — pushed as a full screen, not a shell tab
            ListTile(
              leading: _medallionIcon(context, Icons.info),
              title: const Text('حول التطبيق'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text(AppStrings.exportJsonOption),
              onTap: () {
                Navigator.pop(sheetContext);
                _exportData(context, isCsv: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text(AppStrings.exportCsvOption),
              onTap: () {
                Navigator.pop(sheetContext);
                _exportData(context, isCsv: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, {required bool isCsv}) async {
    final backup = context.read<BackupService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final content =
          isCsv ? await backup.buildCsv() : await backup.buildJsonBackup();
      final dir = await getTemporaryDirectory();
      final name = 'zikr-backup-${dailyKey(DateTime.now())}.${isCsv ? 'csv' : 'json'}';
      final file = File('${dir.path}/$name')..writeAsStringSync(content);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: isCsv ? 'text/csv' : 'application/json')],
      );
      unawaited(file.delete());
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.errorExportFailed)),
      );
    }
  }

  Future<void> _showRestoreFlow(BuildContext context) async {
    final backup = context.read<BackupService>();
    final counters = context.read<CountersProvider>();
    final settings = context.read<SettingsProvider>();
    final notifications = context.read<NotificationService>();
    final messenger = ScaffoldMessenger.of(context);

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final BackupData data;
    try {
      data = backup.parseJsonBackup(utf8.decode(picked.files.single.bytes!));
    } on BackupException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.backupErrorMessage(e.code))),
      );
      return;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.errorReadFileFailed)),
      );
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.restoreBackup),
        content: const Text(AppStrings.restoreConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'استعادة',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await backup.applyBackup(data);
      await counters.load();
      await settings.load();
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.restoreSuccess)),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.errorRestoreFailed)),
      );
    }
    try {
      await notifications.rescheduleAll(counters.counters);
    } catch (_) {}
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(title, style: AppTextStyles.display(context)),
        const GoldHairlineDivider(indent: 0),
      ],
    );
  }

  Widget _medallionIcon(BuildContext context, IconData icon,
      {Color? iconColor}) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: gold, width: 1.2),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
      ),
      child: Icon(icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary, size: 20),
    );
  }

  String _getIntervalText(int minutes) {
    if (minutes < 60) {
      return 'كل $minutes دقيقة';
    } else if (minutes == 60) {
      return 'كل ساعة';
    } else {
      final hours = minutes ~/ 60;
      return 'كل $hours ساعة';
    }
  }

  void _showRenameDialog(BuildContext context, CountersProvider counters) {
    final counter = counters.activeCounter;
    final controller = TextEditingController(text: counter.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل الاسم'),
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
                await counters.renameCounter(counter.id, name);
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, CountersProvider counters) {
    final counter = counters.activeCounter;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف العداد'),
        content: Text('هل أنت متأكد من حذف "${counter.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await counters.deleteCounter(counter.id);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDailyTargetDialog(BuildContext context, CountersProvider counters) {
    final counter = counters.activeCounter;
    showDialog(
      context: context,
      builder: (dialogContext) => _DailyTargetDialog(
        counters: counters,
        counterId: counter.id,
        initialValue: counter.dailyTarget,
      ),
    );
  }

  void _showReminderTypeDialog(
    BuildContext context,
    CountersProvider counters,
  ) {
    final counter = counters.activeCounter;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نوع التذكير'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ReminderType>(
              title: const Text('تذكير متكرر'),
              subtitle: const Text('كل مدة محددة'),
              value: ReminderType.interval,
              groupValue: counter.reminderType,
              onChanged: (value) async {
                await counters.setReminderType(counter.id, value!);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ReminderType>(
              title: const Text('تذكير يومي'),
              subtitle: const Text('في أوقات محددة يومياً'),
              value: ReminderType.daily,
              groupValue: counter.reminderType,
              onChanged: (value) async {
                await counters.setReminderType(counter.id, value!);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showIntervalDialog(BuildContext context, CountersProvider counters) {
    final counter = counters.activeCounter;
    final intervals = [15, 30, 60, 120, 180, 360, 720];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فاصل التذكير'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: intervals.length,
            itemBuilder: (context, index) {
              final minutes = intervals[index];
              return ListTile(
                title: Text(_getIntervalText(minutes)),
                selected: counter.reminderIntervalMinutes == minutes,
                onTap: () async {
                  await counters.setReminderInterval(counter.id, minutes);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDailyTimesDialog(
    BuildContext context,
    CountersProvider counters,
  ) {
    final counter = counters.activeCounter;
    final times = List<int>.from(counter.dailyReminderTimes);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('أوقات التذكير اليومية'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: times.length,
                    itemBuilder: (context, index) {
                      final time = times[index];
                      final hour = time ~/ 60;
                      final minute = time % 60;
                      return ListTile(
                        title: Text(
                            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              times.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        times.add(picked.hour * 60 + picked.minute);
                        times.sort();
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة وقت'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  await counters.setDailyReminderTimes(counter.id, times);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DailyTargetDialog extends StatefulWidget {
  const _DailyTargetDialog({
    required this.counters,
    required this.counterId,
    required this.initialValue,
  });

  final CountersProvider counters;
  final String counterId;
  final int initialValue;

  @override
  State<_DailyTargetDialog> createState() => _DailyTargetDialogState();
}

class _DailyTargetDialogState extends State<_DailyTargetDialog> {
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
    return AlertDialog(
      title: const Text('الهدف اليومي'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'عدد المرات',
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
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
