import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_player/video_player.dart';

/// Default image compressor using [FlutterImageCompress] with WebP output and file-copy fallback.
Future<File?> defaultMediaImageCompressor(
  String sourcePath,
  String targetPath, {
  int minWidth = 1600,
  int minHeight = 1600,
  int quality = 80,
}) async {
  try {
    final xfile = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      format: CompressFormat.webp,
    );
    if (xfile != null) {
      return File(xfile.path);
    }
  } catch (_) {
    // In headless testing or environments without native encoders, fallback to copy
  }

  final source = File(sourcePath);
  if (await source.exists()) {
    return source.copy(targetPath);
  }
  return null;
}

/// Default video duration extractor using [VideoPlayerController].
Future<Duration?> defaultVideoDurationExtractor(File videoFile) async {
  try {
    final controller = VideoPlayerController.file(videoFile);
    await controller.initialize();
    final duration = controller.value.duration;
    await controller.dispose();
    return duration;
  } catch (_) {
    return null;
  }
}

/// Extracts width/height aspect ratio from [imageFile], defaulting to `1.0` if undecodable.
Future<double> extractMediaImageAspectRatio(File imageFile) async {
  try {
    final bytes = await imageFile.readAsBytes();
    if (bytes.isEmpty) return 1.0;
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final width = frame.image.width;
    final height = frame.image.height;
    frame.image.dispose();
    if (width > 0 && height > 0) {
      return width / height;
    }
  } catch (_) {
    // Fallback to 1.0 in headless tests or non-image mock bytes
  }
  return 1.0;
}

/// Renders a procedural vector poster thumbnail using `dart:ui`, with a 1x1 PNG fallback
/// when headless environments do not support rasterization.
Future<File> renderProceduralVideoPoster({
  required String targetThumbnailPath,
  int? durationSeconds,
  int width = 640,
  int height = 360,
}) async {
  final target = File(targetThumbnailPath);
  await target.parent.create(recursive: true);

  try {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    // 1. Dark slate cinematic background
    final bgPaint = ui.Paint()..color = const ui.Color(0xFF1E222D);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      bgPaint,
    );

    // 2. Film border guide
    final framePaint = ui.Paint()
      ..color = const ui.Color(0xFF2E384D)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(24, 24, width - 48.0, height - 48.0),
        const ui.Radius.circular(12),
      ),
      framePaint,
    );

    // 3. Play triangle
    final playPaint = ui.Paint()
      ..color = const ui.Color(0xFFE2E8F0)
      ..style = ui.PaintingStyle.fill;
    final playPath = ui.Path()
      ..moveTo(width / 2.0 - 16, height / 2.0 - 24)
      ..lineTo(width / 2.0 + 24, height / 2.0)
      ..lineTo(width / 2.0 - 16, height / 2.0 + 24)
      ..close();
    canvas.drawPath(playPath, playPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      await target.writeAsBytes(byteData.buffer.asUint8List());
      return target;
    }
  } catch (_) {
    // In headless environments where ui.toImage may not be available
  }

  // Fallback minimal 1x1 transparent PNG if picture recording fails
  final fallbackPng = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);
  await target.writeAsBytes(fallbackPng);
  return target;
}
