// Compiles Make Me a Hanzi `graphics.txt` plus the curated Latin table into
// `assets/calligraphy/hanzi_strokes.bin` (SPEC-020 §2, ADR-0011).
//
// Dataset: https://github.com/skishore/makemeahanzi
// Pinned commit: bddc96d41bef78427ed0e034e9f7e31d71fd1b92
// Licence: graphics.txt is derived from Arphic PL KaitiM GB / Arphic PL UKai
// under the Arphic Public License (see COPYING at the pinned commit); the
// output remains under that licence. Never commit graphics.txt.
//
// Usage:
//   dart run tool/build_hanzi_strokes.dart \
//     --graphics <path/to/graphics.txt> --out assets/calligraphy/hanzi_strokes.bin
import 'dart:io';

import 'package:memodiary/features/editor/ink_choreography/curated_strokes.dart';
import 'package:memodiary/features/editor/ink_choreography/hanzi_stroke_builder.dart';

Future<void> main(List<String> args) async {
  String? graphicsPath;
  String? outPath;
  for (var at = 0; at < args.length - 1; at++) {
    if (args[at] == '--graphics') graphicsPath = args[at + 1];
    if (args[at] == '--out') outPath = args[at + 1];
  }
  if (graphicsPath == null || outPath == null) {
    stderr.writeln(
      'Usage: dart run tool/build_hanzi_strokes.dart '
      '--graphics <graphics.txt> --out <hanzi_strokes.bin>',
    );
    exit(64);
  }

  final lines = await File(graphicsPath).readAsLines();
  final bytes = buildHanziStrokeTable(
    graphicsLines: lines,
    curated: curatedStrokes,
  );
  final outFile = File(outPath);
  await outFile.parent.create(recursive: true);
  await outFile.writeAsBytes(bytes);

  final entryCount = bytes.isEmpty
      ? 0
      : (bytes[6] | (bytes[7] << 8)); // uint16 little-endian header count
  stdout.writeln('Wrote $outPath: $entryCount entries, ${bytes.length} bytes');
}
