import 'dart:math' as math;
import 'package:flutter/services.dart';

import '../domain/stationery_sheet_descriptor.dart';
import '../models/media_embed_data.dart';
import '../models/mount_marker.dart';
import 'stationery_sheet_spill_mutator.dart';

/// Media-specific mutations over the coordinator's ordered Stationery Sheets and
/// its Staging Handscroll: Collect, Mount (via Delta mount markers), ephemera
/// sheets, and inline media inserts.
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

  int _stagedIndexOf(String mediaId) =>
      _stagedItems.indexWhere((item) => item.id == mediaId);

  /// Every known item: mounted items in sheet order, then staged items, so a
  /// re-partition can resolve markers again without losing captions.
  List<SheetMediaItem> allItems() => [
        for (final sheet in _sheets)
          if (sheet is TextStationerySheet) ...sheet.mediaAttachments,
        ..._stagedItems,
      ];

  /// Collects [item] into the Staging Handscroll, after every earlier item.
  void collect(SheetMediaItem item) {
    _stagedItems.add(item);
    _onContentMutated();
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

  /// Removes the staged item [mediaId] from the Staging Handscroll.
  SheetMediaItem? removeStaged(String mediaId) {
    final stagedIndex = _stagedIndexOf(mediaId);
    if (stagedIndex == -1) return null;
    final removed = _stagedItems.removeAt(stagedIndex);
    _onContentMutated();
    return removed;
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

  /// Inserts a new ephemera sheet at [atIndex] or after the active sheet.
  void insertEphemeraSheet({
    required EphemeraMediaType mediaType,
    required MediaEmbedData mediaData,
    int? atIndex,
  }) {
    final targetIndex = (atIndex ?? (_readActiveIndex() + 1)).clamp(0, _sheets.length);
    _sheets.insert(
      targetIndex,
      EphemeraSheet(
        sheetIndex: targetIndex,
        mediaType: mediaType,
        mediaData: mediaData,
      ),
    );
    StationerySheetSpillMutator.reindexSheets(_sheets);
    _writeActiveIndex(targetIndex);
    _onContentMutated();
  }

  /// Inserts media at the active selection, splitting mid-sheet prose cleanly.
  void insertMediaAtCurrentSelection({
    required EphemeraMediaType mediaType,
    required MediaEmbedData mediaData,
  }) {
    _ensureOpeningSheet();
    _writeActiveIndex(StationerySheetSpillMutator.insertMediaAtSelection(
      sheets: _sheets,
      activeIndex: _clampedActiveIndex(),
      mediaType: mediaType,
      mediaData: mediaData,
    ));
    _onContentMutated();
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
