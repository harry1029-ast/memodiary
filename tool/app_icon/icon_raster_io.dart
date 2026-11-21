// dart:ui raster helpers for the app-icon tool scripts. They run under
// `flutter test` (inside `tester.runAsync`), where the engine decodes WebP and
// encodes PNG, so no host imaging tools are needed.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Decodes an image file (WebP, PNG, ...) into a [ui.Image].
Future<ui.Image> decodeImageFile(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// The image's pixels as straight-alpha RGBA bytes.
Future<Uint8List> imageRgba(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  return data!.buffer.asUint8List();
}

/// Wraps straight-alpha RGBA bytes in a [ui.Image].
Future<ui.Image> imageFromRgba(Uint8List rgba, int width, int height) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: width,
    height: height,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Records [paint] onto a [width]×[height] transparent canvas.
Future<ui.Image> renderImage(int width, int height, void Function(ui.Canvas canvas) paint) {
  final recorder = ui.PictureRecorder();
  paint(ui.Canvas(recorder));
  return recorder.endRecording().toImage(width, height);
}

/// Writes [image] as a PNG, creating parent directories.
Future<void> writePng(ui.Image image, String path) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(data!.buffer.asUint8List());
}
