// Renders the app-icon approval contact sheet (SPEC-023 Implementation
// Decision 6): the master at 48px and 180px under the Android circle, the
// Android squircle and the iOS rounded square, plus the themed monochrome
// silhouette. Android tiles show the adaptive viewport (the centre 72dp of the
// 108dp layer). Run after build_icon_master.dart:
//
//   flutter test tool/app_icon/render_icon_previews.dart \
//     --dart-define=ICON_PREVIEW_OUT=<path/to/icon-previews.png>
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'build_icon_master.dart' show masterPath;
import 'icon_raster_io.dart';
import 'monochrome_silhouette.dart';

const previewPath = String.fromEnvironment('ICON_PREVIEW_OUT', defaultValue: 'build/app_icon/icon-previews.png');

const _fontFamily = 'Noto Serif SC';
const _sheetBackground = Color(0xFFE9ECF1);
const _ink = Color(0xFF1E2430);
const _smallSize = 48;
const _zoom = 3;
const _largeSize = 180;

typedef _MaskBuilder = Path Function(double size);
typedef _TilePainter = void Function(Canvas canvas, double size);

Path _circleMask(double size) => Path()..addOval(Rect.fromLTWH(0, 0, size, size));

/// AOSP's squircle `config_icon_mask`, scaled from its 100-unit viewport.
Path _squircleMask(double size) {
  final unit = size / 100;
  return Path()
    ..moveTo(50 * unit, 0)
    ..cubicTo(10 * unit, 0, 0, 10 * unit, 0, 50 * unit)
    ..cubicTo(0, 90 * unit, 10 * unit, 100 * unit, 50 * unit, 100 * unit)
    ..cubicTo(90 * unit, 100 * unit, 100 * unit, 90 * unit, 100 * unit, 50 * unit)
    ..cubicTo(100 * unit, 10 * unit, 90 * unit, 0, 50 * unit, 0)
    ..close();
}

Path _iosMask(double size) =>
    Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size, size), Radius.circular(size * 0.2237)));

void main() {
  testWidgets('render app icon previews', (tester) async {
    await tester.runAsync(() async {
      await _loadLabelFont();
      final master = await decodeImageFile(masterPath);
      final masterSide = master.width.toDouble();
      final fullMaster = Rect.fromLTWH(0, 0, masterSide, masterSide);
      final adaptiveViewport = Rect.fromCenter(
        center: fullMaster.center,
        width: masterSide * 72 / 108,
        height: masterSide * 72 / 108,
      );

      _TilePainter artwork(Rect source) => (canvas, size) => canvas.drawImageRect(
            master,
            source,
            Rect.fromLTWH(0, 0, size, size),
            Paint()..filterQuality = FilterQuality.medium,
          );
      _TilePainter themed(Color background, Color foreground) => (canvas, size) {
            canvas.drawColor(background, BlendMode.src);
            final safeSide = size * 66 / 72;
            paintMonochromeSilhouette(
              canvas,
              Rect.fromCenter(center: Offset(size / 2, size / 2), width: safeSide, height: safeSide),
              foreground,
            );
          };

      final rows = <(String, _MaskBuilder, _TilePainter)>[
        ('Android 圆形', _circleMask, artwork(adaptiveViewport)),
        ('Android 方圆形', _squircleMask, artwork(adaptiveViewport)),
        ('iOS 圆角方形', _iosMask, artwork(fullMaster)),
        ('单色剪影 · 浅色主题', _circleMask, themed(const Color(0xFFDCE3F5), const Color(0xFF23314F))),
        ('单色剪影 · 深色主题', _circleMask, themed(const Color(0xFF2A3242), const Color(0xFFC9D6F2))),
      ];

      const margin = 28.0, labelWidth = 250.0, gap = 44.0, rowHeight = 216.0, headerHeight = 96.0;
      const sheetWidth = margin * 2 + labelWidth + _smallSize + _smallSize * _zoom + _largeSize + gap * 3;
      final sheetHeight = headerHeight + rows.length * rowHeight + margin;

      final tiles = <(ui.Image, ui.Image)>[];
      for (final (_, mask, painter) in rows) {
        tiles.add((await _maskedTile(_smallSize, mask, painter), await _maskedTile(_largeSize, mask, painter)));
      }

      final sheet = await renderImage(sheetWidth.toInt(), sheetHeight.toInt(), (canvas) {
        canvas.drawColor(_sheetBackground, BlendMode.src);
        _label(canvas, '云皓日记 · 图标预览', const Offset(margin, 22), 26);
        final columnX = [
          margin + labelWidth,
          margin + labelWidth + _smallSize + gap,
          margin + labelWidth + _smallSize + gap + _smallSize * _zoom + gap,
        ];
        _label(canvas, '48px', Offset(columnX[0], 66), 15);
        _label(canvas, '48px ×$_zoom 放大', Offset(columnX[1], 66), 15);
        _label(canvas, '180px', Offset(columnX[2], 66), 15);

        for (var index = 0; index < rows.length; index++) {
          final top = headerHeight + index * rowHeight;
          final middle = top + _largeSize / 2;
          final (small, large) = tiles[index];
          _label(canvas, rows[index].$1, Offset(margin, middle - 12), 18);
          canvas.drawImage(small, Offset(columnX[0], middle - _smallSize / 2), Paint());
          canvas.drawImageRect(
            small,
            Rect.fromLTWH(0, 0, _smallSize.toDouble(), _smallSize.toDouble()),
            Rect.fromLTWH(
                columnX[1], middle - _smallSize * _zoom / 2, _smallSize * _zoom * 1.0, _smallSize * _zoom * 1.0),
            Paint()..filterQuality = FilterQuality.none,
          );
          canvas.drawImage(large, Offset(columnX[2], top), Paint());
        }
      });
      await writePng(sheet, previewPath);
    });
  });
}

Future<ui.Image> _maskedTile(int size, _MaskBuilder mask, _TilePainter painter) {
  return renderImage(size, size, (canvas) {
    canvas.clipPath(mask(size.toDouble()));
    painter(canvas, size.toDouble());
  });
}

Future<void> _loadLabelFont() async {
  final bytes = File('assets/fonts/NotoSerifSC-Variable.ttf').readAsBytesSync();
  final loader = FontLoader(_fontFamily)..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  await loader.load();
}

void _label(Canvas canvas, String text, Offset position, double fontSize) {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: _fontFamily, fontSize: fontSize))
    ..pushStyle(ui.TextStyle(color: _ink, fontFamily: _fontFamily, fontSize: fontSize))
    ..addText(text);
  final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 400));
  canvas.drawParagraph(paragraph, position);
}
