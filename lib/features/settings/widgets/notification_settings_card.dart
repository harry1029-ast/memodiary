import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memodiary/features/notifications/services/notification_reminder_service.dart';

/// Card widget embedded in SettingsScreen allowing users to toggle and customize
/// offline Daily Writing Reminders and Sunday Weekly Review Reminders.
class NotificationSettingsCard extends StatefulWidget {
  final NotificationReminderService? reminderService;

  const NotificationSettingsCard({
    super.key,
    this.reminderService,
  });

  @override
  State<NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<NotificationSettingsCard> {
  late final NotificationReminderService _service;
  ReminderPreferences _prefs = const ReminderPreferences();

  @override
  void initState() {
    super.initState();
    _service = widget.reminderService ?? NotificationReminderService();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await _service.loadPreferences();
    if (mounted) {
      setState(() => _prefs = prefs);
    }
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDailyTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _prefs.dailyHour, minute: _prefs.dailyMinute),
    );
    if (picked != null && mounted) {
      HapticFeedback.lightImpact();
      await _service.setDailyReminder(
        enabled: _prefs.dailyEnabled,
        hour: picked.hour,
        minute: picked.minute,
      );
      await _loadPrefs();
    }
  }

  Future<void> _pickWeeklyTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _prefs.weeklyHour, minute: _prefs.weeklyMinute),
    );
    if (picked != null && mounted) {
      HapticFeedback.lightImpact();
      await _service.setWeeklyReviewReminder(
        enabled: _prefs.weeklyEnabled,
        hour: picked.hour,
        minute: picked.minute,
      );
      await _loadPrefs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            key: const Key('daily_reminder_switch'),
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text(
              'Daily Writing Reminder',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: GestureDetector(
              key: const Key('daily_reminder_time_btn'),
              onTap: _pickDailyTime,
              child: Text(
                'Every day at ${_formatTime(_prefs.dailyHour, _prefs.dailyMinute)} (Tap to change)',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            value: _prefs.dailyEnabled,
            onChanged: (enabled) async {
              HapticFeedback.lightImpact();
              await _service.setDailyReminder(
                enabled: enabled,
                hour: _prefs.dailyHour,
                minute: _prefs.dailyMinute,
              );
              await _loadPrefs();
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            key: const Key('weekly_reminder_switch'),
            secondary: const Icon(Icons.event_repeat_outlined),
            title: const Text(
              'Sunday Weekly Review',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: GestureDetector(
              key: const Key('weekly_reminder_time_btn'),
              onTap: _pickWeeklyTime,
              child: Text(
                'Sundays at ${_formatTime(_prefs.weeklyHour, _prefs.weeklyMinute)} (Tap to change)',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            value: _prefs.weeklyEnabled,
            onChanged: (enabled) async {
              HapticFeedback.lightImpact();
              await _service.setWeeklyReviewReminder(
                enabled: enabled,
                hour: _prefs.weeklyHour,
                minute: _prefs.weeklyMinute,
              );
              await _loadPrefs();
            },
          ),
        ],
      ),
    );
  }
}

