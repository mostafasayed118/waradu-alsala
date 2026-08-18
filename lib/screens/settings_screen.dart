import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Notifications Section
              _buildSectionTitle(context, 'الإشعارات'),
              SwitchListTile(
                title: const Text('تفعيل الإشعارات'),
                subtitle: const Text('استلام تذكيرات بالصلاة على النبي ﷺ'),
                value: settings.settings.notificationsEnabled,
                onChanged: (value) async {
                  await settings.toggleNotifications(value);
                },
              ),
              
              if (settings.settings.notificationsEnabled) ...[
                // Reminder Type
                ListTile(
                  title: const Text('نوع التذكير'),
                  subtitle: Text(
                    settings.settings.reminderType == ReminderType.interval
                        ? 'تذكير متكرر كل مدة محددة'
                        : 'تذكير في أوقات يومية',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showReminderTypeDialog(context, settings),
                ),
                
                // Reminder Interval
                if (settings.settings.reminderType == ReminderType.interval)
                  ListTile(
                    title: const Text('فاصل التذكير'),
                    subtitle: Text(_getIntervalText(settings.settings.reminderIntervalMinutes)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showIntervalDialog(context, settings),
                  ),
                
                // Daily Reminder Times
                if (settings.settings.reminderType == ReminderType.daily)
                  ListTile(
                    title: const Text('أوقات التذكير اليومية'),
                    subtitle: Text(
                      settings.settings.dailyReminderTimes.isEmpty
                          ? 'لم يتم تحديد أوقات'
                          : '${settings.settings.dailyReminderTimes.length} أوقات محددة',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDailyTimesDialog(context, settings),
                  ),
              ],
              
              const Divider(),
              
              // Vibration Section
              _buildSectionTitle(context, 'الاستجابة'),
              SwitchListTile(
                title: const Text('الاهتزاز'),
                subtitle: const Text('اهتزاز خفيف عند الضغط على زر العدد'),
                value: settings.settings.vibrationEnabled,
                onChanged: (value) async {
                  await settings.toggleVibration(value);
                },
              ),
              
              const Divider(),
              
              // Counter Section
              _buildSectionTitle(context, 'العداد'),
              SwitchListTile(
                title: const Text('عداد يومي'),
                subtitle: const Text('بدء العداد من الصفر يومياً مع الحفاظ على الإجمالي'),
                value: settings.settings.dailyCounter,
                onChanged: (value) async {
                  await settings.toggleDailyCounter(value);
                },
              ),
              
              const Divider(),
              
              // Appearance Section
              _buildSectionTitle(context, 'المظهر'),
              SwitchListTile(
                title: const Text('الوضع الداكن'),
                subtitle: const Text('استخدام ألوان داكنة للتطبيق'),
                value: settings.settings.isDarkMode,
                onChanged: (value) async {
                  await settings.toggleDarkMode(value);
                },
              ),
              
              const Divider(),
              
              // About
              ListTile(
                title: const Text('حول التطبيق'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/about');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
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

  void _showReminderTypeDialog(BuildContext context, SettingsProvider settings) {
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
              groupValue: settings.settings.reminderType,
              onChanged: (value) async {
                await settings.setReminderType(value!);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ReminderType>(
              title: const Text('تذكير يومي'),
              subtitle: const Text('في أوقات محددة يومياً'),
              value: ReminderType.daily,
              groupValue: settings.settings.reminderType,
              onChanged: (value) async {
                await settings.setReminderType(value!);
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

  void _showIntervalDialog(BuildContext context, SettingsProvider settings) {
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
                selected: settings.settings.reminderIntervalMinutes == minutes,
                onTap: () async {
                  await settings.setReminderInterval(minutes);
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

  void _showDailyTimesDialog(BuildContext context, SettingsProvider settings) {
    final times = List<int>.from(settings.settings.dailyReminderTimes);
    
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
                        title: Text('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'),
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
                  await settings.setDailyReminderTimes(times);
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
