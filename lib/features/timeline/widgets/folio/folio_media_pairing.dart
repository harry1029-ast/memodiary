import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import '../../../../core/database/app_database.dart';
import '../../../editor/domain/stationery_sheet_descriptor.dart';
import '../../../editor/models/typography_settings.dart';
import '../../../editor/services/editor_delta_partitioner.dart';
import '../../../editor/services/stationery_delta_synthesizer.dart';
import '../../../templates/models/template_style.dart';
import 'folio_leaf_model.dart';

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

  /// Attachments mounted on the first text sheet (the Frontispiece showcase).
  List<MediaAttachment> get firstSheetMounts {
    final mounts = textSheetMounts;
    return mounts.isEmpty ? const [] : mounts.first;
  }

  /// Mounted attachments for the [ordinal]-th of [leafCount] body leaves:
  /// Sheet N rides on Leaf N, and sheets beyond the last leaf fold onto it.
  List<MediaAttachment> mountsForLeaf(int ordinal, int leafCount) {
    final mounts = textSheetMounts;
    if (leafCount <= 0 || ordinal >= mounts.length) return const [];
    if (ordinal < leafCount - 1) return mounts[ordinal];
    return mounts.skip(ordinal).expand((sheetMounts) => sheetMounts).toList();
  }
}

/// Pure pairing rules deciding which attachments appear on which Folio leaf or
/// PDF section: an attachment is shown on the sheet whose text holds its mount
/// marker; staged (unmarked) attachments are shown nowhere.
class FolioMediaPairing {
  const FolioMediaPairing._();

  static const TemplateStyle _defaultTemplateStyle = TemplateStyle(
    type: TemplateBackgroundType.lined,
    backgroundColor: Color(0xFFFBF8F1),
    lineSpacing: 1.5,
    marginHorizontal: 24.0,
  );

  /// Partitions [entry] into sheets the way the editor does and resolves each
  /// mount marker to its sheet. Entries still awaiting the legacy mounting pass
  /// (`legacyMountsPending`) are mounted first-come headlessly, without persisting.
  static FolioMountPlan resolveMounts({
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

  /// Converts the attachments mounted on a leaf into Folio photo cards targeting
  /// [targetLeafIndex], preserving persisted overlay drag positions.
  static List<FolioPhotoAttachment> photosForLeaf({
    required List<MediaAttachment> mounted,
    required int targetLeafIndex,
    required String entryDateStr,
  }) {
    return [
      for (int index = 0; index < mounted.length; index++)
        _toPhoto(mounted[index], index, targetLeafIndex, entryDateStr),
    ];
  }

  static FolioPhotoAttachment _toPhoto(
    MediaAttachment attachment,
    int indexOnLeaf,
    int targetLeafIndex,
    String entryDateStr,
  ) {
    final caption = attachment.caption?.trim() ?? '';
    return FolioPhotoAttachment(
      id: attachment.id,
      relativePath: attachment.relativePath,
      mediaType: EphemeraMediaType.fromEmbedKey(attachment.mediaType),
      title: caption.isNotEmpty ? caption.split('\n').first : '随文影札 ${indexOnLeaf + 1}',
      caption: caption.isNotEmpty ? caption : '随文影札 · 拾光留影',
      date: entryDateStr,
      pageNumber: targetLeafIndex,
      targetLeafIndex: targetLeafIndex,
      overlayXRatio: attachment.overlayXRatio,
      overlayYRatio: attachment.overlayYRatio,
    );
  }

  static Delta _decodeDelta(String contentDeltaJson, String fallbackPlainText) {
    if (contentDeltaJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(contentDeltaJson);
        final ops = decoded is List ? decoded : (decoded is Map ? decoded['ops'] : null);
        if (ops is List && ops.isNotEmpty) return Delta.fromJson(ops);
      } catch (_) {
        // Malformed Delta: fall back to plain text below.
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
