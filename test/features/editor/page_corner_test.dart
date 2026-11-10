import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import '../../helpers/editor_test_harness.dart';

const _entryId = 'page_corner_entry';
const _phoneViewport = Size(360.0, 780.0);
const _prevCorner = Key('editor_page_corner_prev');
const _nextCorner = Key('editor_page_corner_next');

/// Page Corners: the curled folds at the foot of each Stationery Sheet that
/// turn to the previous or next sheet. Keyboard behaviour on a corner tap is
/// covered in `desk_keyboard_layout_test.dart`.
void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('page_corner_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);

    // Enough lines to fill three sheets.
    final delta = Delta();
    for (int lineIndex = 1; lineIndex <= 29; lineIndex++) {
      delta.insert('第${lineIndex.toString().padLeft(2, '0')}行折角翻页墨迹\n');
    }
    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: _entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('折角'),
            contentDelta: jsonEncode(delta.toJson()),
            plainText: '折角翻页墨迹',
            entryDate: DateTime(2026, 11, 10, 20),
          ),
        );
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> openEditor(WidgetTester tester) => pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: _entryId,
        viewportSize: _phoneViewport,
      );

  Future<void> tapCorner(WidgetTester tester, Key corner) async {
    await tester.tap(find.byKey(corner));
    await tester.pumpAndSettle();
  }

  testWidgets('the first sheet shows only the next corner, a middle sheet both, the last only the previous', (tester) async {
    await openEditor(tester);
    expect(find.text('第 1 / 3 页'), findsOneWidget);
    expect(find.byKey(_prevCorner), findsNothing);
    expect(find.byKey(_nextCorner), findsOneWidget);

    await tapCorner(tester, _nextCorner);
    expect(find.text('第 2 / 3 页'), findsOneWidget);
    expect(find.byKey(_prevCorner), findsOneWidget);
    expect(find.byKey(_nextCorner), findsOneWidget);

    await tapCorner(tester, _nextCorner);
    expect(find.text('第 3 / 3 页'), findsOneWidget);
    expect(find.byKey(_prevCorner), findsOneWidget);
    expect(find.byKey(_nextCorner), findsNothing);

    await tapCorner(tester, _prevCorner);
    expect(find.text('第 2 / 3 页'), findsOneWidget);
  });

  testWidgets('swiping between sheets still turns the page', (tester) async {
    await openEditor(tester);

    await tester.fling(find.byType(PageView), const Offset(-300.0, 0.0), 1000.0);
    await tester.pumpAndSettle();
    expect(find.text('第 2 / 3 页'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(300.0, 0.0), 1000.0);
    await tester.pumpAndSettle();
    expect(find.text('第 1 / 3 页'), findsOneWidget);
  });

  testWidgets('each corner is a 44x44 target reaching onto the desk, and its fold stays clear of the last Paper Heart row', (tester) async {
    await openEditor(tester);
    await tapCorner(tester, _nextCorner);

    final cardRect = tester.getRect(find.byType(TemplateCanvasContainer).first);
    final metrics = tester.widget<TemplateCanvasContainer>(find.byType(TemplateCanvasContainer).first).layoutMetrics!;
    final paperHeart = metrics.innerFrameRect.shift(cardRect.topLeft);
    final lastRow = Rect.fromLTRB(
      paperHeart.left,
      paperHeart.bottom - metrics.lineStridePx,
      paperHeart.right,
      paperHeart.bottom,
    );

    for (final side in ['prev', 'next']) {
      final targetRect = tester.getRect(find.byKey(Key('editor_page_corner_$side')));
      expect(targetRect.width, greaterThanOrEqualTo(44.0), reason: '$side target width');
      expect(targetRect.height, greaterThanOrEqualTo(44.0), reason: '$side target height');
      expect(targetRect.bottom, greaterThan(cardRect.bottom), reason: 'the $side target reaches down onto the desk');
      expect(targetRect.overlaps(lastRow), isFalse, reason: 'the $side target never steals taps from the last row');

      final foldRect = tester.getRect(find.byKey(Key('editor_page_corner_fold_$side')));
      expect(foldRect.width, closeTo(20.0, 4.0));
      expect(foldRect.bottom, closeTo(cardRect.bottom, 0.5), reason: 'the $side fold sits at the foot of the sheet');
      expect(foldRect.top, greaterThan(lastRow.top), reason: 'the $side fold stays within the bottom margin');
      // The fold is creased at 45°, so it covers only the points whose
      // distances from the sheet's side and foot sum to less than its leg.
      final fromSide = side == 'prev' ? lastRow.left - cardRect.left : cardRect.right - lastRow.right;
      final fromFoot = cardRect.bottom - lastRow.bottom;
      expect(fromSide + fromFoot, greaterThanOrEqualTo(foldRect.width), reason: 'the $side fold never covers the last row');
    }
    expect(tester.getRect(find.byKey(const Key('editor_page_corner_fold_prev'))).left, closeTo(cardRect.left, 0.5));
    expect(tester.getRect(find.byKey(const Key('editor_page_corner_fold_next'))).right, closeTo(cardRect.right, 0.5));
  });

  testWidgets('the corners are announced as 上卷 and 下卷 with the target sheet number', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    await openEditor(tester);
    await tapCorner(tester, _nextCorner);

    expect(find.bySemanticsLabel('上卷 · 第 1 页'), findsOneWidget);
    expect(find.bySemanticsLabel('下卷 · 第 3 页'), findsOneWidget);
    semanticsHandle.dispose();
  });

  testWidgets('no side chevrons remain on the sheet', (tester) async {
    await openEditor(tester);
    await tapCorner(tester, _nextCorner);

    expect(find.byKey(const Key('editor_prev_sheet_btn')), findsNothing);
    expect(find.byKey(const Key('editor_next_sheet_btn')), findsNothing);
    expect(find.text('‹'), findsNothing);
    expect(find.text('›'), findsNothing);
  });
}
