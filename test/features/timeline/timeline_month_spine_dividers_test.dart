import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/atmosphere_palettes.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/timeline/screens/timeline_screen.dart';
import 'package:memodiary/features/timeline/widgets/month_spine_divider.dart';
import 'package:memodiary/features/timeline/widgets/timeline_date_spine_item.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;

  setUp(() {
    db = AppDatabase.memory();
    mediaService = MediaSandboxService();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedCrossMonthEntries() async {
    final items = [
      (
        id: 'e_2026_11_20',
        title: 'Late November Walk',
        date: DateTime(2026, 11, 20, 18, 0),
        mood: 5,
      ),
      (
        id: 'e_2026_11_05',
        title: 'Early November Tea',
        date: DateTime(2026, 11, 5, 9, 0),
        mood: 3,
      ),
      (
        id: 'e_2026_10_18',
        title: 'October Rain Note',
        date: DateTime(2026, 10, 18, 15, 0),
        mood: 5,
      ),
      (
        id: 'e_2025_12_31',
        title: 'Year End Reflection',
        date: DateTime(2025, 12, 31, 22, 0),
        mood: 4,
      ),
    ];

    for (final item in items) {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: item.id,
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: Value(item.title),
          contentDelta: jsonEncode([
            {'insert': 'Body for ${item.title}\n'},
          ]),
          plainText: 'Body for ${item.title}',
          entryDate: item.date,
          mood: Value(item.mood),
        ),
      );
    }
  }

  Future<void> pumpTimelineScreen(
    WidgetTester tester, {
    ThemeData? theme,
    Size? surfaceSize,
    double textScale = 1.0,
  }) async {
    if (surfaceSize != null) {
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? InkDiaryTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: TimelineScreen(
          database: db,
          mediaService: mediaService,
          enableSceneryAnimation: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('TimelineScreen Month Spine Dividers', () {
    testWidgets(
      'inserts YYYY年M月 dividers at feed start and month/year boundaries in both sort orders',
      (tester) async {
        await seedCrossMonthEntries();
        await pumpTimelineScreen(tester, surfaceSize: const Size(400, 900));

        // Newest first: 2026年11月 -> Late Nov, Early Nov -> 2026年10月 -> Oct -> 2025年12月 -> Dec
        expect(find.text('2026年11月'), findsOneWidget);
        final novDividerY = tester.getTopLeft(find.text('2026年11月')).dy;
        final lateNovY = tester.getTopLeft(find.text('Late November Walk')).dy;
        final earlyNovY = tester.getTopLeft(find.text('Early November Tea')).dy;
        expect(novDividerY, lessThan(lateNovY));
        expect(lateNovY, lessThan(earlyNovY));

        await tester.scrollUntilVisible(
          find.text('Year End Reflection'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('2026年10月'), findsOneWidget);
        expect(find.text('2025年12月'), findsOneWidget);
        final octDividerY = tester.getTopLeft(find.text('2026年10月')).dy;
        final octEntryY = tester.getTopLeft(find.text('October Rain Note')).dy;
        final decDividerY = tester.getTopLeft(find.text('2025年12月')).dy;
        final decEntryY = tester.getTopLeft(find.text('Year End Reflection')).dy;
        expect(octDividerY, lessThan(octEntryY));
        expect(octEntryY, lessThan(decDividerY));
        expect(decDividerY, lessThan(decEntryY));

        // Toggle sort order to oldestFirst (最早 ↑)
        await tester.tap(find.byKey(const Key('timeline_sort_toggle_button')));
        await tester.pumpAndSettle();

        expect(find.text('最早'), findsOneWidget);
        expect(find.text('2025年12月'), findsOneWidget);
        final ascDecDividerY = tester.getTopLeft(find.text('2025年12月')).dy;
        final ascDecEntryY = tester.getTopLeft(find.text('Year End Reflection')).dy;
        expect(ascDecDividerY, lessThan(ascDecEntryY));

        await tester.scrollUntilVisible(
          find.text('Late November Walk'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('2026年10月'), findsOneWidget);
        expect(find.text('2026年11月'), findsOneWidget);
        final ascOctDividerY = tester.getTopLeft(find.text('2026年10月')).dy;
        final ascOctEntryY = tester.getTopLeft(find.text('October Rain Note')).dy;
        final ascNovDividerY = tester.getTopLeft(find.text('2026年11月')).dy;
        final ascEarlyNovY = tester.getTopLeft(find.text('Early November Tea')).dy;
        final ascLateNovY = tester.getTopLeft(find.text('Late November Walk')).dy;
        expect(ascOctDividerY, lessThan(ascOctEntryY));
        expect(ascOctEntryY, lessThan(ascNovDividerY));
        expect(ascNovDividerY, lessThan(ascEarlyNovY));
        expect(ascEarlyNovY, lessThan(ascLateNovY));
      },
    );

    testWidgets(
      'updates Month Spine Dividers under Date Index Tray and charm filters',
      (tester) async {
        await seedCrossMonthEntries();
        await pumpTimelineScreen(tester, surfaceSize: const Size(400, 900));

        // Filter by charm mood = 5 (喜悦) -> keeps 2026-11-20 and 2026-10-18 only
        await tester.tap(find.byKey(const Key('timeline_charm_filter_button')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('charm_filter_mood_5')));
        await tester.tap(find.byKey(const Key('charm_filter_mood_5')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('charm_filter_close_button')));
        await tester.pumpAndSettle();

        expect(find.text('2026年11月'), findsOneWidget);
        expect(find.text('2026年10月'), findsOneWidget);
        expect(find.text('2025年12月'), findsNothing);

        // Select 10月 in Date Index Tray -> only 2026年10月 remains
        await tester.ensureVisible(find.byKey(const Key('timeline_month_chip_10')));
        await tester.tap(find.byKey(const Key('timeline_month_chip_10')));
        await tester.pumpAndSettle();

        expect(find.text('2026年10月'), findsOneWidget);
        expect(find.text('2026年11月'), findsNothing);

        // Select empty month 3月 -> zero dividers shown
        await tester.ensureVisible(find.byKey(const Key('timeline_month_chip_3')));
        await tester.tap(find.byKey(const Key('timeline_month_chip_3')));
        await tester.pumpAndSettle();

        expect(find.byType(MonthSpineDivider), findsNothing);
      },
    );

    testWidgets(
      'aligns dividers continuously along the vertical spine from grommet and adapts to light/dark themes',
      (tester) async {
        await seedCrossMonthEntries();

        Future<void> verifySpineInTheme(
          ThemeData theme,
          Color expectedDarkOrLightLabelColor,
        ) async {
          await pumpTimelineScreen(
            tester,
            theme: theme,
            surfaceSize: const Size(400, 900),
          );

          final grommetKnotRect = tester.getRect(
            find.byKey(const Key('timeline_brass_grommet_knot')),
          );
          final grommetRect = tester.getRect(
            find.byKey(const Key('timeline_brass_grommet')),
          );
          final firstDividerRect = tester.getRect(
            find.byType(MonthSpineDivider).first,
          );
          final firstDividerSpineRect = tester.getRect(
            find.byKey(const Key('month_spine_divider_line')).first,
          );
          final firstEntryItemRect = tester.getRect(
            find.byType(TimelineDateSpineItem).first,
          );
          final firstEntrySpineRect = tester.getRect(
            find.byKey(const Key('timeline_date_spine_line')).first,
          );

          // Horizontal alignment: grommet -> divider spine -> entry spine
          expect(
            firstDividerSpineRect.center.dx,
            closeTo(grommetKnotRect.center.dx, 0.5),
          );
          expect(
            firstEntrySpineRect.center.dx,
            closeTo(firstDividerSpineRect.center.dx, 0.5),
          );

          // Vertical continuity: grommet -> first divider -> first entry spine
          expect(firstDividerSpineRect.top, closeTo(grommetRect.bottom, 1.0));
          expect(
            firstEntrySpineRect.top,
            closeTo(firstDividerSpineRect.bottom, 1.0),
          );
          expect(firstEntryItemRect.top, closeTo(firstDividerRect.bottom, 1.0));

          final labelText = tester.widget<Text>(find.text('2026年11月'));
          expect(labelText.style?.color, expectedDarkOrLightLabelColor);
        }

        await verifySpineInTheme(
          InkDiaryTheme.light,
          AtmospherePalettes.yunhaoDay.textSecondary,
        );
        await verifySpineInTheme(
          InkDiaryTheme.dark,
          AtmospherePalettes.yunhaoNight.textSecondary,
        );
      },
    );

    testWidgets(
      'renders cleanly without clipping or overflow on 320dp viewport at 1.3x text scale',
      (tester) async {
        await seedCrossMonthEntries();
        await pumpTimelineScreen(
          tester,
          surfaceSize: const Size(320, 640),
          textScale: 1.3,
        );

        expect(tester.takeException(), isNull);
        final novFinder = find.text('2026年11月');
        expect(novFinder, findsOneWidget);
        expect(tester.getRect(novFinder).right, lessThanOrEqualTo(320.0));

        await tester.scrollUntilVisible(
          find.text('2025年12月'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final decFinder = find.text('2025年12月');
        expect(decFinder, findsOneWidget);
        expect(tester.getRect(decFinder).right, lessThanOrEqualTo(320.0));
      },
    );
  });
}
