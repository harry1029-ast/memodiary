// Builds the reframed launcher icon masters from the diarist's painting
// (SPEC-023 Implementation Decision 6). Runs under `flutter test` so dart:ui
// can decode the WebP source and encode the PNG masters:
//
//   flutter test tool/app_icon/build_icon_master.dart
//
// Input:  tool/app_icon/app_icon_source.webp      (1024×1024, diarist-supplied)
// Output: tool/app_icon/app_icon_master.png        (Android adaptive background:
//                                                   subject at 72% so it fits
//                                                   the 66dp safe zone)
//         tool/app_icon/app_icon_master_ios.png    (iOS: subject at 87%, since
//                                                   iOS only rounds the corners)
//         tool/app_icon/app_icon_master_legacy.png (Android legacy square and
//                                                   round icons: the adaptive
//                                                   master's visible 72dp
//                                                   viewport, rendered sharp)
import 'package:flutter_test/flutter_test.dart';

import 'icon_raster_io.dart';
import 'icon_reframe.dart';

const sourcePath = 'tool/app_icon/app_icon_source.webp';
const masterPath = 'tool/app_icon/app_icon_master.png';
const iosMasterPath = 'tool/app_icon/app_icon_master_ios.png';
const legacyMasterPath = 'tool/app_icon/app_icon_master_legacy.png';
const masterSize = 1024;

const adaptiveReframe = IconReframeSpec();

/// iOS framing: the subject fills the icon. Anchoring source row 540 lifts
/// the subject (centred near row 522) by (540 - 522) × 0.87 ≈ 16px.
const iosReframe = IconReframeSpec(scale: 0.87, sourceAnchorY: 540);

/// The adaptive master's centre 72dp of 108dp, so pre-Oreo launchers show
/// what adaptive launchers show: the same anchor at 108/72 of the scale.
final legacyReframe = IconReframeSpec(
  scale: adaptiveReframe.scale * 108 / 72,
  sourceAnchorY: adaptiveReframe.sourceAnchorY,
);

void main() {
  testWidgets('build app icon masters', (tester) async {
    await tester.runAsync(() async {
      final source = await decodeImageFile(sourcePath);
      expect(source.width, source.height, reason: 'the source painting must be square');
      final sourceRgba = await imageRgba(source);
      final outputs = [(masterPath, adaptiveReframe), (iosMasterPath, iosReframe), (legacyMasterPath, legacyReframe)];
      for (final (path, spec) in outputs) {
        final master = reframeIconMaster(sourceRgba, source.width, canvasSize: masterSize, spec: spec);
        await writePng(await imageFromRgba(master, masterSize, masterSize), path);
      }
    });
  });
}
