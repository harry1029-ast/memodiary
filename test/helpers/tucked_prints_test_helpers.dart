import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'editor_test_harness.dart';

/// The resting fan of Tucked Prints above the active Stationery Sheet (one target).
final Finder tuckedPrintsFan = find.byKey(const Key('tucked_prints'));

/// One Tucked Print of the active sheet's resting fan, by attachment id.
Finder tuckedPrint(String mediaId) => find.byKey(Key('tucked_print_$mediaId'));

/// The fanned overlay opened by tapping the resting fan.
final Finder tuckedPrintsOverlay = find.byKey(const Key('tucked_prints_overlay'));

/// One print in the fanned overlay, by attachment id.
Finder overlayPrint(String mediaId) => find.byKey(Key('tucked_overlay_print_$mediaId'));

/// The ↩ 揭回 control of a print in the fanned overlay, by attachment id.
Finder overlayUnmount(String mediaId) => find.byKey(Key('tucked_overlay_unmount_$mediaId'));

/// Opens the fanned overlay by tapping the resting fan.
Future<void> openTuckedPrintsOverlay(WidgetTester tester) async {
  await tester.tap(tuckedPrintsFan);
  await tester.pumpAndSettle();
}

/// Unmounts [mediaId] back into the Staging Handscroll the way the diarist
/// does: open the fanned overlay if it is not open, then tap the print's ↩ 揭回.
/// Leaves the overlay open unless that was the last print.
Future<void> unmountTuckedPrint(WidgetTester tester, String mediaId) async {
  if (tuckedPrintsOverlay.evaluate().isEmpty) await openTuckedPrintsOverlay(tester);
  await tester.tap(overlayUnmount(mediaId));
  await tester.pumpAndSettle();
}

/// Seeds an entry whose first passage carries [mounted] mount markers
/// (`print_0` ...) and [staged] attachments without markers (`staged_0` ...),
/// with sandbox files for each. [videoIds] are attached as videos.
Future<void> seedMountedEntry(
  AppDatabase database,
  Directory sandboxDirectory, {
  required String entryId,
  int mounted = 0,
  int staged = 0,
  Set<String> videoIds = const {},
}) async {
  final mountedIds = [for (var index = 0; index < mounted; index++) 'print_$index'];
  final stagedIds = [for (var index = 0; index < staged; index++) 'staged_$index'];
  await database.into(database.entries).insert(
        EntriesCompanion.insert(
          id: entryId,
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('江南雨景'),
          contentDelta: jsonEncode([
            {'insert': '雨巷。'},
            for (final mediaId in mountedIds)
              {
                'insert': {'mount': mediaId},
              },
            {'insert': '\n'},
          ]),
          plainText: '雨巷。',
          entryDate: DateTime(2026, 11, 4, 21, 30),
        ),
      );
  for (final mediaId in [...mountedIds, ...stagedIds]) {
    final isVideo = videoIds.contains(mediaId);
    final relativePath = isVideo ? 'media/$mediaId.mp4' : 'media/$mediaId.webp';
    File('${sandboxDirectory.path}/$relativePath')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(isVideo ? kValidMp4FtypBytes : kValid1x1PngBytes);
    await database.attachMediaToEntry(
      id: mediaId,
      entryId: entryId,
      relativePath: relativePath,
      mediaType: isVideo ? 'video' : 'image',
    );
  }
}
