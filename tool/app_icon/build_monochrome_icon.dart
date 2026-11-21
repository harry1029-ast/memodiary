// Renders the Android adaptive icon's drawn layers (SPEC-023 Implementation
// Decision 6) to PNG. Runs under `flutter test` so dart:ui can rasterise them:
//
//   flutter test tool/app_icon/build_monochrome_icon.dart
//
// Output: tool/app_icon/app_icon_monochrome.png, the Android 13 themed-icon
//         silhouette: a 1024×1024 full adaptive layer (108dp) with white
//         shapes on transparency, kept inside the 66dp safe zone.
//         tool/app_icon/app_icon_foreground.png, the fully transparent
//         foreground layer (the painting is the background; no parallax).
// Both are full 108dp layers, so the generator runs with a 0% inset.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'icon_raster_io.dart';
import 'monochrome_silhouette.dart';

const monochromePath = 'tool/app_icon/app_icon_monochrome.png';
const foregroundPath = 'tool/app_icon/app_icon_foreground.png';
const layerSize = 1024;

/// The 66dp safe zone of a 108dp adaptive layer drawn at [layerSize] pixels.
Rect adaptiveSafeZone(double layerSize) => Rect.fromCenter(
    center: Offset(layerSize / 2, layerSize / 2), width: layerSize * 66 / 108, height: layerSize * 66 / 108);

void main() {
  testWidgets('build adaptive icon layers', (tester) async {
    await tester.runAsync(() async {
      final monochrome = await renderImage(layerSize, layerSize, (canvas) {
        paintMonochromeSilhouette(canvas, adaptiveSafeZone(layerSize.toDouble()), const Color(0xFFFFFFFF));
      });
      await writePng(monochrome, monochromePath);
      await writePng(await renderImage(layerSize, layerSize, (canvas) {}), foregroundPath);
    });
  });
}
