import 'dart:math' as math;
import 'package:flutter/services.dart';

import '../domain/stationery_sheet_descriptor.dart';
import '../models/mount_marker.dart';
import 'stationery_sheet_spill_mutator.dart';

/// Media-specific mutations over the coordinator's ordered Stationery Sheets and
/// its Staging Handscroll: Collect, Mount (via Delta mount markers), and removal
/// of legacy ephemera sheets. The Staging Handscroll is the only authoring path
/// for media; legacy inline embeds are render-only.
///
/// Operates directly on the coordinator's mutable sheet list and reports every
/// content mutation through [onContentMutated] so the coordinator can bump its
/// content revision and notify listeners.
class SheetMediaOperations {
  final List<StationerySheetDescriptor> _sheets;
  final List<SheetMediaItem> _stagedItems;
  final int Function() _readActiveIndex;
  final void Function(int index) _writeActiveIndex;
  final void Function() _onContentMutated;

  SheetMediaOperations({
    required List<StationerySheetDescriptor> sheets,
    required List<SheetMediaItem> stagedItems,
    required int Function() readActiveIndex,
    required void Function(int index) writeActiveIndex,
    required void Function() onContentMutated,
  })  : _sheets = sheets,
        _stagedItems = stagedItems,
        _readActiveIndex = readActiveIndex,
        _writeActiveIndex = writeActiveIndex,
        _onContentMutated = onContentMutated;

  int _clampedActiveIndex() => _readActiveIndex().clamp(0, _sheets.length - 1);

  void _ensureOpeningSheet() {
    if (_sheets.isEmpty) {
      _sheets.add(OpeningSheet.empty(sheetIndex: 0));
    }
  }

  /// Most items the Staging Handscroll holds at once.
  static const int kHandscrollCapacity = 15;

  /// Attachment ids in collect order, so items returning to the handscroll
  /// (Unmount, undo of an erase) rejoin it where they were collected.
  final List<String> _collectOrder = <String>[];

  /// Adopts [mediaIds] (the persisted collect order) as the collect order.
  void adoptCollectOrder(Iterable<String> mediaIds) {
    _collectOrder
      ..clear()
      ..addAll(mediaIds);
  }

  int _stagedIndexOf(String mediaId) =>
      _stagedItems.indexWhere((item) => item.id == mediaId);

  int _collectRank(String mediaId) {
    final rank = _collectOrder.indexOf(mediaId);
    return rank == -1 ? _collectOrder.length : rank;
  }

  void _stageInCollectOrder(SheetMediaItem item) {
    final rank = _collectRank(item.id);
    final insertAt = _stagedItems.indexWhere((staged) => _collectRank(staged.id) > rank);
    _stagedItems.insert(insertAt == -1 ? _stagedItems.length : insertAt, item);
  }

  /// Re-sorts the Staging Handscroll into collect order, so items that reflow
  /// returned to it (a deleted passage, last-sheet overflow) rejoin it where
  /// they were collected, as an Unmount does.
  void orderStagedByCollect() {
    final ordered = List.of(_stagedItems)
      ..sort((left, right) => _collectRank(left.id).compareTo(_collectRank(right.id)));
    _stagedItems
      ..clear()
      ..addAll(ordered);
  }

  /// Free slots left in the Staging Handscroll.
  int get handscrollRoom => math.max(0, kHandscrollCapacity - _stagedItems.length);

  /// Collects [item] into the Staging Handscroll, after every earlier item.
  ///
  /// Returns false, collecting nothing, when the handscroll is full.
  bool collect(SheetMediaItem item) {
    if (handscrollRoom == 0) return false;
    _collectOrder
      ..remove(item.id)
      ..add(item.id);
    _stagedItems.add(item);
    _onContentMutated();
    return true;
  }

