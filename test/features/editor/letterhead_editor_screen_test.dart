import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';

import '../../helpers/editor_test_harness.dart';
import '../../helpers/real_cjk_font.dart';

const _entryId = 'letterhead_test_entry';
const _phoneViewport = Size(360, 780);

/// Expected lunar strings are published almanac values: 2026-11-10 is 十月初二
/// (孟冬) and 2026-11-07 is 九月廿九 (季秋), both in the 丙午 year.
void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('letterhead_editor_screen_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);

    await database.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: _entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('兰亭偶得'),
            contentDelta: '[]',
            plainText: '',
            entryDate: DateTime(2026, 11, 10, 10, 30),
            mood: const Value(4),
            weather: const Value('sunny'),
          ),
        );
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  /// Fills the entry so the opening sheet is not the final one: the signature
  /// seal only rests on the final sheet, and it is not under test here.
  Future<void> fillThreeSheets() {
    final multiSheetDelta = Delta();
    for (var lineIndex = 1; lineIndex <= 29; lineIndex++) {
      multiSheetDelta.insert('第${lineIndex.toString().padLeft(2, '0')}行信笺书法墨迹书写记录\n');
    }
    return database.entriesDao.updateEntryContent(_entryId, jsonEncode(multiSheetDelta.toJson()), 'Multi-sheet content');
  }

  Future<void> pumpEditor(
    WidgetTester tester, {
    String entryId = _entryId,
    Size viewportSize = _phoneViewport,
    bool settle = true,
  }) {
    return pumpEntryEditorScreen(
      tester,
      database: database,
      mediaSandboxService: sandboxService,
      entryId: entryId,
      viewportSize: viewportSize,
      settle: settle,
    );
  }

  Finder sealText(String character) => find.descendant(
        of: find.byKey(const Key('letterhead_date_seal')),
        matching: find.text(character),
      );

  void expectFourRowLetterhead(WidgetTester tester) {
    final letterhead = tester.widget<JournalLetterhead>(find.byType(JournalLetterhead));
    expect(tester.getSize(find.byType(JournalLetterhead)).height, equals(4 * letterhead.rowHeight));
    final canvas = tester.widget<TemplateCanvasContainer>(find.byType(TemplateCanvasContainer));
    expect(canvas.layoutMetrics!.rowCount, equals(14));
  }

  group('Journal Letterhead on the opening sheet', () {
    testWidgets('shows the lunar seal, both date lines and the charms in four rows', (tester) async {
      await pumpEditor(tester);

      expect(sealText('丙'), findsOneWidget);
      expect(sealText('午'), findsOneWidget);
      expect(sealText('孟'), findsOneWidget);
      expect(sealText('冬'), findsOneWidget);
      expect(find.text('2026年11月10日 周二'), findsOneWidget);
      expect(find.text('十月初二 · 立冬'), findsOneWidget);
      expect(find.text('兰亭偶得'), findsOneWidget);
      expect(find.byKey(const Key('letterhead_weather_charm')), findsOneWidget);
      expect(find.byKey(const Key('letterhead_mood_charm')), findsOneWidget);
      expectFourRowLetterhead(tester);
    });

    testWidgets('shows the whole solar date between the seal and the charms at 360dp', (tester) async {
      await pumpEditor(tester);

      final solarLine = find.byKey(const Key('letterhead_solar_line'));
      final dateRight = tester.getBottomRight(solarLine).dx;
      final dateLeft = tester.getTopLeft(solarLine).dx;
      expect(dateLeft, greaterThanOrEqualTo(tester.getTopRight(find.byKey(const Key('letterhead_date_seal_target'))).dx - 0.01));
      expect(dateRight, lessThanOrEqualTo(tester.getTopLeft(find.byKey(const Key('letterhead_weather_charm_target'))).dx + 0.01));
      expect(tester.widget<Text>(solarLine).style!.fontSize, greaterThanOrEqualTo(13));
      expect(tester.widget<Text>(solarLine).overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('shows the solar date unscaled at 360dp in a real CJK font', skip: realCjkFontPath == null,
        (tester) async {
      await loadRealCjkFont(tester, InkDiaryTheme.fontKaiti);
      await pumpEditor(tester);

      final solarLine = find.byKey(const Key('letterhead_solar_line'));
      // getRect applies the FittedBox transform: a scaled-down line is narrower than its layout size.
      expect(tester.getRect(solarLine).width, closeTo(tester.getSize(solarLine).width, 0.01),
          reason: 'the solar date must not be scaled down');
      expect(tester.getSize(solarLine).width, lessThan(14 * 13), reason: 'the real font is in use, not Ahem');
      expect(find.byKey(const Key('letterhead_lunar_line')), findsOneWidget);
    });

    testWidgets('sits the larger title on the bottom row, below the muted date lines', (tester) async {
      await pumpEditor(tester);

      final letterhead = tester.getRect(find.byType(JournalLetterhead));
      final title = tester.getRect(find.byType(TextField).first);
      final lunar = tester.getRect(find.byKey(const Key('letterhead_lunar_line')));
      expect(title.bottom, closeTo(letterhead.bottom, 0.5));
      expect(lunar.bottom, lessThanOrEqualTo(title.top + 0.01));
      final titleFontSize = tester.widget<TextField>(find.byType(TextField).first).style!.fontSize!;
      final solarFontSize = tester.widget<Text>(find.byKey(const Key('letterhead_solar_line'))).style!.fontSize!;
      expect(titleFontSize, greaterThan(solarFontSize + 4));
    });

    testWidgets('keeps four rows and the whole solar date at large text scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await fillThreeSheets();
      await pumpEditor(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('2026年11月10日 周二'), findsOneWidget);
      expectFourRowLetterhead(tester);
    });

    testWidgets('tapping the seal changes the date and the seal follows the new lunar month', (tester) async {
      await pumpEditor(tester);

      await tester.tap(find.byKey(const Key('letterhead_date_seal_target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('7'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('2026年11月7日 周六'), findsOneWidget);
      expect(find.text('九月廿九 · 立冬'), findsOneWidget);
      expect(sealText('季'), findsOneWidget);
      expect(sealText('秋'), findsOneWidget);
      expect(sealText('孟'), findsNothing);
      expectFourRowLetterhead(tester);

      final stored = await database.entriesDao.getEntryById(_entryId);
      expect(stored!.entryDate.day, 7);
    });

    testWidgets('mood charm opens its picker, saves the choice and relabels itself', (tester) async {
      await pumpEditor(tester);

      await tester.tap(find.byKey(const Key('letterhead_mood_charm_target')));
      await tester.pumpAndSettle();
      expect(find.textContaining('心境感怀'), findsOneWidget);
      await tester.tap(find.text('欢欣'));
      await tester.pumpAndSettle();

      final charm = find.byKey(const Key('letterhead_mood_charm'));
      expect(find.descendant(of: charm, matching: find.text('欢')), findsOneWidget);
      expect(find.descendant(of: charm, matching: find.text('😄')), findsOneWidget);
      expect((await database.entriesDao.getEntryById(_entryId))!.mood, 5);
    });

    testWidgets('weather charm opens its picker, saves the choice and relabels itself', (tester) async {
      await pumpEditor(tester);

      await tester.tap(find.byKey(const Key('letterhead_weather_charm_target')));
      await tester.pumpAndSettle();
      expect(find.textContaining('天候气象'), findsOneWidget);
      await tester.tap(find.text('润雨'));
      await tester.pumpAndSettle();

      final charm = find.byKey(const Key('letterhead_weather_charm'));
      expect(find.descendant(of: charm, matching: find.text('润')), findsOneWidget);
      expect((await database.entriesDao.getEntryById(_entryId))!.weather, 'rainy');
    });

    testWidgets('labels the seal, date block and charms for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpEditor(tester);

      expect(find.bySemanticsLabel('岁次丙午 孟冬初二，轻触修改日期'), findsOneWidget);
      expect(find.bySemanticsLabel('2026年11月10日 周二，农历十月初二，立冬'), findsOneWidget);
      expect(find.bySemanticsLabel('天气晴明，轻触修改'), findsOneWidget);
      expect(find.bySemanticsLabel('心情怡然，轻触修改'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('continuation sheets carry no letterhead and pagination is unchanged', (tester) async {
      await fillThreeSheets();

      await pumpEditor(tester);
      expect(find.text('第 1 / 3 页'), findsOneWidget);
      expect(find.byKey(const Key('letterhead_date_seal')), findsOneWidget);

      await tester.tap(find.byKey(const Key('editor_page_corner_next')));
      await tester.pumpAndSettle();

      expect(find.text('第 2 / 3 页'), findsOneWidget);
      expect(find.byKey(const Key('letterhead_date_seal')), findsNothing);
      expect(find.byKey(const Key('letterhead_weather_charm')), findsNothing);
      expect(find.byKey(const Key('letterhead_solar_line')), findsNothing);
    });

    testWidgets('lined template with 29px line stride renders headerHeight 116.0 on frame 1 without post-frame drift', (tester) async {
      const linedEntryId = 'letterhead_lined_entry';
      await database.entriesDao.createEntry(
            EntriesCompanion.insert(
              id: linedEntryId,
              notebookId: 'notebook_default',
              templateId: 'template_lined_paper',
              title: const Value('秋水偶得'),
              contentDelta: '[]',
              plainText: '',
              entryDate: DateTime(2026, 11, 10, 10, 30),
              mood: const Value(4),
              weather: const Value('sunny'),
            ),
          );

      await pumpEditor(tester, entryId: linedEntryId, settle: false);

      // On frame 1, TemplateCanvasContainer must immediately have headerHeight == 116.0
      final canvasContainer = tester.widget<TemplateCanvasContainer>(
        find.byType(TemplateCanvasContainer),
      );
      expect(canvasContainer.headerHeight, equals(116.0));

      // Pump another single frame to verify no post-frame callback triggers a setState layout jitter.
      await tester.pump();

      final canvasContainerAfter = tester.widget<TemplateCanvasContainer>(
        find.byType(TemplateCanvasContainer),
      );
      expect(canvasContainerAfter.headerHeight, equals(116.0));
    });

    testWidgets('switching template updates geometry and headerHeight synchronously on frame 1 without post-frame drift', (tester) async {
      const switchEntryId = 'letterhead_switch_entry';
      await database.entriesDao.createEntry(
            EntriesCompanion.insert(
              id: switchEntryId,
              notebookId: 'notebook_default',
              templateId: 'template_lined_paper',
              title: const Value('换笺沉思'),
              contentDelta: '[]',
              plainText: '',
              entryDate: DateTime(2026, 11, 10, 10, 30),
              mood: const Value(4),
              weather: const Value('sunny'),
            ),
          );

      await pumpEditor(
        tester,
        entryId: switchEntryId,
        viewportSize: const Size(412, 800),
      );

      Finder editorCanvasContainer() => find.descendant(
            of: find.byType(EditorPaperCanvas),
            matching: find.byType(TemplateCanvasContainer),
          );

      // Initial lined template: 29px line stride -> headerHeight 116.0
      expect(
        tester.widget<TemplateCanvasContainer>(editorCanvasContainer()).headerHeight,
        equals(116.0),
      );

      // Open the scholar chest stationery drawer
      await tester.tap(find.byKey(const Key('top_bar_scholar_chest_button')));
      await tester.pumpAndSettle();

      // Switch to grid template (Weekly Review template with 24px line stride)
      final gridChip = find.byKey(const Key('chest_template_chip_template_weekly_review'));
      await tester.ensureVisible(gridChip);
      await tester.tap(gridChip);

      // Tapping triggers onSelectTemplate with setState.
      // Pump exactly 1 frame without pumpAndSettle.
      await tester.pump();

      // On this single frame, geometry must immediately update to grid: 24px stride -> 4 * 24.0 = 96.0
      expect(
        tester.widget<TemplateCanvasContainer>(editorCanvasContainer()).headerHeight,
        equals(96.0),
      );

      // Pump another single frame to verify zero post-frame setState was scheduled.
      await tester.pump();
      expect(
        tester.widget<TemplateCanvasContainer>(editorCanvasContainer()).headerHeight,
        equals(96.0),
      );
    });
  });
}
