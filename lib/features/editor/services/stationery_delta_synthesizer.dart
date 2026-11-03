import 'package:flutter_quill/quill_delta.dart';
import '../domain/stationery_sheet_descriptor.dart';

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
        final sheetDelta = sheet.delta;
        if (sheet.hasTrailingSoftNewline && sheetDelta.isNotEmpty) {
          for (int opIndex = 0; opIndex < sheetDelta.operations.length; opIndex++) {
            final operation = sheetDelta.operations[opIndex];
            final isLast = opIndex == sheetDelta.operations.length - 1;

            if (isLast && operation.isInsert && operation.data is String) {
              final text = operation.data as String;
              if (text.endsWith('\n')) {
                final stripped = text.substring(0, text.length - 1);
                if (stripped.isNotEmpty) {
                  unified.push(Operation.insert(stripped, operation.attributes));
                }
              } else {
                unified.push(operation);
              }
            } else {
              unified.push(operation);
            }
          }
        } else {
          for (final operation in sheetDelta.operations) {
            unified.push(operation);
          }
        }
      } else if (sheet is EphemeraSheet) {
        final embedValue = sheet.currentMediaData.toEmbedValue();
        unified.push(Operation.insert({sheet.mediaType: embedValue}));
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

