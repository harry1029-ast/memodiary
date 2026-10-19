import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/search/screens/search_screen.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService mediaService;
  final referenceNow = DateTime(2026, 10, 18, 12, 0);

  setUp(() async {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('memodiary_search_nl_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );

    // 1. Entry from Last Year National Day (2025-10-03) with CJK sentence containing 旅行
    await db.createEntry(
      EntriesCompanion.insert(
        id: 'e_last_year_nat_day',
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: const Value('西湖风景'),
        contentDelta: '[{"insert":"今天去杭州西湖旅行非常开心。\\n"}]',
        plainText: '今天去杭州西湖旅行非常开心。',
        entryDate: DateTime(2025, 10, 3, 14, 0),
        isWeeklyReview: const Value(false),
      ),
    );

    // 2. Entry from October 2026 that IS a Weekly Review
    await db.createEntry(
      EntriesCompanion.insert(
        id: 'e_oct_weekly_review',
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: const Value('十月第二周复盘'),
        contentDelta: '[{"insert":"本周完成了期末考试复习计划。\\n"}]',
        plainText: '本周完成了期末考试复习计划。',
        entryDate: DateTime(2026, 10, 11, 20, 0),
        isWeeklyReview: const Value(true),
        weekNumber: const Value(41),
      ),
    );

    // 3. Entry from October 2026 that is NOT a Weekly Review
    await db.createEntry(
      EntriesCompanion.insert(
        id: 'e_oct_daily',
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: const Value('秋日随笔'),
        contentDelta: '[{"insert":"今天去云南大理旅行拍照。\\n"}]',
        plainText: '今天去云南大理旅行拍照。',
        entryDate: DateTime(2026, 10, 15, 10, 0),
        isWeeklyReview: const Value(false),
      ),
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: SearchScreen(
        database: db,
        mediaService: mediaService,
        referenceNow: referenceNow,
      ),
    );
  }

  testWidgets('parses "10月所有周记", renders Understood as chips, and filters Oct weekly reviews',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('search_text_field')),
      '10月所有周记',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // Verify "Understood as:" bar and both chips are displayed
    expect(find.byKey(const Key('nl_understood_as_bar')), findsOneWidget);
    expect(
      find.byKey(const Key('nl_constraint_chip_dateRange')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('nl_constraint_chip_weeklyReview')),
      findsOneWidget,
    );

    // Only the October weekly review entry should be shown
    expect(find.text('十月第二周复盘'), findsOneWidget);
    expect(find.text('秋日随笔'), findsNothing);
    expect(find.text('西湖风景'), findsNothing);
  });

  testWidgets('parses "去年国庆发生的事" and filters Oct 1-7 of last year',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('search_text_field')),
      '去年国庆发生的事',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nl_understood_as_bar')), findsOneWidget);
    expect(
      find.byKey(const Key('nl_constraint_chip_dateRange')),
      findsOneWidget,
    );

    // Only the 2025-10-03 entry should match
    expect(find.text('西湖风景'), findsOneWidget);
    expect(find.text('十月第二周复盘'), findsNothing);
    expect(find.text('秋日随笔'), findsNothing);
  });

  testWidgets('dismissing an Understood as chip removes the constraint',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('search_text_field')),
      '10月所有周记',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('十月第二周复盘'), findsOneWidget);
    expect(find.text('秋日随笔'), findsNothing);

    // Dismiss the weeklyReview chip by tapping its delete icon
    final weeklyChip = find.byKey(const Key('nl_constraint_chip_weeklyReview'));
    final deleteIcon = find.descendant(
      of: weeklyChip,
      matching: find.byIcon(Icons.close),
    );
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    // Now weeklyReview constraint is ignored, so '所有周记' remains in query text
    expect(
      find.byKey(const Key('nl_constraint_chip_weeklyReview')),
      findsNothing,
    );
  });

  testWidgets('scopes delete semantics strictly to deleteIcon rather than parent chip',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('search_text_field')),
      '10月所有周记',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    final chipFinder = find.byKey(const Key('nl_constraint_chip_weeklyReview'));
    expect(chipFinder, findsOneWidget);

    final chipWidget = tester.widget<InputChip>(chipFinder);
    expect(chipWidget.deleteIcon, isA<Semantics>());
    final deleteSemantics = chipWidget.deleteIcon as Semantics;
    expect(deleteSemantics.properties.label, 'Remove Weekly Review filter');
  });

  testWidgets('renders Smart Event Suggestions chips and filters CJK substring entries on tap',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Smart Event Suggestions bar should be visible with '旅行 · 2' and '考试 · 1'
    expect(
      find.byKey(const Key('smart_event_suggestions_bar')),
      findsOneWidget,
    );
    final travelChip = find.byKey(const Key('event_chip_旅行'));
    expect(travelChip, findsOneWidget);
    expect(find.text('旅行 · 2'), findsOneWidget);

    // Tap the '旅行' chip -> filters the 2 entries whose Chinese sentences contain '旅行'
    await tester.tap(travelChip);
    await tester.pumpAndSettle();

    expect(find.text('西湖风景'), findsOneWidget);
    expect(find.text('秋日随笔'), findsOneWidget);
    expect(find.text('十月第二周复盘'), findsNothing);
  });

  testWidgets('renders Understood as bar resiliently on narrow (320px) screens without RenderFlex overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    FlutterErrorDetails? caughtDetails;
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      caughtDetails = details;
    };

    // Multi-constraint query creating 4 constraint chips (dateRange, weather, hasImage, weeklyReview)
    await tester.enterText(
      find.byKey(const Key('search_text_field')),
      '去年国庆 晴天 带图 所有周记',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    FlutterError.onError = oldHandler;

    // Understood as bar is visible
    expect(find.byKey(const Key('nl_understood_as_bar')), findsOneWidget);

    // On narrow screen (< 360px), text 'Understood as:' is collapsed to icon tooltip
    expect(find.text('Understood as:'), findsNothing);
    expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);

    // All 4 constraint chips rendered
    expect(
      find.byKey(const Key('nl_constraint_chip_dateRange')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('nl_constraint_chip_weather')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('nl_constraint_chip_hasImage')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('nl_constraint_chip_weeklyReview')),
      findsOneWidget,
    );

    // Verify chip deletion works on 320px screen without overflow or hit-test failure
    final weeklyChip = find.byKey(const Key('nl_constraint_chip_weeklyReview'));
    await tester.ensureVisible(weeklyChip);
    await tester.pumpAndSettle();

    final deleteIcon = find.descendant(
      of: weeklyChip,
      matching: find.byIcon(Icons.close),
    );
    expect(deleteIcon, findsOneWidget);
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    // weeklyReview chip removed, remaining 3 chips intact
    expect(
      find.byKey(const Key('nl_constraint_chip_weeklyReview')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('nl_constraint_chip_dateRange')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('nl_constraint_chip_weather')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('nl_constraint_chip_hasImage')),
      findsOneWidget,
    );

    expect(caughtDetails, isNull);
  });
}
