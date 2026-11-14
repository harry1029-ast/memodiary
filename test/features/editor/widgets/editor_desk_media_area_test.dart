import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/controllers/editor_chrome_controller.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/models/desk_media_handlers.dart';
import 'package:memodiary/features/editor/widgets/editor_desk_media_area.dart';
import '../../../helpers/editor_test_harness.dart';

void main() {
  late Directory tempDirectory;

  setUp(() => tempDirectory = Directory.systemTemp.createTempSync('desk_media_area_test_'));
  tearDown(() => tempDirectory.deleteSync(recursive: true));

  final pullTab = find.byKey(const Key('workstation_pull_tab'));
  final pill = find.byKey(const Key('workstation_restore_pill'));
  final dockRestoreTab = find.byKey(const Key('writing_dock_restore_tab'));

  Future<EditorChromeController> pumpArea(
    WidgetTester tester, {
    bool isWorkstationCollapsed = false,
    bool isKeyboardVisible = false,
    bool isWritingDockVisible = true,
    List<SheetMediaItem> mountedItems = const [],
    List<SheetMediaItem> stagedItems = const [],
    DeskMediaHandlers handlers = const DeskMediaHandlers(),
  }) async {
    final chrome = EditorChromeController();
    addTearDown(chrome.dispose);
    if (isWorkstationCollapsed) chrome.collapseWorkstation();
    if (isKeyboardVisible) chrome.syncKeyboardInset(300.0);
    if (!isWritingDockVisible) chrome.setWritingDockVisible(false);

    final budget = chrome.resolveDeskBudget(
      restingDeskHeight: 700.0,
      sheetHeight: 400.0,
      sealBlockHeight: 64.0,
      isHandscrollEmpty: stagedItems.isEmpty,
      isLastSheet: false,
    );
    await tester.pumpWidget(MaterialApp(
      theme: InkDiaryTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 400.0,
          height: 700.0,
          child: EditorDeskMediaArea(
            budget: budget,
            mountedItems: mountedItems,
            stagedItems: stagedItems,
            mediaSandboxService: SyncTestMediaSandboxService(tempDir: tempDirectory),
            activeSheetNumber: 1,
            chrome: chrome,
            handlers: handlers,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return chrome;
  }

  group('EditorDeskMediaArea', () {
    testWidgets('a docked workstation shows its pull tab, which puts it away', (tester) async {
      final chrome = await pumpArea(tester);

      expect(pill, findsNothing);
      await tester.tap(pullTab);
      expect(chrome.isWorkstationCollapsed, isTrue);
    });

    testWidgets('a collapsed workstation shows only the Restore Pill, which brings it back', (tester) async {
      final chrome = await pumpArea(tester, isWorkstationCollapsed: true);

      expect(pullTab, findsNothing);
      await tester.tap(pill);
      expect(chrome.isWorkstationCollapsed, isFalse);
    });

    testWidgets('while the keyboard steps the docked workstation aside, neither control is built', (tester) async {
      await pumpArea(tester, isKeyboardVisible: true);

      expect(tester.takeException(), isNull);
      expect(pullTab, findsNothing);
      expect(pill, findsNothing);
    });

    testWidgets('shows the Writing Dock restore tab only while dock is hidden and keyboard closed', (tester) async {
      final chrome = await pumpArea(tester, isWritingDockVisible: false);

      expect(dockRestoreTab, findsOneWidget);
      await tester.tap(dockRestoreTab);
      expect(chrome.isWritingDockVisible, isTrue);

      await pumpArea(tester, isWritingDockVisible: false, isKeyboardVisible: true);
      expect(dockRestoreTab, findsNothing);
    });

    testWidgets('forwards DeskMediaHandlers.onCaptionChanged to staged and mounted lightboxes', (tester) async {
      final captionUpdates = <(String, String)>[];
      const stagedItem = SheetMediaItem(
        id: 'staged_1',
        mediaType: EphemeraMediaType.image,
        relativePath: 'media/staged_1.webp',
      );
      const mountedItem = SheetMediaItem(
        id: 'mounted_1',
        mediaType: EphemeraMediaType.image,
        relativePath: 'media/mounted_1.webp',
      );

      await pumpArea(
        tester,
        mountedItems: const [mountedItem],
        stagedItems: const [stagedItem],
        handlers: DeskMediaHandlers(
          onCaptionChanged: (mediaId, newCaption) => captionUpdates.add((mediaId, newCaption)),
        ),
      );

      await tester.tap(find.byKey(const Key('handscroll_item_staged_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lightbox_caption_edit_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('lightbox_caption_input')), '暮春西湖');
      await tester.tap(find.byKey(const Key('lightbox_caption_save_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fullscreen_lightbox_close_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tucked_prints')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tucked_overlay_print_mounted_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lightbox_caption_edit_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('lightbox_caption_input')), '断桥残雪');
      await tester.tap(find.byKey(const Key('lightbox_caption_save_button')));
      await tester.pumpAndSettle();

      expect(captionUpdates, equals([
        ('staged_1', '暮春西湖'),
        ('mounted_1', '断桥残雪'),
      ]));
    });
  });
}
