import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/models/mount_marker.dart';
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

/// Navigates the stationery sheet pager to [sheetNumber] of [totalSheets] using
/// the bottom-corner page-turn folds.
Future<void> goToSheet(WidgetTester tester, int sheetNumber, int totalSheets) async {
  for (var attempt = 0; attempt < totalSheets; attempt++) {
    if (find.text('第 $sheetNumber / $totalSheets 页').evaluate().isNotEmpty) return;
    final textWidgets = tester.widgetList<Text>(find.textContaining(' / $totalSheets 页'));
    if (textWidgets.isEmpty) return;
    final match = RegExp(r'第 (\d+) /').firstMatch(textWidgets.first.data!);
    if (match == null) return;
    final current = int.parse(match.group(1)!);
    await tester.tap(find.byKey(Key(
      current < sheetNumber ? 'editor_page_corner_next' : 'editor_page_corner_prev',
    )));
    await tester.pumpAndSettle();
  }
}

/// Seeds an entry whose first passage carries [mounted] mount markers
/// (`print_0` ...) and [staged] attachments without markers (`staged_0` ...),
/// with sandbox files for each. [videoIds] are attached as videos.
/// Optionally takes an explicit [delta] or custom [stagedIds].
Future<void> seedMountedEntry(
  AppDatabase database,
  Directory sandboxDirectory, {
  required String entryId,
  Delta? delta,
  int mounted = 0,
  int staged = 0,
  List<String>? stagedIds,
  Set<String> videoIds = const {},
}) async {
  final effectiveMountedIds = [for (var index = 0; index < mounted; index++) 'print_$index'];
  final effectiveStagedIds = stagedIds ?? [for (var index = 0; index < staged; index++) 'staged_$index'];
  final contentDeltaJson = delta != null
      ? jsonEncode(delta.toJson())
      : jsonEncode([
          {'insert': '雨巷。'},
          for (final mediaId in effectiveMountedIds)
            {
              'insert': {'mount': mediaId},
            },
          {'insert': '\n'},
        ]);
  final derivedPlainText = delta != null
      ? Document.fromDelta(MountMarker.strip(delta)).toPlainText().trim()
      : '雨巷。';
  await database.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: entryId,
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('江南雨景'),
          contentDelta: contentDeltaJson,
          plainText: derivedPlainText,
          entryDate: DateTime(2026, 11, 4, 21, 30),
        ),
      );
  for (final mediaId in [...effectiveMountedIds, ...effectiveStagedIds]) {
    final isVideo = videoIds.contains(mediaId);
    final relativePath = isVideo ? 'media/$mediaId.mp4' : 'media/$mediaId.webp';
    File('${sandboxDirectory.path}/$relativePath')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(isVideo ? kValidMp4FtypBytes : kValid1x1PngBytes);
    await database.mediaOcrDao.attachMediaToEntry(
      id: mediaId,
      entryId: entryId,
      relativePath: relativePath,
      mediaType: isVideo ? 'video' : 'image',
    );
  }
}
