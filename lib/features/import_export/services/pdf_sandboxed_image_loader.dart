import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/services/media_sandbox_service.dart';
import 'image_format_transcoder.dart';

/// Shared sandboxed image loader for PDF compilation.
/// Enforces strictly-relative sandbox path checks, reads bytes safely,
/// transcodes non-native formats (e.g., WebP -> PNG) with dimension clamping,
/// and returns a [pw.MemoryImage] or `null` when unavailable.
class PdfSandboxedImageLoader {
  const PdfSandboxedImageLoader._();

  /// Loads and transcodes the sandboxed asset at [relativePath] into a [pw.MemoryImage].
  static Future<pw.MemoryImage?> load({
    required String relativePath,
    required MediaSandboxService mediaService,
    Future<Uint8List> Function(Uint8List)? customTranscoder,
    int maxDimension = 1400,
  }) async {
    final trimmed = relativePath.trim();
    if (trimmed.isEmpty || !MediaSandboxService.isStrictlyRelative(trimmed)) {
      return null;
    }
    try {
      final file = await mediaService.getFileFromRelativePath(trimmed);
      if (!await file.exists()) return null;
      final rawBytes = await file.readAsBytes();
      if (rawBytes.isEmpty) return null;
      final pdfBytes = await ImageFormatTranscoder.ensurePdfCompatibleBytes(
        rawBytes,
        customTranscoder: customTranscoder,
        maxDimension: maxDimension,
      );
      return pw.MemoryImage(pdfBytes);
    } catch (_) {
      return null;
    }
  }
}
