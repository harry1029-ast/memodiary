import 'package:flutter_quill/quill_delta.dart';
import '../domain/stationery_sheet_descriptor.dart';
import 'stationery_delta_splitter.dart';

/// Pure-Dart synthesizer that merges discrete [StationerySheetDescriptor] slices
/// back into a single continuous Quill Delta document.
class StationeryDeltaSynthesizer {
  const StationeryDeltaSynthesizer._();

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
}
