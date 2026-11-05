import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/widgets/brush_reveal/brush_reveal_choreography.dart';
import 'package:memodiary/features/editor/widgets/staging_handscroll.dart';
import '../../helpers/editor_test_harness.dart';

const _entryId = 'brush_reveal_entry';
const _viewport = Size(360.0, 780.0);
const _photoReveal = BrushRevealTimeline(isVideo: false);

/// Bounded pumps through [total] (never `pumpAndSettle` during a reveal).
Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;
  late File photo;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('brush_reveal_collect_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
    photo = File('${tempDirectory.path}/picked_photo.png')..writeAsBytesSync(kValid1x1PngBytes);

    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: _entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('泼墨'),
            contentDelta: jsonEncode((Delta()..insert('云山墨戏。\n')).toJson()),
            plainText: '云山墨戏。',
            entryDate: DateTime(2026, 11, 6, 21),
          ),
        );
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  Future<void> openEditor(WidgetTester tester, {int picks = 1}) => pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: _entryId,
        imagePicker: StubEditorImagePicker(
          imageResult: XFile(photo.path),
          multiImageResults: [for (var index = 0; index < picks; index++) XFile(photo.path)],
        ),
        viewportSize: _viewport,
      );

  Future<void> reopenEditor(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('editor_seal_done_btn')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await openEditor(tester);
  }

  /// Collects from the gallery, pumping only until the picked items land.
  Future<void> startCollecting(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('writing_dock_photo_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('相册选撷 · Photo Gallery'));
    await _pumpFor(tester, const Duration(milliseconds: 300));
  }

  Future<List<String>> attachmentIds() async =>
      (await database.getMediaForEntry(_entryId)).map((row) => row.id).toList();

  Finder cover(String id) => find.byKey(Key('brush_reveal_cover_$id'));
  final anyCover = find.byWidgetPredicate(
    (widget) => widget.key is ValueKey<String> && (widget.key! as ValueKey<String>).value.startsWith('brush_reveal_cover_'),
  );
  double unrollFraction(WidgetTester tester) =>
      (tester.widget<ClipRect>(find.byKey(const Key('staging_handscroll_unroll'))).clipper! as HandscrollUnrollClipper)
          .fraction;

  testWidgets('the first collect unrolls the scroll, then paints the item; reopening never replays it', (tester) async {
    await openEditor(tester);
    await startCollecting(tester);

    final mediaId = (await attachmentIds()).single;
    expect(unrollFraction(tester), lessThan(1.0));
    expect(cover(mediaId), findsOneWidget);

    await _pumpFor(tester, StagingHandscroll.kUnrollDuration + _photoReveal.total);
    expect(unrollFraction(tester), 1.0);
    expect(anyCover, findsNothing);

    await reopenEditor(tester);
    expect(find.byKey(Key('handscroll_item_$mediaId')), findsOneWidget);
    expect(anyCover, findsNothing);
    expect(unrollFraction(tester), 1.0);
  });

  testWidgets('collecting into an open handscroll paints only the new slot, without the unroll', (tester) async {
    await openEditor(tester);
    await startCollecting(tester);
    await _pumpFor(tester, StagingHandscroll.kUnrollDuration + _photoReveal.total);
    final firstId = (await attachmentIds()).single;

    await startCollecting(tester);
    final secondId = (await attachmentIds()).firstWhere((id) => id != firstId);
    expect(unrollFraction(tester), 1.0);
    expect(cover(secondId), findsOneWidget);
    expect(cover(firstId), findsNothing);

    await _pumpFor(tester, _photoReveal.total);
    expect(anyCover, findsNothing);
  });

  testWidgets('multi-pick paints items one after another', (tester) async {
    await openEditor(tester, picks: 2);
    await startCollecting(tester);
    final ids = await attachmentIds();
    expect(ids, hasLength(2));
    expect(cover(ids[0]), findsOneWidget);
    expect(cover(ids[1]), findsOneWidget);

    await _pumpFor(tester, StagingHandscroll.kUnrollDuration + _photoReveal.total);
    expect(cover(ids[0]), findsNothing);
    expect(cover(ids[1]), findsOneWidget);

    await _pumpFor(tester, _photoReveal.total);
    expect(anyCover, findsNothing);
  });

  testWidgets('mounting and unmounting move the item without replaying its reveal', (tester) async {
    await openEditor(tester);
    await startCollecting(tester);
    await _pumpFor(tester, StagingHandscroll.kUnrollDuration + _photoReveal.total);
    final mediaId = (await attachmentIds()).single;

    await tester.tap(find.byKey(Key('handscroll_mount_$mediaId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('mount_strip_unmount_$mediaId')));
    await tester.pump();

    expect(find.byKey(Key('handscroll_item_$mediaId')), findsOneWidget);
    expect(anyCover, findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('an item unmounted by reflow rejoins the handscroll without replaying its reveal', (tester) async {
    File('${tempDirectory.path}/media/plum.webp')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(kValid1x1PngBytes);
    await database.attachMediaToEntry(id: 'plum', entryId: _entryId, relativePath: 'media/plum.webp');
    await (database.update(database.entries)..where((row) => row.id.equals(_entryId))).write(
          EntriesCompanion(
            contentDelta: Value(jsonEncode((Delta()
                  ..insert('断桥残雪')
                  ..insert({'mount': 'plum'})
                  ..insert('\n'))
                .toJson())),
          ),
        );
    await openEditor(tester);
    expect(find.byKey(const Key('mount_strip_item_plum')), findsOneWidget);

    tester
        .widget<QuillEditor>(find.byType(QuillEditor).first)
        .controller
        .replaceText(2, 3, '', const TextSelection.collapsed(offset: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('handscroll_item_plum')), findsOneWidget);
    expect(anyCover, findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('with reduce-motion the collected item appears at once in full colour', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await openEditor(tester);
    await startCollecting(tester);

    final mediaId = (await attachmentIds()).single;
    expect(find.byKey(Key('handscroll_item_$mediaId')), findsOneWidget);
    expect(anyCover, findsNothing);
    expect(find.byKey(Key('brush_reveal_ink_wash_$mediaId')), findsNothing);
    expect(unrollFraction(tester), 1.0);
  });

  testWidgets('leaving the editor mid-reveal stops the animation cleanly', (tester) async {
    await openEditor(tester, picks: 3);
    await startCollecting(tester);
    expect(anyCover, findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpFor(tester, _photoReveal.total * 3);
    expect(tester.takeException(), isNull);
  });
}
