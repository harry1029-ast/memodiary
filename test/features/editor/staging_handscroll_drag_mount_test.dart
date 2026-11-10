import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:memodiary/features/editor/widgets/fullscreen_media_lightbox.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/tucked_prints_test_helpers.dart';
import '../../helpers/staged_editor_fixture.dart';
import '../../helpers/widget_test_helpers.dart';

const _entryId = 'drag_mount_entry';
const _viewport = Size(360.0, 780.0);

void main() {
  final fixture = StagedEditorFixture(entryId: _entryId);
  late StubEditorImagePicker picker;

  setUpAll(() {
    VideoPlayerPlatform.instance = FakeEditorVideoPlatform();
  });

  setUp(() async {
    await fixture.setUp();
    final photo = File('${fixture.tempDirectory.path}/picked_photo.png')..writeAsBytesSync(kValid1x1PngBytes);
    final video = File('${fixture.tempDirectory.path}/picked_video.mp4')..writeAsBytesSync(kValidMp4FtypBytes);
    picker = StubEditorImagePicker(
      imageResult: XFile(photo.path),
      videoResult: XFile(video.path),
    );
  });

  tearDown(fixture.tearDown);

  Future<void> openEditor(WidgetTester tester) => pumpEntryEditorScreen(
        tester,
        database: fixture.database,
        mediaSandboxService: fixture.sandboxService,
        entryId: _entryId,
        imagePicker: picker,
        viewportSize: _viewport,
      );

  Future<void> reopenEditor(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('editor_seal_done_btn')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await openEditor(tester);
  }

  Future<void> seedStagedPhotos(int count) => fixture.seedStagedPhotos(count);

  Future<void> mount(WidgetTester tester, String mediaId) async {
    await tester.tap(find.byKey(Key('handscroll_mount_$mediaId')));
    await tester.pumpAndSettle();
  }

  Finder handscrollItem(String mediaId) => find.byKey(Key('handscroll_item_$mediaId'));
  Finder snackBarText(Pattern pattern) => find.descendant(
        of: find.byType(SnackBar),
        matching: find.textContaining(pattern),
      );

  /// Long-presses [mediaId]'s print and drags it to [target], returning the
  /// still-held gesture so a test can inspect the hover state before release.
  Future<TestGesture> dragItemTo(WidgetTester tester, String mediaId, Offset target) async {
    final gesture = await tester.startGesture(tester.getCenter(handscrollItem(mediaId)));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 50));
    return gesture;
  }

  Offset sheetCenter(WidgetTester tester) => tester.getCenter(find.byKey(const Key('sheet_drop_target_0')));

  group('Long-press drag mount', () {
    testWidgets('hovering highlights the sheet; dropping mounts the item exactly as 📌 does and survives reopen',
        (tester) async {
      await seedStagedPhotos(2);
      await openEditor(tester);
      expect(find.byKey(const Key('sheet_drop_highlight')), findsNothing);

      final gesture = await dragItemTo(tester, 'seeded_0', sheetCenter(tester));
      expect(find.byKey(const Key('sheet_drop_highlight')), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sheet_drop_highlight')), findsNothing);
      expect(tuckedPrint('seeded_0'), findsOneWidget);
      expect(handscrollItem('seeded_0'), findsNothing);
      expect(handscrollItem('seeded_1'), findsOneWidget);

      await reopenEditor(tester);
      expect(tuckedPrint('seeded_0'), findsOneWidget);
    });

    testWidgets('dropping onto a full sheet is refused with a shake and SnackBar; the item stays staged',
        (tester) async {
      await seedStagedPhotos(4);
      await openEditor(tester);
      for (var index = 0; index < 3; index++) {
        await mount(tester, 'seeded_$index');
      }
      final restingLeft = tester.getTopLeft(tuckedPrint('seeded_0')).dx;

      final gesture = await dragItemTo(tester, 'seeded_3', sheetCenter(tester));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.getTopLeft(tuckedPrint('seeded_0')).dx, isNot(restingLeft));

      await tester.pumpAndSettle();
      expect(snackBarText('本页已满三影'), findsOneWidget);
      expect(handscrollItem('seeded_3'), findsOneWidget);
      expect(tuckedPrint('seeded_3'), findsNothing);
    });

    testWidgets('dropping outside the sheet cancels with no change', (tester) async {
      await seedStagedPhotos(1);
      await openEditor(tester);

      final gesture = await dragItemTo(tester, 'seeded_0', const Offset(180.0, 4.0));
      expect(find.byKey(const Key('sheet_drop_highlight')), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(handscrollItem('seeded_0'), findsOneWidget);
      expect(tuckedPrint('seeded_0'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a plain tap still opens the lightbox', (tester) async {
      await seedStagedPhotos(1);
      await openEditor(tester);

      await tester.tap(handscrollItem('seeded_0'));
      await tester.pumpAndSettle();

      expect(find.byType(FullscreenMediaLightbox), findsOneWidget);
    });

    testWidgets('a horizontal swipe scrolls the handscroll instead of dragging', (tester) async {
      await seedStagedPhotos(6);
      await openEditor(tester);
      final restingLeft = tester.getTopLeft(handscrollItem('seeded_1')).dx;

      await tester.drag(handscrollItem('seeded_1'), const Offset(-200.0, 0.0));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(handscrollItem('seeded_1')).dx, lessThan(restingLeft));
      expect(find.byKey(const Key('sheet_drop_highlight')), findsNothing);
      expect(tuckedPrint('seeded_1'), findsNothing);
    });

    testWidgets('📌 stays the accessible equivalent at 44px', (tester) async {
      final semantics = tester.ensureSemantics();
      await seedStagedPhotos(1);
      await openEditor(tester);

      await expectAccessibleTapTargets(tester, within: find.byKey(const Key('handscroll_mount_seeded_0')));
      await mount(tester, 'seeded_0');
      expect(tuckedPrint('seeded_0'), findsOneWidget);
      semantics.dispose();
    });
  });
}
