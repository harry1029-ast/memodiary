import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/mount_marker.dart';
import 'sheet_mount_resolver.dart';
import 'stationery_delta_splitter.dart';

/// Pure-Dart synthesizer that merges discrete [StationerySheetDescriptor] slices
/// back into a single continuous Quill Delta document.
class StationeryDeltaSynthesizer {
  const StationeryDeltaSynthesizer._();

  /// Decodes a raw continuous Quill Delta JSON string (or fallback plain text) into a [Delta].
  static Delta decode(String contentDeltaJson, {String? fallbackPlainText}) {
    if (contentDeltaJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(contentDeltaJson);
        final ops = decoded is List ? decoded : (decoded is Map ? decoded['ops'] : null);
        return ops is List ? Delta.fromJson(ops) : (Delta()..insert('\n'));
      } catch (_) {
        return Delta()..insert('\n');
      }
    }
    if (fallbackPlainText != null && fallbackPlainText.trim().isNotEmpty) {
      final delta = Delta()..insert(fallbackPlainText);
      if (!fallbackPlainText.endsWith('\n')) delta.insert('\n');
      return delta;
    }
    return Delta()..insert('\n');
  }

  /// Synthesizes all active sheets back into a single continuous Quill Delta.
  static Delta synthesize(List<StationerySheetDescriptor> sheets) {
    final unified = Delta();

    for (int sheetIndex = 0; sheetIndex < sheets.length; sheetIndex++) {
      final sheet = sheets[sheetIndex];
      if (sheet is TextStationerySheet) {
        StationeryDeltaSplitter.appendDeltaStrippingSoftNewline(
          target: unified,
          source: sheet.delta,
          stripTrailingSoftNewline: sheet.hasTrailingSoftNewline,
        );
      } else if (sheet is EphemeraSheet) {
        final embedValue = sheet.currentMediaData.toEmbedValue();
        unified.push(Operation.insert({sheet.mediaType.embedKey: embedValue}));
        unified.push(Operation.insert('\n'));
      }
    }

    if (unified.isEmpty) {
      unified.push(Operation.insert('\n'));
    } else {
      final lastOp = unified.operations.last;
      if (lastOp.data is! String || !(lastOp.data as String).endsWith('\n')) {
        unified.push(Operation.insert('\n'));
      }
    }

    return unified;
  }

  /// Re-synthesizes the unified Delta JSON string and plain text representation,
  /// stripping mount markers that reference no known attachment (or repeat one).
  static (String deltaJson, String plainText) reSynthesize(
    List<StationerySheetDescriptor> sheets, {
    required Set<String> knownMediaIds,
  }) {
    final unified = SheetMountResolver.stripOrphanMarkers(
      synthesize(sheets),
      knownMediaIds: knownMediaIds,
    );
    final hasMountMarkers = MountMarker.mediaIdsIn(unified).isNotEmpty;
    final textDocument = Document.fromDelta(MountMarker.strip(unified));
    final plainText = textDocument.toPlainText().trim();
    // Structural emptiness: whitespace and blank lines are kept as content.
    if (textDocument.length <= 1 &&
        !hasMountMarkers &&
        sheets.every((sheet) => sheet is! EphemeraSheet)) {
      return ('[]', '');
    }
    return (jsonEncode(unified.toJson()), plainText);
  }
}
