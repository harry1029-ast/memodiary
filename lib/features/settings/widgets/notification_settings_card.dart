import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/ink_switch.dart';
import '../../../core/theme/widgets/xuan_paper_card.dart';
import '../../notifications/services/notification_reminder_service.dart';

/// Card widget embedded in SettingsScreen allowing users to toggle and customize
/// offline Daily Writing Reminders and Sunday Weekly Review Reminders in Ink aesthetic.
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
    final tokens = InkDiaryTheme.tokensOf(context);

    return XuanPaperCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Daily Writing Reminder
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  size: 22,
                  color: tokens.cinnabar,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Writing Reminder',
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: tokens.jiaomo,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        key: const Key('daily_reminder_time_btn'),
                        onTap: _pickDailyTime,
                        child: Text(
                          '每日 ${_formatTime(_prefs.dailyHour, _prefs.dailyMinute)} (夜阑提笔时 · 点击更改)',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontKaiti,
                            fontSize: 11.5,
                            color: tokens.danmo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InkSwitch(
                  key: const Key('daily_reminder_switch'),
                  value: _prefs.dailyEnabled,
                  onChanged: (val) async {
                    HapticFeedback.lightImpact();
                    await _service.setDailyReminder(
                      enabled: val,
                      hour: _prefs.dailyHour,
                      minute: _prefs.dailyMinute,
                    );
                    await _loadPrefs();
                  },
                  semanticLabel: '每日日记提醒开关',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.agedFiber),

          // Sunday Weekly Review Reminder
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 22,
                  color: tokens.danmo,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sunday Weekly Review',
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: tokens.jiaomo,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        key: const Key('weekly_reminder_time_btn'),
                        onTap: _pickWeeklyTime,
                        child: Text(
                          '每周日 ${_formatTime(_prefs.weeklyHour, _prefs.weeklyMinute)} (结卷温故时 · 点击更改)',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontKaiti,
                            fontSize: 11.5,
                            color: tokens.danmo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InkSwitch(
                  key: const Key('weekly_reminder_switch'),
                  value: _prefs.weeklyEnabled,
                  onChanged: (val) async {
                    HapticFeedback.lightImpact();
                    await _service.setWeeklyReviewReminder(
                      enabled: val,
                      hour: _prefs.weeklyHour,
                      minute: _prefs.weeklyMinute,
                    );
                    await _loadPrefs();
                  },
                  semanticLabel: '周末复盘提醒开关',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
