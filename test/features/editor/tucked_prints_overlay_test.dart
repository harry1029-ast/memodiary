import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';
import 'package:memodiary/features/editor/widgets/fullscreen_media_lightbox.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/tucked_prints_test_helpers.dart';
import '../../helpers/widget_test_helpers.dart';

const _entryId = 'tucked_prints_overlay_entry';
const _viewport = Size(360.0, 780.0);

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUpAll(() {
    VideoPlayerPlatform.instance = FakeEditorVideoPlatform();
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('tucked_prints_overlay_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  Future<void> openEditor(WidgetTester tester, {int mounted = 0, Set<String> videoIds = const {}}) async {
    await seedMountedEntry(database, tempDirectory, entryId: _entryId, mounted: mounted, videoIds: videoIds);
    await pumpEntryEditorScreen(
      tester,
      database: database,
      mediaSandboxService: sandboxService,
      entryId: _entryId,
      viewportSize: _viewport,
    );
  }

  TextStationerySheet firstSheet(WidgetTester tester) => tester
      .widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas))
      .coordinator
      .sheets
      .whereType<TextStationerySheet>()
      .first;

  Finder handscrollItem(String mediaId) => find.byKey(Key('handscroll_item_$mediaId'));

  group('Fanned overlay', () {
    testWidgets('tapping the fan opens an overlay fanning out every mounted item at about 96px', (tester) async {
      await openEditor(tester, mounted: 5);

      await openTuckedPrintsOverlay(tester);

      expect(tuckedPrintsOverlay, findsOneWidget);
      for (var index = 0; index < 5; index++) {
        final size = tester.getSize(overlayPrint('print_$index'));
        expect(size.width, closeTo(96.0, 8.0), reason: 'print_$index');
      }
      // The overlay is a modal over the desk: it hides the handscroll from hits.
      expect(find.byType(FullscreenMediaLightbox), findsNothing);
    });

    testWidgets('a video\'s fanned print keeps its cinnabar ▶ stamp', (tester) async {
      await openEditor(tester, mounted: 2, videoIds: {'print_1'});

      await openTuckedPrintsOverlay(tester);

      expect(
        find.descendant(of: overlayPrint('print_1'), matching: find.byIcon(Icons.play_arrow_rounded)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: overlayPrint('print_0'), matching: find.byIcon(Icons.play_arrow_rounded)),
        findsNothing,
      );
    });

    testWidgets('tapping a print opens the lightbox on that item and the overlay stays beneath', (tester) async {
      await openEditor(tester, mounted: 3);
      await openTuckedPrintsOverlay(tester);

      await tester.tap(overlayPrint('print_1'));
      await tester.pumpAndSettle();

      final lightbox = tester.widget<FullscreenMediaLightbox>(find.byType(FullscreenMediaLightbox));
      expect(lightbox.items.map((item) => item.id), ['print_0', 'print_1', 'print_2']);
      expect(lightbox.initialIndex, 1);

      await tester.tap(find.byKey(const Key('fullscreen_lightbox_close_button')));
      await tester.pumpAndSettle();
      expect(find.byType(FullscreenMediaLightbox), findsNothing);
      expect(tuckedPrintsOverlay, findsOneWidget);
    });

    testWidgets('↩ 揭回 returns a print to the handscroll, updating the open overlay and the fan in place', (tester) async {
      await openEditor(tester, mounted: 3);
      await openTuckedPrintsOverlay(tester);

      await tester.tap(overlayUnmount('print_1'));
      await tester.pumpAndSettle();

      expect(tuckedPrintsOverlay, findsOneWidget);
      expect(overlayPrint('print_1'), findsNothing);
      expect(overlayPrint('print_0'), findsOneWidget);
      expect(overlayPrint('print_2'), findsOneWidget);

      await tester.tapAt(const Offset(4.0, 300.0));
      await tester.pumpAndSettle();

      expect(tuckedPrintsOverlay, findsNothing);
      expect(tuckedPrint('print_1'), findsNothing);
      expect(tuckedPrint('print_0'), findsOneWidget);
      expect(handscrollItem('print_1'), findsOneWidget);
    });

    testWidgets('unmounting a legacy overflow item lets the next one into the resting fan', (tester) async {
      await openEditor(tester, mounted: 5);

      await unmountTuckedPrint(tester, 'print_0');

      expect(overlayPrint('print_0'), findsNothing);
      expect(find.byKey(const Key('tucked_prints_overlay')), findsOneWidget);
      await tester.tapAt(const Offset(4.0, 300.0));
      await tester.pumpAndSettle();
      expect(tuckedPrint('print_3'), findsOneWidget);
      expect(find.descendant(of: tuckedPrintsFan, matching: find.text('+1')), findsOneWidget);
    });

    testWidgets('the overlay closes when the last print is unmounted', (tester) async {
      await openEditor(tester, mounted: 2);

      await unmountTuckedPrint(tester, 'print_0');
      expect(tuckedPrintsOverlay, findsOneWidget);
      await tester.tap(overlayUnmount('print_1'));
      await tester.pumpAndSettle();

      expect(tuckedPrintsOverlay, findsNothing);
      expect(tuckedPrintsFan, findsNothing);
      expect(handscrollItem('print_0'), findsOneWidget);
      expect(handscrollItem('print_1'), findsOneWidget);
    });

    testWidgets('tapping outside dismisses the overlay and leaves the prints mounted', (tester) async {
      await openEditor(tester, mounted: 2);
      await openTuckedPrintsOverlay(tester);

      await tester.tapAt(const Offset(4.0, 300.0));
      await tester.pumpAndSettle();

      expect(tuckedPrintsOverlay, findsNothing);
      expect(tuckedPrint('print_0'), findsOneWidget);
      expect(tuckedPrint('print_1'), findsOneWidget);
    });

    testWidgets('the back gesture dismisses the overlay', (tester) async {
      await openEditor(tester, mounted: 2);
      await openTuckedPrintsOverlay(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(tuckedPrintsOverlay, findsNothing);
      expect(find.byType(EditorPaperCanvas), findsOneWidget);
      expect(tuckedPrint('print_0'), findsOneWidget);
    });

    testWidgets('each print and ↩ is at least 44×44 with its own scoped label', (tester) async {
      final semantics = tester.ensureSemantics();
      await openEditor(tester, mounted: 2);
      await openTuckedPrintsOverlay(tester);

      for (var index = 0; index < 2; index++) {
        for (final finder in [overlayPrint('print_$index'), overlayUnmount('print_$index')]) {
          final size = tester.getSize(finder);
          expect(size.width, greaterThanOrEqualTo(44.0));
          expect(size.height, greaterThanOrEqualTo(44.0));
        }
      }
      expect(find.bySemanticsLabel(RegExp(r'^揭回画卷：本页第 1 影 · 影札$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^揭回画卷：本页第 2 影 · 影札$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^本页第 1 影 · 影札，点按查看$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^本页第 2 影 · 影札，点按查看$')), findsOneWidget);
      await expectAccessibleTapTargets(tester, within: tuckedPrintsOverlay);
      semantics.dispose();
    });
  });

  group('Keyboard safety', () {
    Iterable<String> inputCalls(WidgetTester tester) => tester.testTextInput.log.map((call) => call.method);

    Future<TextStationerySheet> startWriting(WidgetTester tester) async {
      final sheet = firstSheet(tester);
      sheet.focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(sheet.focusNode.hasFocus, isTrue);
      tester.testTextInput.log.clear();
      return sheet;
    }

    testWidgets('opening, unmounting and dismissing release writing focus and never show the keyboard', (tester) async {
      await openEditor(tester, mounted: 2);
      final sheet = await startWriting(tester);

      await openTuckedPrintsOverlay(tester);
      expect(sheet.focusNode.hasFocus, isFalse);
      expect(inputCalls(tester), isNot(contains('TextInput.show')));

      await tester.tap(overlayUnmount('print_0'));
      await tester.pumpAndSettle();
      expect(inputCalls(tester), isNot(contains('TextInput.show')));

      await tester.tapAt(const Offset(4.0, 300.0));
      await tester.pumpAndSettle();
      expect(tuckedPrintsOverlay, findsNothing);
      expect(sheet.focusNode.hasFocus, isFalse);
      expect(inputCalls(tester), isNot(contains('TextInput.show')));
    });

    testWidgets('opening the overlay while the keyboard is hidden does not summon it', (tester) async {
      await openEditor(tester, mounted: 1);
      tester.testTextInput.log.clear();

      await openTuckedPrintsOverlay(tester);
      await tester.tap(overlayUnmount('print_0'));
      await tester.pumpAndSettle();

      expect(tuckedPrintsOverlay, findsNothing);
      expect(inputCalls(tester), isNot(contains('TextInput.show')));
    });
  });
}
