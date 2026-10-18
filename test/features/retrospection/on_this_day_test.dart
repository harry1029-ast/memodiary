import 'dart:math';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/retrospection/widgets/on_this_day_banner.dart';
import 'package:memodiary/features/retrospection/widgets/serendipity_roulette_card.dart';

void main() {
  group('Retrospective Reflection Engine (On This Day & Serendipity Roulette)', () {
    test('getEntriesOnThisDay matches month and day across past years and handles Feb 29 leap years', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      // Entry 1: Same month/day 1 year ago (2025-10-18)
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'otd_2025',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Autumn 2025'),
          contentDelta: '[{"insert":"2025 memory\\n"}]',
          plainText: '2025 memory',
          entryDate: DateTime(2025, 10, 18, 14, 0),
        ),
      );

      // Entry 2: Same month/day 2 years ago (2024-10-18)
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'otd_2024',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Autumn 2024'),
          contentDelta: '[{"insert":"2024 memory\\n"}]',
          plainText: '2024 memory',
          entryDate: DateTime(2024, 10, 18, 9, 0),
        ),
      );

      // Entry 3: Today in current year (2026-10-18) -> should be excluded
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'otd_2026_today',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Today 2026'),
          contentDelta: '[{"insert":"Today\\n"}]',
          plainText: 'Today',
          entryDate: DateTime(2026, 10, 18, 12, 0),
        ),
      );

      // Entry 4: Leap day entry (2024-02-29)
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'leap_2024',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Leap Day 2024'),
          contentDelta: '[{"insert":"Leap memory\\n"}]',
          plainText: 'Leap memory',
          entryDate: DateTime(2024, 2, 29, 18, 0),
        ),
      );

      final matches = await db.getEntriesOnThisDay(DateTime(2026, 10, 18));
      expect(matches.map((e) => e.id).toList(), equals(['otd_2025', 'otd_2024']));

      // On Feb 28 of a non-leap year (2026-02-28), Feb 29 memories should also surface!
      final nonLeapFeb28 = await db.getEntriesOnThisDay(DateTime(2026, 2, 28));
      expect(nonLeapFeb28.map((e) => e.id), contains('leap_2024'));
    });

    test('getRandomOldEntry draws only active unlocked entries >= 90 days old', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      final refDate = DateTime(2026, 10, 18);

      // Old entry (120 days ago) -> eligible
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'old_120d',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Summer Memory'),
          contentDelta: '[{"insert":"Old memory\\n"}]',
          plainText: 'Old memory',
          entryDate: refDate.subtract(const Duration(days: 120)),
        ),
      );

      // Recent entry (10 days ago) -> ineligible
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'recent_10d',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Recent Memory'),
          contentDelta: '[{"insert":"Recent\\n"}]',
          plainText: 'Recent',
          entryDate: refDate.subtract(const Duration(days: 10)),
        ),
      );

      // Old sealed time capsule -> ineligible
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'old_sealed_capsule',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Future Capsule'),
          contentDelta: '[{"insert":"Capsule\\n"}]',
          plainText: 'Capsule',
          entryDate: refDate.subtract(const Duration(days: 200)),
          unlockAt: Value(refDate.add(const Duration(days: 365))),
        ),
      );

      final drawn = await db.getRandomOldEntry(
        minDaysAgo: 90,
        referenceDate: refDate,
        random: Random(42),
      );
      expect(drawn, isNotNull);
      expect(drawn!.id, equals('old_120d'));
    });

    testWidgets('OnThisDayBanner and SerendipityRouletteCard render and trigger callbacks', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'hist_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('One Year Ago Today'),
          contentDelta: '[{"insert":"A wonderful day in the mountains\\n"}]',
          plainText: 'A wonderful day in the mountains',
          entryDate: DateTime.now().subtract(const Duration(days: 365)),
        ),
      );

      final entry = (await db.getEntryById('hist_1'))!;
      Entry? tappedEntry;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => OnThisDayBanner(
                entries: [entry],
                onEntryTap: (e) => tappedEntry = e,
                onOpenSerendipity: () {
                  SerendipityRouletteCard.show(
                    context: context,
                    database: db,
                    onOpenEntry: (e) => tappedEntry = e,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('On This Day · 1 Memory'), findsOneWidget);
      expect(find.text('One Year Ago Today'), findsOneWidget);

      // Open Serendipity Roulette dialog
      await tester.tap(find.byKey(const Key('open_serendipity_roulette_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Serendipity Memory Roulette'), findsOneWidget);
      expect(find.text('One Year Ago Today'), findsWidgets);

      await tester.tap(find.byKey(const Key('serendipity_open_entry_btn')));
      await tester.pumpAndSettle();
      expect(tappedEntry?.id, equals('hist_1'));
    });
  });
}

