// Builds the reframed launcher icon master from the diarist's painting
// (SPEC-023 Implementation Decision 6). Runs under `flutter test` so dart:ui
// can decode the WebP source and encode the PNG master:
//
//   flutter test tool/app_icon/build_icon_master.dart
//
// Input:  tool/app_icon/app_icon_source.webp (1024×1024, diarist-supplied)
// Output: tool/app_icon/app_icon_master.png  (1024×1024, opaque)
import 'package:flutter_test/flutter_test.dart';

import 'icon_raster_io.dart';
import 'icon_reframe.dart';

const sourcePath = 'tool/app_icon/app_icon_source.webp';
const masterPath = 'tool/app_icon/app_icon_master.png';
const masterSize = 1024;

void main() {
  testWidgets('build app icon master', (tester) async {
    await tester.runAsync(() async {
      final source = await decodeImageFile(sourcePath);
      expect(source.width, source.height, reason: 'the source painting must be square');
      final master = reframeIconMaster(await imageRgba(source), source.width, canvasSize: masterSize);
      await writePng(await imageFromRgba(master, masterSize, masterSize), masterPath);
    });
  });
}
