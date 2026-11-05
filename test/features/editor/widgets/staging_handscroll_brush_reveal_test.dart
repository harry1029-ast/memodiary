import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/controllers/brush_reveal_queue.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/widgets/brush_reveal/brush_reveal_choreography.dart';
import 'package:memodiary/features/editor/widgets/staging_handscroll.dart';
import '../../../helpers/editor_test_harness.dart';

SheetMediaItem _photo(String id) =>
    SheetMediaItem(id: id, mediaType: EphemeraMediaType.image, relativePath: 'photo.webp');
SheetMediaItem _video(String id) =>
    SheetMediaItem(id: id, mediaType: EphemeraMediaType.video, relativePath: 'video.mp4');

const _photoReveal = BrushRevealTimeline(isVideo: false);
const _videoReveal = BrushRevealTimeline(isVideo: true);

/// Bounded pumps through [total] (never `pumpAndSettle` during a reveal).
Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

Finder _cover(String id) => find.byKey(Key('brush_reveal_cover_$id'));
Finder _inkWash(String id) => find.byKey(Key('brush_reveal_ink_wash_$id'));
Finder _seal(String id) => find.byKey(Key('handscroll_video_seal_$id'));

void main() {
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;
  late BrushRevealQueue queue;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('handscroll_brush_reveal_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
    File('${tempDirectory.path}/photo.webp').writeAsBytesSync(kValid1x1PngBytes);
    File('${tempDirectory.path}/video.mp4').writeAsBytesSync(kValidMp4FtypBytes);
    queue = BrushRevealQueue();
  });

  tearDown(() {
    queue.dispose();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  Future<void> pumpHandscroll(
    WidgetTester tester,
    List<SheetMediaItem> items, {
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 160,
              child: StagingHandscroll(
                items: items,
                mediaSandboxService: sandboxService,
                activeSheetNumber: 1,
                brushReveals: queue,
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('a collected photo is uncovered by the brush, washed in ink, then blooms into colour', (tester) async {
    queue.enqueue('fresh');
    await pumpHandscroll(tester, [_photo('old'), _photo('fresh')]);

    expect(_cover('fresh'), findsOneWidget);
    expect(_cover('old'), findsNothing, reason: 'items already in the handscroll never replay');
    expect(_inkWash('old'), findsNothing);

    // Sweeps done and the cover faded: the print is still monochrome ink wash.
    await _pumpFor(tester, BrushRevealTimeline.kSweep * 5 + BrushRevealTimeline.kCoverFade + const Duration(milliseconds: 100));
    expect(_cover('fresh'), findsNothing);
    expect(_inkWash('fresh'), findsOneWidget);

    await _pumpFor(tester, BrushRevealTimeline.kBloom);
    expect(_inkWash('fresh'), findsNothing);
    expect(queue.hasPending, isFalse);
  });

  testWidgets('multi-pick reveals items one after another', (tester) async {
    queue
      ..enqueue('first')
      ..enqueue('second');
    await pumpHandscroll(tester, [_photo('first'), _photo('second')]);

    await _pumpFor(tester, _photoReveal.total - const Duration(milliseconds: 200));
    expect(_cover('first'), findsNothing);
    expect(_cover('second'), findsOneWidget, reason: 'waits under its cover');

    await _pumpFor(tester, const Duration(milliseconds: 400));
    expect(_cover('second'), findsOneWidget, reason: 'its own reveal has only just begun');

    await _pumpFor(tester, _photoReveal.total);
    expect(_cover('second'), findsNothing);
    expect(_inkWash('second'), findsNothing);
    expect(queue.hasPending, isFalse);
  });

  testWidgets('the handscroll glides to an off-screen slot before painting it', (tester) async {
    queue.enqueue('item_5');
    await pumpHandscroll(tester, [for (var index = 1; index <= 5; index++) _photo('item_$index')]);

    await _pumpFor(tester, StagingHandscroll.kGlideDuration + const Duration(milliseconds: 100));
    final handscrollRect = tester.getRect(find.byKey(const Key('staging_handscroll')));
    final slotRect = tester.getRect(find.byKey(const Key('handscroll_item_item_5')));
    expect(slotRect.right, lessThanOrEqualTo(handscrollRect.right + 0.5));
    expect(_cover('item_5'), findsOneWidget);

    await _pumpFor(tester, _photoReveal.total);
    expect(_cover('item_5'), findsNothing);
    expect(queue.hasPending, isFalse);
  });

  testWidgets('a collected video receives the cinnabar seal play stamp after its reveal', (tester) async {
    queue.enqueue('clip');
    await pumpHandscroll(tester, [_video('older_clip'), _video('clip')]);

    expect(_seal('older_clip'), findsOneWidget);
    expect(_seal('clip'), findsNothing);

    await _pumpFor(tester, _photoReveal.total + const Duration(milliseconds: 100));
    expect(_seal('clip'), findsNothing, reason: 'the seal waits ~260ms after the bloom');

    await _pumpFor(tester, _videoReveal.total - _photoReveal.total);
    expect(_seal('clip'), findsOneWidget);
    expect(queue.hasPending, isFalse);
  });

  testWidgets('with reduce-motion, collected items appear at once in full colour', (tester) async {
    queue
      ..enqueue('fresh')
      ..enqueue('clip');
    await pumpHandscroll(tester, [_photo('fresh'), _video('clip')], disableAnimations: true);

    expect(_cover('fresh'), findsNothing);
    expect(_inkWash('fresh'), findsNothing);
    expect(_cover('clip'), findsNothing);
    expect(_seal('clip'), findsOneWidget);
    expect(queue.hasPending, isFalse);
  });

  testWidgets('slot controls are inert while the item is being painted', (tester) async {
    final mounted = <String>[];
    queue.enqueue('fresh');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          height: 160,
          child: StagingHandscroll(
            items: [_photo('fresh')],
            mediaSandboxService: sandboxService,
            activeSheetNumber: 1,
            brushReveals: queue,
            onMountItem: (item) => mounted.add(item.id),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('handscroll_mount_fresh')), warnIfMissed: false);
    expect(mounted, isEmpty);

    await _pumpFor(tester, _photoReveal.total);
    await tester.tap(find.byKey(const Key('handscroll_mount_fresh')));
    expect(mounted, ['fresh']);
  });

  testWidgets('removing the handscroll mid-reveal stops the animation cleanly', (tester) async {
    queue
      ..enqueue('first')
      ..enqueue('second');
    await pumpHandscroll(tester, [_photo('first'), _photo('second')]);
    await _pumpFor(tester, const Duration(milliseconds: 400));

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpFor(tester, _photoReveal.total * 2);
    expect(tester.takeException(), isNull);
  });
}
