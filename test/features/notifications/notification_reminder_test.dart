import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/notifications/services/notification_reminder_service.dart';
import 'package:memodiary/features/settings/widgets/notification_settings_card.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationReminderService & NotificationSettingsCard Tests', () {
    test('computeNextDailyInstance initializes timezones and schedules next future occurrence', () {
      NotificationReminderService.ensureTimeZonesInitialized();
      final utc = tz.getLocation('UTC');

      // Case 1: Reference time is 10:00 -> 21:00 is later the same day
      final morningRef = DateTime.utc(2026, 10, 18, 10, 0);
      final nextSameDay = NotificationReminderService.computeNextDailyInstance(
        hour: 21,
        minute: 0,
        now: morningRef,
        location: utc,
      );
      expect(nextSameDay.year, 2026);
      expect(nextSameDay.month, 10);
      expect(nextSameDay.day, 18);
      expect(nextSameDay.hour, 21);
      expect(nextSameDay.minute, 0);

      // Case 2: Reference time is 22:00 -> 21:00 rolls over to tomorrow
      final nightRef = DateTime.utc(2026, 10, 18, 22, 0);
      final nextTomorrow = NotificationReminderService.computeNextDailyInstance(
        hour: 21,
        minute: 0,
        now: nightRef,
        location: utc,
      );
      expect(nextTomorrow.year, 2026);
      expect(nextTomorrow.month, 10);
      expect(nextTomorrow.day, 19);
      expect(nextTomorrow.hour, 21);
    });

    test('computeNextSundayInstance advances to the next Sunday at target hour:minute', () {
      NotificationReminderService.ensureTimeZonesInitialized();
      final utc = tz.getLocation('UTC');

      // 2026-10-14 is a Wednesday -> next Sunday is 2026-10-18
      final wedRef = DateTime.utc(2026, 10, 14, 12, 0);
      final nextSun = NotificationReminderService.computeNextSundayInstance(
        hour: 20,
        minute: 30,
        now: wedRef,
        location: utc,
      );
      expect(nextSun.weekday, equals(DateTime.sunday));
      expect(nextSun.year, 2026);
      expect(nextSun.month, 10);
      expect(nextSun.day, 18);
      expect(nextSun.hour, 20);
      expect(nextSun.minute, 30);
    });

    testWidgets('NotificationSettingsCard toggles Daily Writing and Sunday Weekly Review reminders', (tester) async {
      final service = NotificationReminderService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationSettingsCard(reminderService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Writing Reminder'), findsOneWidget);
      expect(find.text('Sunday Weekly Review'), findsOneWidget);

      await tester.tap(find.byKey(const Key('daily_reminder_switch')));
      await tester.pumpAndSettle();

      var prefs = await service.loadPreferences();
      expect(prefs.dailyEnabled, isTrue);

      await tester.tap(find.byKey(const Key('weekly_reminder_switch')));
      await tester.pumpAndSettle();

      prefs = await service.loadPreferences();
      expect(prefs.weeklyEnabled, isTrue);
    });
  });
}

