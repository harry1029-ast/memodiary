// Renders the Android 13 themed-icon silhouette (SPEC-023 Implementation
// Decision 6) to PNG. Runs under `flutter test` so dart:ui can rasterise it:
//
//   flutter test tool/app_icon/build_monochrome_icon.dart
//
// Output: tool/app_icon/app_icon_monochrome.png, a 1024×1024 full adaptive
// layer (108dp) with white shapes on transparency, kept inside the 66dp safe
// zone.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'icon_raster_io.dart';
import 'monochrome_silhouette.dart';

const monochromePath = 'tool/app_icon/app_icon_monochrome.png';
const layerSize = 1024;

/// The 66dp safe zone of a 108dp adaptive layer drawn at [layerSize] pixels.
Rect adaptiveSafeZone(double layerSize) => Rect.fromCenter(
    center: Offset(layerSize / 2, layerSize / 2), width: layerSize * 66 / 108, height: layerSize * 66 / 108);

void main() {
  testWidgets('build monochrome app icon layer', (tester) async {
    await tester.runAsync(() async {
      final layer = await renderImage(layerSize, layerSize, (canvas) {
        paintMonochromeSilhouette(canvas, adaptiveSafeZone(layerSize.toDouble()), const Color(0xFFFFFFFF));
      });
      await writePng(layer, monochromePath);
    });
  });
}