  /// Mounts the staged item [mediaId] onto the active text sheet by inserting a
  /// mount marker at the end of that sheet's text (position 0 when empty).
  ///
  /// Returns false, leaving the item staged, when it is not staged or the
  /// active sheet is not a text sheet with room for another item.
  bool mountOnActiveSheet(String mediaId) {
    _ensureOpeningSheet();
    final sheet = _sheets[_clampedActiveIndex()];
    final stagedIndex = _stagedIndexOf(mediaId);
    if (stagedIndex == -1 || sheet is! TextStationerySheet || sheet.isAtMediaCapacity) {
      return false;
    }
    final item = _stagedItems.removeAt(stagedIndex);
    final selection = sheet.controller.selection;
    final endOfText = math.max(0, sheet.document.length - 1);
    sheet.controller.replaceText(
      endOfText,
      0,
      MountMarker.embeddable(item.id),
      selection.isValid ? selection : const TextSelection.collapsed(offset: 0),
    );
    sheet.mediaAttachments.add(item);
    _onContentMutated();
    return true;
  }

  /// Unmounts [mediaId]: removes its mount marker from the sheet holding it and
  /// returns the item to the Staging Handscroll in collect order.
  ///
  /// Returns false when no sheet has [mediaId] mounted.
  bool unmount(String mediaId) {
    for (final sheet in _sheets) {
      if (sheet is! TextStationerySheet) continue;
      final mountedIndex = sheet.mediaAttachments.indexWhere((item) => item.id == mediaId);
      if (mountedIndex == -1) continue;
      // A cascaded item shows on a later sheet than the one holding its marker.
      for (final markerSheet in _sheets.whereType<TextStationerySheet>()) {
        final markerOffset = _markerOffsetIn(markerSheet, mediaId);
        if (markerOffset == null) continue;
        final selection = markerSheet.controller.selection;
        final base = selection.isValid ? selection.baseOffset : 0;
        markerSheet.controller.replaceText(
          markerOffset,
          1,
          '',
          TextSelection.collapsed(offset: base > markerOffset ? base - 1 : base),
        );
      }
      _stageInCollectOrder(sheet.mediaAttachments.removeAt(mountedIndex));
      _onContentMutated();
      return true;
    }
    return false;
  }

  static int? _markerOffsetIn(TextStationerySheet sheet, String mediaId) {
    var offset = 0;
    for (final operation in sheet.document.toDelta().operations) {
      if (MountMarker.mediaIdOf(operation) == mediaId) return offset;
      offset += operation.length ?? 0;
    }
    return null;
  }

  /// Removes the staged item [mediaId] from the Staging Handscroll; it keeps
  /// its collect position so [restoreStaged] can put it back in place.
  SheetMediaItem? removeStaged(String mediaId) {
    final stagedIndex = _stagedIndexOf(mediaId);
    if (stagedIndex == -1) return null;
    final removed = _stagedItems.removeAt(stagedIndex);
    _onContentMutated();
    return removed;
  }

  /// Puts an erased [item] back into the Staging Handscroll where it was (undo).
  void restoreStaged(SheetMediaItem item) {
    if (_stagedIndexOf(item.id) != -1) return;
    _stageInCollectOrder(item);
    _onContentMutated();
  }

  /// Updates the in-memory caption of [mediaId], wherever it is staged or mounted.
  bool updateCaption(String mediaId, String newCaption) {
    final lists = [
      for (final sheet in _sheets)
        if (sheet is TextStationerySheet) sheet.mediaAttachments,
      _stagedItems,
    ];
    for (final items in lists) {
      final index = items.indexWhere((item) => item.id == mediaId);
      if (index == -1) continue;
      items[index] = items[index].copyWith(caption: newCaption);
      _onContentMutated();
      return true;
    }
    return false;
  }

  /// Removes an ephemera sheet at [sheetIndex], maintaining contiguous indexing.
  void removeEphemeraSheet(int sheetIndex) {
    if (sheetIndex < 0 || sheetIndex >= _sheets.length) return;
    final sheet = _sheets[sheetIndex];
    if (sheet is! EphemeraSheet) return;
    _sheets.removeAt(sheetIndex);
    sheet.dispose();
    StationerySheetSpillMutator.reindexSheets(_sheets);
    _writeActiveIndex(_clampedActiveIndex());
    _onContentMutated();
  }
}
