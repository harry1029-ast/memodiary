import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Configuration state for local writing and weekly review reminders.
class ReminderPreferences {
  final bool dailyEnabled;
  final int dailyHour;
  final int dailyMinute;
  final bool weeklyEnabled;
  final int weeklyHour;
  final int weeklyMinute;

  const ReminderPreferences({
    this.dailyEnabled = false,
    this.dailyHour = 21,
    this.dailyMinute = 0,
    this.weeklyEnabled = false,
    this.weeklyHour = 20,
    this.weeklyMinute = 0,
  });

  ReminderPreferences copyWith({
    bool? dailyEnabled,
    int? dailyHour,
    int? dailyMinute,
    bool? weeklyEnabled,
    int? weeklyHour,
    int? weeklyMinute,
  }) {
    return ReminderPreferences(
      dailyEnabled: dailyEnabled ?? this.dailyEnabled,
      dailyHour: dailyHour ?? this.dailyHour,
      dailyMinute: dailyMinute ?? this.dailyMinute,
      weeklyEnabled: weeklyEnabled ?? this.weeklyEnabled,
      weeklyHour: weeklyHour ?? this.weeklyHour,
      weeklyMinute: weeklyMinute ?? this.weeklyMinute,
    );
  }
}

/// 100% offline local notification scheduler for Daily Writing Reminders
/// and Sunday Weekly Review Reminders. Zero cloud push servers (no FCM/APNs).
class NotificationReminderService {
  static const int dailyNotificationId = 1001;
  static const int weeklyNotificationId = 1002;

  static bool _tzInitialized = false;
  static ReminderPreferences _cachedPrefs = const ReminderPreferences();

  final FlutterLocalNotificationsPlugin? _plugin;
  bool _pluginInitialized = false;

  NotificationReminderService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin;

  late final FlutterLocalNotificationsPlugin _resolvedPlugin =
      _plugin ?? FlutterLocalNotificationsPlugin();

  /// Initializes timezone database and local notification channels.
  Future<void> init() async {
    ensureTimeZonesInitialized();
    if (_pluginInitialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _resolvedPlugin.initialize(settings);
      _pluginInitialized = true;
    } catch (e) {
      // Absorb missing platform channel in headless test environments
      debugPrint('NotificationReminderService init fallback: $e');
    }
  }

  /// Ensures `tz.initializeTimeZones()` has been called before any schedule computation.
  static void ensureTimeZonesInitialized() {
    if (_tzInitialized) return;
    tz_data.initializeTimeZones();
    _tzInitialized = true;
  }

  /// Computes the next occurrence of [hour]:[minute] in local/UTC timezone.
  static tz.TZDateTime computeNextDailyInstance({
    required int hour,
    required int minute,
    DateTime? now,
    tz.Location? location,
  }) {
    ensureTimeZonesInitialized();
    final loc = location ?? tz.local;
    final ref = now != null
        ? tz.TZDateTime.from(now, loc)
        : tz.TZDateTime.now(loc);

    var scheduled = tz.TZDateTime(
      loc,
      ref.year,
      ref.month,
      ref.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(ref)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Computes the next occurrence of Sunday at [hour]:[minute] for the Weekly Review.
  static tz.TZDateTime computeNextSundayInstance({
    required int hour,
    required int minute,
    DateTime? now,
    tz.Location? location,
  }) {
    var scheduled = computeNextDailyInstance(
      hour: hour,
      minute: minute,
      now: now,
      location: location,
    );
    while (scheduled.weekday != DateTime.sunday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Loads current reminder preferences.
  Future<ReminderPreferences> loadPreferences() async {
    await init();
    return _cachedPrefs;
  }

  /// Schedules or updates the Daily Writing Reminder at [hour]:[minute].
  Future<void> setDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await init();
    _cachedPrefs = _cachedPrefs.copyWith(
      dailyEnabled: enabled,
      dailyHour: hour,
      dailyMinute: minute,
    );

    try {
      if (!enabled) {
        await _resolvedPlugin.cancel(dailyNotificationId);
        return;
      }

      final scheduledDate = computeNextDailyInstance(
        hour: hour,
        minute: minute,
      );

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'memodiary_daily_reminder',
          'Daily Writing Reminder',
          channelDescription: 'Gentle daily prompt to capture your thoughts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _resolvedPlugin.zonedSchedule(
        dailyNotificationId,
        'Time to Capture Today ✨',
        'Take a quiet moment to write down today\'s memories in MemoDiary.',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('setDailyReminder fallback: $e');
    }
  }

  /// Schedules or updates the Sunday Weekly Review Reminder at [hour]:[minute].
  Future<void> setWeeklyReviewReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await init();
    _cachedPrefs = _cachedPrefs.copyWith(
      weeklyEnabled: enabled,
      weeklyHour: hour,
      weeklyMinute: minute,
    );

    try {
      if (!enabled) {
        await _resolvedPlugin.cancel(weeklyNotificationId);
        return;
      }

      final scheduledDate = computeNextSundayInstance(
        hour: hour,
        minute: minute,
      );

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'memodiary_weekly_review',
          'Weekly Review Reminder',
          channelDescription: 'Sunday evening prompt for your weekly reflection',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _resolvedPlugin.zonedSchedule(
        weeklyNotificationId,
        'Weekly Review Time 📖',
        'Reflect on your 7-day journey and write your weekly synthesis.',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('setWeeklyReviewReminder fallback: $e');
    }
  }
}

