import 'package:flutter_quill/quill_delta.dart';
import '../../templates/models/template_style.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/mount_marker.dart';
import '../models/typography_settings.dart';
import 'editor_pagination_models.dart';
import 'sheet_mount_resolver.dart';
import 'stationery_delta_splitter.dart';
import 'stationery_delta_synthesizer.dart';
import 'stationery_line_measurer.dart';

export 'editor_pagination_models.dart' show EditorPartition, MountResolution;

/// Pure algorithmic partitioner segmenting a continuous Quill Delta
/// into discrete [StationerySheetDescriptor] instances.
class EditorDeltaPartitioner {
  const EditorDeltaPartitioner._();

  /// Partitions [unifiedDelta] into a sequence of stationery sheets, each
  /// holding the rows [rowCapacity] gives it, mounting each item of [media] on
  /// the sheet holding its mount marker and reporting the unreferenced items
  /// (in [media] order) as staged.
  static EditorPartition partition({
    required Delta unifiedDelta,
    List<SheetMediaItem> media = const [],
    required TypographySettings typography,
    double? contentWidth,
    required TemplateStyle templateStyle,
    double? lineStridePx,
    SheetRowCapacity rowCapacity = SheetRowCapacity.folioLeaf,
  }) {
    final sheets = <StationerySheetDescriptor>[];
    final blocks = extractContentBlocks(unifiedDelta);

    if (blocks.isEmpty) {
      return EditorPartition(
        sheets: [OpeningSheet.empty(sheetIndex: 0)],
        stagedItems: List.of(media),
      );
    }

    var pendingTextDelta = Delta();

    void flushPendingTextSheets() {
      if (pendingTextDelta.isEmpty) {
        if (sheets.isEmpty) {
          sheets.add(OpeningSheet.empty(sheetIndex: 0));
        }
        return;
      }

      var remainingDelta = pendingTextDelta;
      pendingTextDelta = Delta();

      while (remainingDelta.isNotEmpty) {
        final budget = sheets.isEmpty
            ? rowCapacity.openingRows
            : rowCapacity.continuationRows;
        final overflow = StationeryDeltaSplitter.extractOverflow(
          sheetDelta: remainingDelta,
          rowCapacity: budget,
          typography: typography,
          contentWidth: contentWidth,
          backgroundType: templateStyle.type,
          lineStridePx: lineStridePx,
        );

        if (sheets.isEmpty) {
          sheets.add(OpeningSheet.fromDelta(
            sheetIndex: 0,
            delta: overflow.remainingDelta,
            hasTrailingSoftNewline: overflow.hasTrailingSoftNewline,
          ));
        } else {
          sheets.add(ContinuationSheet.fromDelta(
            sheetIndex: sheets.length,
            delta: overflow.remainingDelta,
            hasTrailingSoftNewline: overflow.hasTrailingSoftNewline,
          ));
        }

        if (overflow.overflowingDelta.isEmpty) {
          break;
        }
        remainingDelta = overflow.overflowingDelta;
      }
    }

    for (final block in blocks) {
      if (block is EditorEphemeraBlock) {
        flushPendingTextSheets();
        sheets.add(EphemeraSheet.fromEmbed(
          sheetIndex: sheets.length,
          mediaType: block.mediaType,
          rawData: block.rawData,
        ));
      } else if (block is EditorTextBlock) {
        for (final operation in block.operations) {
          pendingTextDelta.push(operation);
        }
      }
    }

    if (pendingTextDelta.isNotEmpty || sheets.isEmpty) {
      flushPendingTextSheets();
    }

    // Opening never unmounts: overflow past the last sheet is tolerated there.
    final mounts = SheetMountResolver.resolveMounts(sheets: sheets, media: media);

    for (int index = 0; index < sheets.length; index++) {
      sheets[index] = sheets[index].copyWithIndex(index);
    }

    return EditorPartition(
      sheets: sheets,
      stagedItems: mounts.stagedItems,
      toleratedOverflowIds: mounts.toleratedOverflowIds,
      markerHomes: mounts.markerHomes,
    );
  }

  /// Legacy mounting pass for entries written before mount markers existed
  /// (ADR-0009): returns [unifiedDelta] with a marker written for every
  /// unanchored item of [media], placed with the pre-marker first-come rule
  /// (the first text sheet with fewer than three items, else the last text
  /// sheet) at the end of that sheet's text, in [media] order.
  ///
  /// Returns [unifiedDelta] unchanged when nothing is unanchored, so applying
  /// it twice is a no-op.
  static Delta mountLegacyAttachments({
    required Delta unifiedDelta,
    required List<SheetMediaItem> media,
    required TypographySettings typography,
    double? contentWidth,
    required TemplateStyle templateStyle,
    double? lineStridePx,
    SheetRowCapacity rowCapacity = SheetRowCapacity.folioLeaf,
  }) {
    final partitioned = partition(
      unifiedDelta: unifiedDelta,
      media: media,
      typography: typography,
      contentWidth: contentWidth,
      templateStyle: templateStyle,
      lineStridePx: lineStridePx,
      rowCapacity: rowCapacity,
    );
    try {
      final textSheets = partitioned.sheets.whereType<TextStationerySheet>().toList();
      if (partitioned.stagedItems.isEmpty || textSheets.isEmpty) return unifiedDelta;

      final assignedIds = <TextStationerySheet, List<String>>{};
      for (final item in partitioned.stagedItems) {
        final target = textSheets.firstWhere(
          (sheet) => !sheet.isAtMediaCapacity,
          orElse: () => textSheets.last,
        );
        target.mediaAttachments.add(item);
        (assignedIds[target] ??= <String>[]).add(item.id);
      }

      for (final MapEntry(key: sheet, value: mediaIds) in assignedIds.entries) {
        final endOfText = MountMarker.endOfTextOffset(sheet.delta);
        final markers = Delta()..retain(endOfText);
        for (final mediaId in mediaIds) {
          markers.insert(MountMarker.embeddable(mediaId).toJson());
        }
        sheet.setDelta(sheet.delta.compose(markers));
      }
      return StationeryDeltaSynthesizer.synthesize(partitioned.sheets);
    } finally {
      for (final sheet in partitioned.sheets) {
        sheet.dispose();
      }
    }
  }

  /// Extracts structured text and ephemera blocks from continuous Delta.
  static List<EditorContentBlock> extractContentBlocks(Delta delta) {
    return StationeryLineMeasurer.extractContentBlocks(delta);
  }
}
