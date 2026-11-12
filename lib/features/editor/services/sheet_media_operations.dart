part of 'editor_pagination_coordinator.dart';

/// Internal media-specific mutations over the coordinator's ordered Stationery
/// Sheets and its Staging Handscroll: Collect, Mount (via Delta mount markers),
/// Unmount, staged erasure/restoration, caption updates, and legacy ephemera
/// sheet removal.
class _SheetMediaOperations {
  final EditorPaginationCoordinator _coordinator;

  _SheetMediaOperations(this._coordinator);

  List<StationerySheetDescriptor> get _sheets => _coordinator._sheets;
  List<SheetMediaItem> get _stagedItems => _coordinator._stagedItems;

  int _clampedActiveIndex() =>
      _coordinator._activeSheetIndex.clamp(0, _sheets.length - 1);

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

  /// Populates staged items and mount tracker state from a fresh [partition].
  void adoptPartitionMounts(EditorPartition partition) {
    _stagedItems
      ..clear()
      ..addAll(partition.stagedItems);
    _coordinator._mounts.adoptPartition(partition);
  }

  int _stagedIndexOf(String mediaId) =>
      _stagedItems.indexWhere((item) => item.id == mediaId);

  int _collectRank(String mediaId) {
    final rank = _collectOrder.indexOf(mediaId);
    return rank == -1 ? _collectOrder.length : rank;
  }

  void _stageInCollectOrder(SheetMediaItem item) {
    final rank = _collectRank(item.id);
    final insertAt =
        _stagedItems.indexWhere((staged) => _collectRank(staged.id) > rank);
    _stagedItems.insert(insertAt == -1 ? _stagedItems.length : insertAt, item);
  }

  /// Re-sorts the Staging Handscroll into collect order, so items that reflow
  /// returned to it (a deleted passage, last-sheet overflow) rejoin it where
  /// they were collected, as an Unmount does.
  void orderStagedByCollect() {
    final ordered = List.of(_stagedItems)
      ..sort((left, right) =>
          _collectRank(left.id).compareTo(_collectRank(right.id)));
    _stagedItems
      ..clear()
      ..addAll(ordered);
  }

  /// Re-resolves which sheet shows each mounted item after the text changed:
  /// items follow the sheet their marker's passage now lies on, cascade past
  /// full sheets, and those pushed past the last sheet are unmounted (reported
  /// through [EditorPaginationCoordinator.onOverflowUnmount]).
  void reflowMounts() {
    if (_coordinator._isDisposed) return;
    if (_sheets.any((sheet) => _coordinator.isSheetComposing(sheet.sheetIndex))) {
      return;
    }

    final outcome = _coordinator._mounts.reflow(_sheets, _stagedItems);
    orderStagedByCollect();
    if (outcome.didChange) {
      _coordinator._notifyContentMutated();
    }
    if (outcome.unmountedByOverflow.isNotEmpty) {
      _coordinator.onOverflowUnmount?.call(outcome.unmountedByOverflow);
    }
  }

  /// Free slots left in the Staging Handscroll.
  int get handscrollRoom =>
      math.max(0, kHandscrollCapacity - _stagedItems.length);

  /// Collects [item] into the Staging Handscroll, after every earlier item.
  ///
  /// Returns false, collecting nothing, when the handscroll is full.
  bool collect(SheetMediaItem item) {
    if (handscrollRoom == 0) return false;
    _collectOrder
      ..remove(item.id)
      ..add(item.id);
    _stagedItems.add(item);
    _coordinator._notifyContentMutated();
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
    if (stagedIndex == -1 ||
        sheet is! TextStationerySheet ||
        sheet.isAtMediaCapacity) {
      return false;
    }
    final item = _stagedItems.removeAt(stagedIndex);
    final selection = sheet.controller.selection;
    final endOfText = MountMarker.endOfTextOffset(sheet.delta);
    sheet.controller.replaceText(
      endOfText,
      0,
      MountMarker.embeddable(item.id),
      selection.isValid ? selection : const TextSelection.collapsed(offset: 0),
      // A desk action, not typing: Quill must not summon the keyboard for it.
      ignoreFocus: true,
    );
    sheet.mediaAttachments.add(item);
    _coordinator._notifyContentMutated();
    return true;
  }

  /// Unmounts [mediaId]: removes its mount marker from the sheet holding it and
  /// returns the item to the Staging Handscroll in collect order.
  ///
  /// Returns false when no sheet has [mediaId] mounted.
  bool unmount(String mediaId) {
    for (final sheet in _sheets) {
      if (sheet is! TextStationerySheet) continue;
      final mountedIndex =
          sheet.mediaAttachments.indexWhere((item) => item.id == mediaId);
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
          TextSelection.collapsed(
              offset: base > markerOffset ? base - 1 : base),
          ignoreFocus: true,
        );
      }
      _stageInCollectOrder(sheet.mediaAttachments.removeAt(mountedIndex));
      _coordinator._notifyContentMutated();
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
    _coordinator._notifyContentMutated();
    return removed;
  }

  /// Puts an erased [item] back into the Staging Handscroll where it was (undo).
  void restoreStaged(SheetMediaItem item) {
    if (_stagedIndexOf(item.id) != -1) return;
    _stageInCollectOrder(item);
    _coordinator._notifyContentMutated();
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
      _coordinator._notifyContentMutated();
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
    _coordinator._activeSheetIndex = _clampedActiveIndex();
    _coordinator._notifyContentMutated();
  }

  /// Mounts legacy attachments first-come by writing their markers into the
  /// unified Delta at the measured layout width.
  bool mountLegacyAttachments() {
    if (_stagedItems.isEmpty) return false;
    final allMedia = _coordinator._knownItems();
    final mountedDelta = EditorDeltaPartitioner.mountLegacyAttachments(
      unifiedDelta: _coordinator.synthesizeUnifiedDelta(),
      media: allMedia,
      typography: _coordinator.typography,
      contentWidth: _coordinator.contentWidth,
      templateStyle: _coordinator.templateStyle,
      lineStridePx: _coordinator.lineStridePx,
      rowCapacity: _coordinator.rowCapacity,
    );
    _coordinator._initialize(jsonEncode(mountedDelta.toJson()), media: allMedia);
    return true;
  }
}
