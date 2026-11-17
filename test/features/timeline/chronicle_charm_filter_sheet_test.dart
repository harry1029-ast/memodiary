import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/timeline/models/timeline_filter_state.dart';
import 'package:memodiary/features/timeline/widgets/chronicle_charm_filter_sheet.dart';

void main() {
  group('ChronicleCharmFilterSheet Widget Tests', () {
    Future<void> pumpHostAndOpenSheet(
      WidgetTester tester, {
      TimelineFilterState initialFilters = const TimelineFilterState(),
      ValueChanged<TimelineFilterState>? onFiltersChanged,
      Size viewportSize = const Size(400, 800),
      double textScale = 1.0,
      Brightness brightness = Brightness.light,
    }) async {
      tester.view.physicalSize = viewportSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: brightness == Brightness.dark
              ? InkDiaryTheme.dark
              : InkDiaryTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  key: const Key('open_charm_sheet_trigger'),
                  onPressed: () => ChronicleCharmFilterSheet.show(
                    context: context,
                    initialFilters: initialFilters,
                    onFiltersChanged: onFiltersChanged ?? (_) {},
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_charm_sheet_trigger')));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'updates visual selection and checkmarks inside open sheet and notifies caller',
      (tester) async {
        final updates = <TimelineFilterState>[];
        await pumpHostAndOpenSheet(
          tester,
          initialFilters: const TimelineFilterState(year: 2026, month: 11),
          onFiltersChanged: updates.add,
        );

        expect(find.byType(ChronicleCharmFilterSheet), findsOneWidget);
        expect(find.text('心绪'), findsOneWidget);
        expect(find.text('天时'), findsOneWidget);
        expect(find.text('含图影'), findsOneWidget);
        expect(find.text('周志复盘'), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsNothing);

        // Toggle Mood: 欢欣 (5)
        final greatChip = find.byKey(const Key('charm_filter_mood_5'));
        await tester.ensureVisible(greatChip);
        await tester.tap(greatChip);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: greatChip,
            matching: find.byIcon(Icons.check_rounded),
          ),
          findsOneWidget,
        );
        expect(updates.last.mood, equals(5));

        // Toggle Weather: 润雨 ('rainy')
        final rainyChip = find.byKey(const Key('charm_filter_weather_rainy'));
        await tester.ensureVisible(rainyChip);
        await tester.tap(rainyChip);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: rainyChip,
            matching: find.byIcon(Icons.check_rounded),
          ),
          findsOneWidget,
        );
        expect(updates.last.weather, equals('rainy'));

        // Toggle With Media: 含图影
        final mediaChip = find.byKey(const Key('charm_filter_media_toggle'));
        await tester.ensureVisible(mediaChip);
        await tester.tap(mediaChip);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: mediaChip,
            matching: find.byIcon(Icons.check_rounded),
          ),
          findsOneWidget,
        );
        expect(updates.last.hasMediaOnly, isTrue);

        // Toggle Weekly Review: 周志复盘
        final weeklyChip = find.byKey(const Key('charm_filter_weekly_toggle'));
        await tester.ensureVisible(weeklyChip);
        await tester.tap(weeklyChip);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: weeklyChip,
            matching: find.byIcon(Icons.check_rounded),
          ),
          findsOneWidget,
        );
        expect(updates.last.weeklyReviewOnly, isTrue);

        // Tapping active Mood again toggles it off visually inside open sheet
        await tester.ensureVisible(greatChip);
        await tester.tap(greatChip);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: greatChip,
            matching: find.byIcon(Icons.check_rounded),
          ),
          findsNothing,
        );
        expect(updates.last.mood, isNull);

        // Tap 重置笺签 -> clears remaining charms visually while preserving date
        final resetButton = find.byKey(const Key('charm_filter_reset_button'));
        await tester.ensureVisible(resetButton);
        await tester.tap(resetButton);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check_rounded), findsNothing);
        expect(updates.last.hasActiveCharmFilters, isFalse);
        expect(updates.last.year, equals(2026));
        expect(updates.last.month, equals(11));
      },
    );

    testWidgets(
      'enforces 44x44 minimum tap targets, explicit semantics, and zero overflow on 320dp short screen with 1.6x system text scale',
      (tester) async {
        await pumpHostAndOpenSheet(
          tester,
          viewportSize: const Size(320, 400),
          textScale: 1.6,
          brightness: Brightness.dark,
        );

        expect(tester.takeException(), isNull);

        final controlKeys = [
          const Key('charm_filter_reset_button'),
          const Key('charm_filter_close_button'),
          const Key('charm_filter_mood_5'),
          const Key('charm_filter_mood_1'),
          const Key('charm_filter_weather_sunny'),
          const Key('charm_filter_weather_snowy'),
          const Key('charm_filter_media_toggle'),
          const Key('charm_filter_weekly_toggle'),
        ];

        for (final key in controlKeys) {
          final finder = find.byKey(key);
          await tester.ensureVisible(finder);
          final size = tester.getSize(finder);
          expect(
            size.width,
            greaterThanOrEqualTo(44.0),
            reason: '$key width should be >= 44dp',
          );
          expect(
            size.height,
            greaterThanOrEqualTo(44.0),
            reason: '$key height should be >= 44dp',
          );
        }

        expect(find.bySemanticsLabel(RegExp('心绪：喜悦')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('天时：晴天')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('含图影')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('周志复盘')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('重置笺签')), findsOneWidget);
      },
    );
  });
}
