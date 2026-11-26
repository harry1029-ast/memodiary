import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/atmosphere_palettes.dart';
import 'package:memodiary/core/theme/atmosphere_theme_models.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/timeline/models/chronicle_feed_item.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_summary.dart';
import 'package:memodiary/features/timeline/widgets/month_spine_divider.dart';

TimelineEntrySummary _summary(String id, DateTime date) {
  return TimelineEntrySummary(
    id: id,
    title: id,
    plainTextSnippet: 'Body for $id',
    entryDate: date,
  );
}

void main() {
  group('buildChronicleFeedItems', () {
    test('returns empty list for empty entries', () {
      expect(buildChronicleFeedItems(const []), isEmpty);
    });

    test('inserts top divider and boundary dividers across month and year transitions', () {
      final entries = [
        _summary('nov_20', DateTime(2026, 11, 20)),
        _summary('nov_05', DateTime(2026, 11, 5)),
        _summary('oct_18', DateTime(2026, 10, 18)),
        _summary('dec_2025', DateTime(2025, 12, 31)),
      ];

      final items = buildChronicleFeedItems(entries);

      expect(items.length, 7);

      expect(
        items[0],
        const ChronicleMonthDividerItem(year: 2026, month: 11, isFirstInFeed: true),
      );
      expect(
        items[1],
        ChronicleEntryFeedItem(
          summary: entries[0],
          entryIndex: 0,
          isLastEntry: false,
        ),
      );
      expect(
        items[2],
        ChronicleEntryFeedItem(
          summary: entries[1],
          entryIndex: 1,
          isLastEntry: false,
        ),
      );
      expect(
        items[3],
        const ChronicleMonthDividerItem(year: 2026, month: 10, isFirstInFeed: false),
      );
      expect(
        items[4],
        ChronicleEntryFeedItem(
          summary: entries[2],
          entryIndex: 2,
          isLastEntry: false,
        ),
      );
      expect(
        items[5],
        const ChronicleMonthDividerItem(year: 2025, month: 12, isFirstInFeed: false),
      );
      expect(
        items[6],
        ChronicleEntryFeedItem(
          summary: entries[3],
          entryIndex: 3,
          isLastEntry: true,
        ),
      );
    });

    test('inserts divider when consecutive entries share month number across different years', () {
      final entries = [
        _summary('nov_2026', DateTime(2026, 11, 2)),
        _summary('nov_2025', DateTime(2025, 11, 28)),
      ];

      final items = buildChronicleFeedItems(entries);

      expect(items.length, 4);
      expect(
        items[0],
        const ChronicleMonthDividerItem(year: 2026, month: 11, isFirstInFeed: true),
      );
      expect(
        items[2],
        const ChronicleMonthDividerItem(year: 2025, month: 11, isFirstInFeed: false),
      );
    });

    test('countChronicleMonthDividersThrough matches buildChronicleFeedItems divider boundaries', () {
      final entries = [
        _summary('nov_20', DateTime(2026, 11, 20)),
        _summary('nov_05', DateTime(2026, 11, 5)),
        _summary('oct_18', DateTime(2026, 10, 18)),
        _summary('oct_02', DateTime(2026, 10, 2)),
        _summary('nov_2025', DateTime(2025, 11, 28)),
      ];

      expect(countChronicleMonthDividersThrough(const [], 0), equals(0));
      expect(countChronicleMonthDividersThrough(entries, -1), equals(0));
      expect(countChronicleMonthDividersThrough(entries, 0), equals(1));
      expect(countChronicleMonthDividersThrough(entries, 1), equals(1));
      expect(countChronicleMonthDividersThrough(entries, 2), equals(2));
      expect(countChronicleMonthDividersThrough(entries, 3), equals(2));
      expect(countChronicleMonthDividersThrough(entries, 4), equals(3));
      expect(countChronicleMonthDividersThrough(entries, 99), equals(3));
    });
  });

  group('MonthSpineDivider Widget Tests', () {
    testWidgets('renders YYYY年M月 label, header semantics, and continuous spine line at X=37', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: const Scaffold(
            body: MonthSpineDivider(
              year: 2026,
              month: 9,
              isFirstInFeed: true,
            ),
          ),
        ),
      );

      expect(find.text('2026年9月'), findsOneWidget);

      final dividerRect = tester.getRect(find.byType(MonthSpineDivider));
      final spineRect = tester.getRect(
        find.byKey(const Key('month_spine_divider_line')),
      );
      expect(spineRect.center.dx, closeTo(37.0, 0.1));
      expect(spineRect.width, closeTo(2.0, 0.1));
      expect(spineRect.top, closeTo(dividerRect.top, 0.1));
      expect(spineRect.bottom, closeTo(dividerRect.bottom, 0.1));

      final semantics = tester.getSemantics(find.byType(MonthSpineDivider));
      expect(semantics.label, contains('2026年9月'));
    });

    testWidgets('adapts spine gradient, rule, and pill colors across light and dark AtmospherePalettes', (tester) async {
      Future<void> verifyPalette({
        required ThemeData theme,
        required AtmospherePalette expectedPalette,
        required bool isFirstInFeed,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: MonthSpineDivider(
                year: 2025,
                month: 12,
                isFirstInFeed: isFirstInFeed,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final spineLine = tester.widget<Container>(
          find.byKey(const Key('month_spine_divider_line')),
        );
        final spineDec = spineLine.decoration! as BoxDecoration;
        if (isFirstInFeed) {
          expect(
            (spineDec.gradient! as LinearGradient).colors,
            equals([expectedPalette.spineCordTop, expectedPalette.deckleBorder]),
          );
        } else {
          expect(spineDec.gradient, isNull);
          expect(spineDec.color, expectedPalette.deckleBorder);
        }

        final labelText = tester.widget<Text>(find.text('2025年12月'));
        expect(labelText.style?.color, expectedPalette.textSecondary);
      }

      await verifyPalette(
        theme: InkDiaryTheme.light,
        expectedPalette: AtmospherePalettes.yunhaoDay,
        isFirstInFeed: true,
      );
      await verifyPalette(
        theme: InkDiaryTheme.dark,
        expectedPalette: AtmospherePalettes.yunhaoNight,
        isFirstInFeed: false,
      );
      await verifyPalette(
        theme: InkDiaryTheme.forLightPalette(LightAtmospherePaletteId.classicWalnut),
        expectedPalette: AtmospherePalettes.classicWalnut,
        isFirstInFeed: false,
      );
    });

    testWidgets('renders without clipping or overflow on 320dp narrow viewport at 1.3x text scale', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 9),
              child: MonthSpineDivider(
                year: 2026,
                month: 12,
                isFirstInFeed: false,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final labelFinder = find.text('2026年12月');
      expect(labelFinder, findsOneWidget);
      final labelRect = tester.getRect(labelFinder);
      expect(labelRect.right, lessThanOrEqualTo(320.0));
      expect(labelRect.width, greaterThan(0.0));
    });
  });
}
