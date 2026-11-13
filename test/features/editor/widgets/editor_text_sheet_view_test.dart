import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_geometry.dart';
import 'package:memodiary/features/editor/models/letterhead_data.dart';
import 'package:memodiary/features/editor/models/stationery_sheet_configs.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/widgets/editor_text_sheet_view.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';
import 'package:memodiary/features/templates/models/template_style.dart';

import '../../../helpers/editor_test_harness.dart';

void main() {
  late Directory tempDir;
  late SyncTestMediaSandboxService sandboxService;
  late TextEditingController titleController;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('editor_text_sheet_view_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDir);
    titleController = TextEditingController(text: '兰亭偶得');
  });

  tearDown(() {
    titleController.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  const templateStyle = TemplateStyle(
    type: TemplateBackgroundType.lined,
    backgroundColor: Colors.white,
    lineSpacing: 1.8,
    marginHorizontal: 24.0,
  );
  const typography = TypographySettings(fontSize: 16.0, lineSpacing: 1.8);

  final geometry = StationerySheetGeometry.resolve(
    canvasWidth: 360.0,
    restingDeskHeight: 400.0,
    templateStyle: templateStyle,
    typography: typography,
  );

  final themeConfig = StationerySheetThemeConfig.fromTemplateStyle(
    templateStyle: templateStyle,
    typography: typography,
  );

  StationeryLetterheadConfig buildLetterheadConfig() {
    return StationeryLetterheadConfig(
      data: LetterheadData.resolve(
        entryDate: DateTime(2026, 11, 10, 10, 30),
        weather: 'sunny',
        mood: 4,
      ),
      titleController: titleController,
      onDateChanged: (_) {},
      onMoodChanged: (_) {},
      onWeatherChanged: (_) {},
    );
  }

  testWidgets('OpeningSheet renders JournalLetterhead without running colophon', (tester) async {
    final openingSheet = OpeningSheet.empty();
    addTearDown(openingSheet.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: InkDiaryTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: geometry.cardSize.width,
            height: geometry.cardSize.height,
            child: EditorTextSheetView(
              sheet: openingSheet,
              sheetIndex: 0,
              geometry: geometry,
              themeConfig: themeConfig,
              letterheadConfig: buildLetterheadConfig(),
              mediaSandboxService: sandboxService,
              onSaveDraft: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(JournalLetterhead), findsOneWidget);
    expect(find.byKey(const Key('editor_continuation_colophon_header')), findsNothing);
  });

  testWidgets('ContinuationSheet positions running colophon directly using Positioned.fromRect', (tester) async {
    final continuationSheet = ContinuationSheet.empty(sheetIndex: 1);
    addTearDown(continuationSheet.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: InkDiaryTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: geometry.cardSize.width,
            height: geometry.cardSize.height,
            child: EditorTextSheetView(
              sheet: continuationSheet,
              sheetIndex: 1,
              geometry: geometry,
              themeConfig: themeConfig,
              letterheadConfig: buildLetterheadConfig(),
              mediaSandboxService: sandboxService,
              onSaveDraft: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(JournalLetterhead), findsNothing);
    final colophonFinder = find.byKey(const Key('editor_continuation_colophon_header'));
    expect(colophonFinder, findsOneWidget);
    expect(find.text('《兰亭偶得》 · 第 2 页'), findsOneWidget);

    // Verify positioned ancestor matches geometry.continuationColophonRect directly
    final positioned = tester.widget<Positioned>(
      find.ancestor(
        of: colophonFinder,
        matching: find.byType(Positioned),
      ).first,
    );
    expect(positioned.left, equals(geometry.continuationColophonRect.left));
    expect(positioned.top, equals(geometry.continuationColophonRect.top));
    expect(positioned.width, equals(geometry.continuationColophonRect.width));
    expect(positioned.height, equals(geometry.continuationColophonRect.height));
  });
}
