import 'package:flutter/widgets.dart' show TextSelection;
import 'package:flutter_quill/flutter_quill.dart' show QuillController;
import 'package:flutter_quill/quill_delta.dart';

import '../domain/stationery_sheet_descriptor.dart';
import '../models/mount_marker.dart';
import 'editor_pagination_models.dart';

/// Resolves mount markers (ADR-0009) to the Stationery Sheets that show their
/// items, for [EditorDeltaPartitioner] at layout time and for reflow while the
/// diarist edits.
class SheetMountResolver {
  const SheetMountResolver._();

  /// Resolves which items each text sheet shows from the mount markers in the
  /// sheets' Deltas, replacing every sheet's `mediaAttachments`:
  ///
  /// - Items show in marker order on the sheet holding their marker, at most
  ///   three per sheet; extras cascade onto the following text sheet.
  /// - Extras past the last text sheet are unmounted (their markers removed)
  ///   when [unmountLastSheetOverflow] is set, unless listed in
  ///   [toleratedOverflowIds]; otherwise they stay on the last sheet, tolerated.
  ///   No sheet is ever allocated to host media.
  /// - A marker repeated for one item (e.g. a pasted copy) is removed, keeping
  ///   the occurrence on its [previousMarkerHomes] sheet, else the first.
  /// - Markers for unknown items are left for [stripOrphanMarkers] at save.
  ///
  /// Items backing a legacy inline embed (an [EphemeraSheet]) are neither
  /// mounted nor staged.
  static MountResolution resolveMounts({
    required List<StationerySheetDescriptor> sheets,
    required List<SheetMediaItem> media,
    bool unmountLastSheetOverflow = false,
    Set<String> toleratedOverflowIds = const {},
    Map<String, QuillController> previousMarkerHomes = const {},
  }) {
    final legacyEmbedPaths = sheets
        .whereType<EphemeraSheet>()
        .map((ephemera) => ephemera.sandboxedRelativePath)
        .toSet();
    final mediaById = {
      for (final item in media)
        if (!legacyEmbedPaths.contains(item.relativePath)) item.id: item,
    };
    final textSheets = sheets.whereType<TextStationerySheet>().toList();

    final markersBySheet = <TextStationerySheet, List<({int offset, String mediaId})>>{};
    for (final sheet in textSheets) {
      var offset = 0;
      final found = <({int offset, String mediaId})>[];
      for (final operation in sheet.delta.operations) {
        final mediaId = MountMarker.mediaIdOf(operation);
        if (mediaId != null && mediaById.containsKey(mediaId)) {
          found.add((offset: offset, mediaId: mediaId));
        }
        offset += operation.length ?? 0;
      }
      markersBySheet[sheet] = found;
    }

    final homes = <String, TextStationerySheet>{};
    for (final sheet in textSheets) {
      for (final marker in markersBySheet[sheet]!) {
        final previousHome = previousMarkerHomes[marker.mediaId];
        final current = homes[marker.mediaId];
        if (current == null ||
            (!identical(current.controller, previousHome) &&
                identical(sheet.controller, previousHome))) {
          homes[marker.mediaId] = sheet;
        }
      }
    }

    final removals = <TextStationerySheet, List<int>>{};
    final anchoredBySheet = <TextStationerySheet, List<({int offset, String mediaId})>>{};
    for (final sheet in textSheets) {
      final anchored = anchoredBySheet[sheet] = <({int offset, String mediaId})>[];
      for (final marker in markersBySheet[sheet]!) {
        final isKeeper = identical(homes[marker.mediaId], sheet) &&
            anchored.every((kept) => kept.mediaId != marker.mediaId);
        if (isKeeper) {
          anchored.add(marker);
        } else {
          (removals[sheet] ??= <int>[]).add(marker.offset);
        }
      }
    }

    final pending = <({int offset, String mediaId})>[];
    for (final sheet in textSheets) {
      sheet.mediaAttachments.clear();
      pending.addAll(anchoredBySheet[sheet]!);
      while (pending.isNotEmpty && !sheet.isAtMediaCapacity) {
        sheet.mediaAttachments.add(mediaById[pending.removeAt(0).mediaId]!);
      }
    }

    final unmounted = <SheetMediaItem>[];
    final tolerated = <String>{};
    for (final marker in pending) {
      if (!unmountLastSheetOverflow || toleratedOverflowIds.contains(marker.mediaId)) {
        textSheets.last.mediaAttachments.add(mediaById[marker.mediaId]!);
        tolerated.add(marker.mediaId);
        continue;
      }
      final home = homes.remove(marker.mediaId)!;
      (removals[home] ??= <int>[]).add(marker.offset);
      unmounted.add(mediaById[marker.mediaId]!);
    }

    for (final MapEntry(key: sheet, value: offsets) in removals.entries) {
      offsets.sort((left, right) => right.compareTo(left));
      for (final offset in offsets) {
        _removeMarkerAt(sheet.controller, offset);
      }
    }

    return MountResolution(
      stagedItems: media
          .where((item) => mediaById.containsKey(item.id) && !homes.containsKey(item.id))
          .toList(),
      unmountedByOverflow: unmounted,
      toleratedOverflowIds: tolerated,
      markerHomes: {
        for (final MapEntry(key: mediaId, value: sheet) in homes.entries)
          mediaId: sheet.controller,
      },
    );
  }

