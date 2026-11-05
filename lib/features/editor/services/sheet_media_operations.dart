import '../../../../core/database/app_database.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/media_embed_data.dart';
import 'stationery_sheet_spill_mutator.dart';

/// Media-specific mutations over the coordinator's ordered Stationery Sheets:
/// sheet-paired keepsake attachments, ephemera sheets, and inline media inserts.
///
/// Operates directly on the coordinator's mutable sheet list and reports every
/// content mutation through [onContentMutated] so the coordinator can bump its
/// content revision and notify listeners.
class SheetMediaOperations {
  final List<StationerySheetDescriptor> _sheets;
  final int Function() _readActiveIndex;
  final void Function(int index) _writeActiveIndex;
  final void Function() _onContentMutated;

  SheetMediaOperations({
    required List<StationerySheetDescriptor> sheets,
    required int Function() readActiveIndex,
    required void Function(int index) writeActiveIndex,
    required void Function() onContentMutated,
  })  : _sheets = sheets,
        _readActiveIndex = readActiveIndex,
        _writeActiveIndex = writeActiveIndex,
        _onContentMutated = onContentMutated;

  int _clampedActiveIndex() => _readActiveIndex().clamp(0, _sheets.length - 1);

  void _ensureOpeningSheet() {
    if (_sheets.isEmpty) {
      _sheets.add(OpeningSheet.empty(sheetIndex: 0));
    }
  }

  /// Collects every keepsake attached to text sheets as [MediaAttachment] records,
  /// so a re-partition can redistribute them without losing captions.
  List<MediaAttachment> collectSheetAttachments() {
    final attachments = <MediaAttachment>[];
    for (final sheet in _sheets) {
      if (sheet is! TextStationerySheet) continue;
      for (final item in sheet.mediaAttachments) {
        attachments.add(MediaAttachment(
          id: item.id,
          entryId: '',
          mediaType: item.mediaType.embedKey,
          relativePath: item.relativePath,
          thumbnailPath: item.thumbnailPath,
          caption: item.caption,
          createdAt: DateTime.now(),
        ));
      }
    }
    return attachments;
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

  /// Attaches a keepsake photo or video directly to the active text sheet.
  bool attachMediaToActiveSheet(SheetMediaItem item) {
    _ensureOpeningSheet();
    final sheet = _sheets[_clampedActiveIndex()];
    if (sheet is! TextStationerySheet || sheet.isAtMediaCapacity) {
      return false;
    }
    sheet.mediaAttachments.add(item);
    _onContentMutated();
    return true;
  }

  /// Removes an attached keepsake from a text sheet at [sheetIndex].
  bool removeMediaAttachment(int sheetIndex, String mediaId) {
    final sheet = _textSheetAt(sheetIndex);
    if (sheet == null) return false;
    sheet.mediaAttachments.removeWhere((item) => item.id == mediaId);
    _onContentMutated();
    return true;
  }

  /// Updates the caption for an attached keepsake on [sheetIndex].
  bool updateMediaCaption(int sheetIndex, String mediaId, String newCaption) {
    final sheet = _textSheetAt(sheetIndex);
    if (sheet == null) return false;
    final index = sheet.mediaAttachments.indexWhere((item) => item.id == mediaId);
    if (index == -1) return false;
    sheet.mediaAttachments[index] = sheet.mediaAttachments[index].copyWith(caption: newCaption);
    _onContentMutated();
    return true;
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

  TextStationerySheet? _textSheetAt(int sheetIndex) {
    if (sheetIndex < 0 || sheetIndex >= _sheets.length) return null;
    final sheet = _sheets[sheetIndex];
    return sheet is TextStationerySheet ? sheet : null;
  }
}
