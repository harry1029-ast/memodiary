// Renders Android's legacy round launcher icons (SPEC-023 Implementation
// Decision 6), which flutter_launcher_icons does not produce. Run after the
// generator, because the round adaptive XML mirrors its `ic_launcher.xml`:
//
//   flutter test tool/app_icon/build_round_icons.dart
//
// Input:  tool/app_icon/app_icon_master_legacy.png
//         android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
// Output: android/app/src/main/res/mipmap-<density>/ic_launcher_round.png
//         android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'build_icon_master.dart' show legacyMasterPath;
import 'icon_raster_io.dart';

const _resDir = 'android/app/src/main/res';

/// Legacy launcher icon size (48dp) per density bucket, in pixels.
const _legacySizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};

void main() {
  testWidgets('build round launcher icons', (tester) async {
    await tester.runAsync(() async {
      final master = await decodeImageFile(legacyMasterPath);
      final source = Rect.fromLTWH(0, 0, master.width.toDouble(), master.height.toDouble());
      for (final MapEntry(key: density, value: size) in _legacySizes.entries) {
        final round = await renderImage(size, size, (canvas) {
          final bounds = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
          canvas.clipPath(Path()..addOval(bounds));
          canvas.drawImageRect(master, source, bounds, Paint()..filterQuality = FilterQuality.medium);
        });
        await writePng(round, '$_resDir/mipmap-$density/ic_launcher_round.png');
      }

      final adaptiveXml = File('$_resDir/mipmap-anydpi-v26/ic_launcher.xml');
      expect(adaptiveXml.existsSync(), isTrue, reason: 'run flutter_launcher_icons first');
      adaptiveXml.copySync('$_resDir/mipmap-anydpi-v26/ic_launcher_round.xml');
    });
  });
}