  static void _removeMarkerAt(QuillController controller, int offset) {
    final selection = controller.selection;
    int shifted(int position) => position > offset ? position - 1 : position;
    controller.replaceText(
      offset,
      1,
      '',
      selection.isValid
          ? TextSelection(
              baseOffset: shifted(selection.baseOffset),
              extentOffset: shifted(selection.extentOffset),
            )
          : null,
    );
  }

  /// A copy of [delta] without the markers a save must not keep: those
  /// referencing an attachment outside [knownMediaIds], and repeats of a
  /// marker already seen earlier in the Delta.
  static Delta stripOrphanMarkers(Delta delta, {required Set<String> knownMediaIds}) {
    final seen = <String>{};
    final stripped = Delta();
    for (final operation in delta.operations) {
      final mediaId = MountMarker.mediaIdOf(operation);
      if (mediaId != null && (!knownMediaIds.contains(mediaId) || !seen.add(mediaId))) {
        continue;
      }
      stripped.push(operation);
    }
    return stripped;
  }

}

/// Mount state carried from one resolution to the next while an entry is
/// edited: tolerated overflow, each marker's home sheet, and the items that
/// were mounted, since spill-back and collapse drop sheets (and their item
/// lists) whose markers moved elsewhere.
class MountReflowTracker {
  Set<String> _toleratedOverflowIds = const {};
  Map<String, QuillController> _markerHomes = const {};
  List<SheetMediaItem> _lastMountedItems = const [];

  /// Adopts the mount state of a fresh layout of [sheets].
  void adoptPartition(EditorPartition partition) {
    _toleratedOverflowIds = partition.toleratedOverflowIds;
    _markerHomes = partition.markerHomes;
    _lastMountedItems = _mountedItems(partition.sheets);
  }

  /// Every item a resolution may place: staged first (so items newly returned
  /// to the handscroll follow those already there), then mounted ones.
  List<SheetMediaItem> knownItems(
    List<StationerySheetDescriptor> sheets,
    List<SheetMediaItem> stagedItems,
  ) {
    final byId = <String, SheetMediaItem>{};
    for (final item in [...stagedItems, ..._mountedItems(sheets), ..._lastMountedItems]) {
      byId.putIfAbsent(item.id, () => item);
    }
    return byId.values.toList();
  }

  /// Re-resolves [sheets] after an edit, rewriting [stagedItems] in place, and
  /// returns whether any sheet or the handscroll changed, plus the items
  /// unmounted because they overflowed the last sheet.
  ({bool didChange, List<SheetMediaItem> unmountedByOverflow}) reflow(
    List<StationerySheetDescriptor> sheets,
    List<SheetMediaItem> stagedItems,
  ) {
    final before = _signature(sheets, stagedItems);
    final resolution = SheetMountResolver.resolveMounts(
      sheets: sheets,
      media: knownItems(sheets, stagedItems),
      unmountLastSheetOverflow: true,
      toleratedOverflowIds: _toleratedOverflowIds,
      previousMarkerHomes: _markerHomes,
    );
    stagedItems
      ..clear()
      ..addAll(resolution.stagedItems);
    _toleratedOverflowIds = resolution.toleratedOverflowIds;
    _markerHomes = resolution.markerHomes;
    _lastMountedItems = _mountedItems(sheets);
    return (
      didChange: _signature(sheets, stagedItems) != before,
      unmountedByOverflow: resolution.unmountedByOverflow,
    );
  }

  static List<SheetMediaItem> _mountedItems(List<StationerySheetDescriptor> sheets) => [
        for (final sheet in sheets)
          if (sheet is TextStationerySheet) ...sheet.mediaAttachments,
      ];

  static String _signature(
    List<StationerySheetDescriptor> sheets,
    List<SheetMediaItem> stagedItems,
  ) =>
      [
        for (final sheet in sheets)
          if (sheet is TextStationerySheet) sheet.mediaAttachments.map((item) => item.id).join(','),
        stagedItems.map((item) => item.id).join(','),
      ].join('|');
}
