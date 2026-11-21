import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/atmosphere_palettes.dart';
import 'package:memodiary/core/theme/atmosphere_theme_models.dart';
import 'package:memodiary/core/theme/theme_settings_service.dart';
import 'package:memodiary/features/timeline/widgets/chronicle_desk_palette.dart';
import 'package:memodiary/main.dart';

import '../../helpers/mock_secure_storage.dart';

Future<Color> _samplePixel(
  WidgetTester tester,
  Key boundaryKey,
  Offset logicalPoint,
) async {
  final boundary =
      tester.renderObject(find.byKey(boundaryKey)) as RenderRepaintBoundary;
  final dpr = tester.view.devicePixelRatio;
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: dpr));
  final byteData = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final width = image!.width;
  final x = (logicalPoint.dx * dpr).round().clamp(0, image.width - 1);
  final y = (logicalPoint.dy * dpr).round().clamp(0, image.height - 1);
  final offset = (y * width + x) * 4;
  final r = byteData!.getUint8(offset);
  final g = byteData.getUint8(offset + 1);
  final b = byteData.getUint8(offset + 2);
  final a = byteData.getUint8(offset + 3);
  image.dispose();
  return Color.fromARGB(a, r, g, b);
}

void _expectColorClose(Color actual, Color expected, {required String label}) {
  const tolerance = 3.0 / 255.0;
  expect(actual.r, closeTo(expected.r, tolerance), reason: '$label red channel');
  expect(
    actual.g,
    closeTo(expected.g, tolerance),
    reason: '$label green channel',
  );
  expect(
    actual.b,
    closeTo(expected.b, tolerance),
    reason: '$label blue channel',
  );
}

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late ThemeSettingsService themeSettings;

  setUp(() {
    db = AppDatabase.memory();
    mediaService = MediaSandboxService();
    themeSettings = ThemeSettingsService(storage: MockSecureStorage());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'ChronicleDeskHeader completes AnimatedTheme transitions across light, dark, and palette switches',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 860));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const boundaryKey = Key('chronicle_header_theme_boundary');
      await themeSettings.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MemoDiaryApp(
            database: db,
            mediaService: mediaService,
            showIntroOnLaunch: false,
            themeSettings: themeSettings,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final diaryTextRect = tester.getRect(find.text('日记'));
      // Left gutter inside ChronicleDeskHeaderDelegate (paints deskSurroundTop).
      final surroundSample = Offset(3, diaryTextRect.top - 6);
      // Center of the header deskMat region (inside the pinned sliver header).
      final deskMatSample = Offset(200, diaryTextRect.center.dy);

      Future<void> assertRenderedPalette(
        AtmospherePalette palette,
        String stage,
      ) async {
        final expectedDesk = ChronicleDeskPalette.fromAtmosphere(palette);
        final headerFinder = find.byType(SliverPersistentHeader);
        final headerContainers = tester.widgetList<Container>(
          find.descendant(
            of: headerFinder,
            matching: find.byType(Container),
          ),
        );
        final hasSurroundGradient = headerContainers.any((c) {
          final dec = c.decoration;
          return dec is BoxDecoration &&
              dec.gradient is LinearGradient &&
              (dec.gradient! as LinearGradient).colors.first ==
                  expectedDesk.deskSurroundTop;
        });
        expect(
          hasSurroundGradient,
          isTrue,
          reason: '$stage surround gradient should match target palette',
        );
        final hasDeskMatColor = headerContainers.any((c) {
          final dec = c.decoration;
          return dec is BoxDecoration &&
              dec.borderRadius != null &&
              dec.color == expectedDesk.deskMat;
        });
        expect(
          hasDeskMatColor,
          isTrue,
          reason: '$stage deskMat BoxDecoration should match target palette',
        );

        final actualSurround =
            await _samplePixel(tester, boundaryKey, surroundSample);
        _expectColorClose(
          actualSurround,
          expectedDesk.deskSurroundTop,
          label: '$stage surround pixel',
        );

        final actualMat = await _samplePixel(tester, boundaryKey, deskMatSample);
        final matLuminance = actualMat.computeLuminance();
        if (palette.brightness == Brightness.dark) {
          expect(
            matLuminance,
            lessThan(0.08),
            reason: '$stage deskMat pixel $actualMat should be genuinely dark',
          );
        } else {
          expect(
            matLuminance,
            greaterThan(0.65),
            reason: '$stage deskMat pixel $actualMat should be genuinely light',
          );
        }
      }

      // 1. Initial Light (yunhaoDay)
      await assertRenderedPalette(AtmospherePalettes.yunhaoDay, 'Initial Light');

      // 2. Light -> Dark (yunhaoNight) via AnimatedTheme
      await themeSettings.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      await assertRenderedPalette(AtmospherePalettes.yunhaoNight, 'Light->Dark');

      // 3. Dark -> Light (yunhaoDay) via AnimatedTheme
      await themeSettings.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();
      await assertRenderedPalette(AtmospherePalettes.yunhaoDay, 'Dark->Light');

      // 4. Same-brightness palette switch (yunhaoDay -> classicWalnut)
      await themeSettings.setPreset(AtmosphereThemePreset.classic);
      await tester.pumpAndSettle();
      await assertRenderedPalette(
        AtmospherePalettes.classicWalnut,
        'Classic Light',
      );
    },
  );
}
