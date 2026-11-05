import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/delta_ops_decoder.dart';
import '../../editor/domain/stationery_sheet_descriptor.dart';
import '../../editor/models/typography_settings.dart';
import '../../editor/services/editor_delta_partitioner.dart';
import '../../editor/services/stationery_delta_synthesizer.dart';
import '../../templates/models/template_style.dart';

/// One Stationery Sheet of an entry as the editor partitions it: its slice of
/// the Delta and the attachments mounted on it (in marker order).
class FolioSheetSection {
  /// Whether this is a text sheet (as opposed to a legacy inline-embed ephemera sheet).
  final bool isText;

  /// The sheet's slice of the entry's Quill Delta, as JSON operations.
  final List<dynamic> deltaOps;

  /// Attachments mounted on this sheet, in marker order. Always empty for ephemera sheets.
  final List<MediaAttachment> mounted;

  const FolioSheetSection({
    required this.isText,
    required this.deltaOps,
    this.mounted = const [],
  });
}

/// The editor's sheet assignment of an entry's mounted media (ADR-0009), shared
/// by the Thread-Bound Folio and PDF export so both pair media identically.
class FolioMountPlan {
  /// Every sheet in editor order.
  final List<FolioSheetSection> sections;

  const FolioMountPlan(this.sections);

  /// Mounted attachments of each text sheet, in sheet order.
  List<List<MediaAttachment>> get textSheetMounts => sections
      .where((section) => section.isText)
      .map((section) => section.mounted)
      .toList();

  /// Whether any text sheet has a mounted item.
  bool get hasMounts => textSheetMounts.any((mounts) => mounts.isNotEmpty);

  /// Attachments mounted on the first text sheet (the Frontispiece showcase).
  List<MediaAttachment> get firstSheetMounts {
    final mounts = textSheetMounts;
    return mounts.isEmpty ? const [] : mounts.first;
  }

  /// Mounted attachments of each of [leafCount] body leaves (Folio leaves or
  /// PDF pages), in leaf order. No leaf holds more than
  /// [TextStationerySheet.kMountCapacity] items.
  ///
  /// Sheet N rides on Leaf N, and sheets beyond the last leaf fold onto it.
  /// Items past a leaf's capacity (in leaf order) move to the nearest earlier
  /// leaf with room, else the nearest later one; items with no room on any
  /// leaf are left out.
  List<List<MediaAttachment>> mountsByLeaf(int leafCount) {
    if (leafCount <= 0) return const [];
    const capacity = TextStationerySheet.kMountCapacity;
    final leaves = List.generate(leafCount, (_) => <MediaAttachment>[]);
    final mounts = textSheetMounts;
    for (int sheetIndex = 0; sheetIndex < mounts.length; sheetIndex++) {
      leaves[math.min(sheetIndex, leafCount - 1)].addAll(mounts[sheetIndex]);
    }

    final overflow = <(int, MediaAttachment)>[];
    for (int leafIndex = 0; leafIndex < leafCount; leafIndex++) {
      final leaf = leaves[leafIndex];
      if (leaf.length <= capacity) continue;
      overflow.addAll(leaf.skip(capacity).map((item) => (leafIndex, item)));
      leaf.removeRange(capacity, leaf.length);
    }

    for (final (origin, item) in overflow) {
      final candidates = [
        for (int leafIndex = origin - 1; leafIndex >= 0; leafIndex--) leafIndex,
        for (int leafIndex = origin + 1; leafIndex < leafCount; leafIndex++) leafIndex,
      ];
      for (final leafIndex in candidates) {
        if (leaves[leafIndex].length < capacity) {
          leaves[leafIndex].add(item);
          break;
        }
      }
    }
    return leaves;
  }
}

/// Pure pairing rules deciding which attachments appear on which Folio leaf or
/// PDF section: an attachment is shown on the sheet whose text holds its mount
/// marker; staged (unmarked) attachments are shown nowhere.
///
/// The partition is computed without the editor's measured sheet width, so it
/// is approximate for long wrapped paragraphs.
class FolioMediaPairing {
  const FolioMediaPairing._();

  static const TemplateStyle _defaultTemplateStyle = TemplateStyle(
    type: TemplateBackgroundType.lined,
    backgroundColor: Color(0xFFFBF8F1),
    lineSpacing: 1.5,
    marginHorizontal: 24.0,
  );

  /// Partitions [entry] into sheets the way the editor does and pairs each
  /// mount marker with its sheet. Entries still awaiting the legacy mounting pass
  /// (`legacyMountsPending`) are mounted first-come headlessly, without persisting.
  static FolioMountPlan pairLeaves({
    required Entry entry,
    required List<MediaAttachment> attachments,
    TemplateStyle? templateStyle,
  }) {
    final style = templateStyle ?? _defaultTemplateStyle;
    final typography = TypographySettings(
      fontFamily: (style.fontFamily == null || style.fontFamily == 'System') ? null : style.fontFamily,
      lineSpacing: style.lineSpacing,
    );
    final media = attachments.map(SheetMediaItem.fromMediaAttachment).toList();
    final attachmentsById = {for (final attachment in attachments) attachment.id: attachment};

    var unifiedDelta = _decodeDelta(entry.contentDelta, entry.plainText);
    if (entry.legacyMountsPending) {
      unifiedDelta = EditorDeltaPartitioner.mountLegacyAttachments(
        unifiedDelta: unifiedDelta,
        media: media,
        typography: typography,
        templateStyle: style,
      );
    }

    final partition = EditorDeltaPartitioner.partition(
      unifiedDelta: unifiedDelta,
      media: media,
      typography: typography,
      templateStyle: style,
    );
    try {
      return FolioMountPlan([
        for (final sheet in partition.sheets)
          FolioSheetSection(
            isText: sheet is TextStationerySheet,
            deltaOps: StationeryDeltaSynthesizer.synthesize([sheet]).toJson(),
            mounted: sheet is TextStationerySheet
                ? [
                    for (final item in sheet.mediaAttachments)
                      if (attachmentsById[item.id] != null) attachmentsById[item.id]!,
                  ]
                : const [],
          ),
      ]);
    } finally {
      for (final sheet in partition.sheets) {
        sheet.dispose();
      }
    }
  }

  static Delta _decodeDelta(String contentDeltaJson, String fallbackPlainText) {
    final ops = decodeDeltaOps(contentDeltaJson);
    if (ops != null) {
      try {
        return Delta.fromJson(ops);
      } catch (_) {
        // Ops that are not a valid Delta: fall back to plain text below.
      }
    }
    final delta = Delta();
    if (fallbackPlainText.trim().isNotEmpty) {
      delta.insert(fallbackPlainText.endsWith('\n') ? fallbackPlainText : '$fallbackPlainText\n');
    } else {
      delta.insert('\n');
    }
    return delta;
  }
}
