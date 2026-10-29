import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../import_export/services/image_format_transcoder.dart';
import '../../import_export/services/pdf_font_resolver.dart';
import '../models/album_studio_models.dart';
import 'album_layout_engine.dart';
import 'album_studio_pdf_renderer.dart';

/// Supported page formats for Travel Memory Album PDF photobooks.
enum AlbumPdfPageFormat {
  /// A4 Landscape (`841.89 × 595.28 pt` / `297 × 210 mm`).
  a4Landscape,

  /// Square keepsake photobook (`595.28 × 595.28 pt` / `210 × 210 mm`).
  square,

  /// 2-Page Bound Spread (`1190.56 × 595.28 pt` / `420 × 210 mm`).
  boundSpread;

  PdfPageFormat get pdfFormat {
    switch (this) {
      case AlbumPdfPageFormat.a4Landscape:
        return PdfPageFormat.a4.landscape;
      case AlbumPdfPageFormat.square:
        return const PdfPageFormat(595.28, 595.28, marginAll: 28.0);
      case AlbumPdfPageFormat.boundSpread:
        return const PdfPageFormat(1190.56, 595.28, marginAll: 18.0);
    }
  }

  String get displayLabel {
    switch (this) {
      case AlbumPdfPageFormat.a4Landscape:
        return 'A4 横版画册 (297×210mm)';
      case AlbumPdfPageFormat.square:
        return '方册画幅 (210×210mm)';
      case AlbumPdfPageFormat.boundSpread:
        return '双页跨页画册 (420×210mm)';
    }
  }

  String get fileSuffix {
    switch (this) {
      case AlbumPdfPageFormat.a4Landscape:
        return 'A4';
      case AlbumPdfPageFormat.square:
        return 'Square';
      case AlbumPdfPageFormat.boundSpread:
        return 'Spread';
    }
  }
}

/// High-fidelity vector PDF photobook exporter for Travel Memory Albums.
///
/// Compiles WYSIWYG [AlbumStudioDocument] layouts into a print-ready PDF with
/// Xuan-paper vector backgrounds, double-hairline literati borders, Cinnabar seals,
/// aspect-ratio-preserving image cells, and single-page hard bounds.
class AlbumPdfExporter {
  const AlbumPdfExporter._();

  /// Generates a complete PDF photobook byte payload for [collection] and [photos].
  ///
  /// Automatically resolves or compiles the underlying [AlbumStudioDocument].
  static Future<Uint8List> generatePhotobookPdf({
    required AlbumCollection collection,
    required List<AlbumPhoto> photos,
    required MediaSandboxService mediaService,
    AlbumPdfPageFormat format = AlbumPdfPageFormat.a4Landscape,
    PdfFontResolver? fontResolver,
    Future<Uint8List> Function(Uint8List)? imageTranscoder,
  }) async {
    final resolver = fontResolver ?? PdfFontResolver.cjk();

    final studioDoc = AlbumLayoutEngine.resolveOrCompileDocument(
      collection: collection,
      photos: photos,
    );

    return generatePhotobookFromStudioDocument(
      collection: collection,
      studioDocument: studioDoc,
      photos: photos,
      mediaService: mediaService,
      format: format,
      fontResolver: resolver,
      imageTranscoder: imageTranscoder,
    );
  }

  /// Generates a WYSIWYG PDF photobook directly from an [AlbumStudioDocument].
  static Future<Uint8List> generatePhotobookFromStudioDocument({
    required AlbumCollection collection,
    required AlbumStudioDocument studioDocument,
    required List<AlbumPhoto> photos,
    required MediaSandboxService mediaService,
    AlbumPdfPageFormat format = AlbumPdfPageFormat.a4Landscape,
    PdfFontResolver? fontResolver,
    Future<Uint8List> Function(Uint8List)? imageTranscoder,
  }) async {
    final resolver = fontResolver ?? PdfFontResolver.cjk();
    final document = pw.Document();

    final photoById = <String, AlbumPhoto>{
      for (final photo in photos) photo.id: photo,
    };

    // Collect all referenced relative image paths (cover + placed photo slots)
    final referencedPaths = <String>{};
    final coverPath = collection.coverImagePath?.trim();
    if (coverPath != null && coverPath.isNotEmpty) {
      referencedPaths.add(coverPath);
    }
    for (final photoId in studioDocument.collectReferencedPhotoIds()) {
      final photo = photoById[photoId];
      if (photo != null && photo.relativeImagePath.trim().isNotEmpty) {
        referencedPaths.add(photo.relativeImagePath.trim());
      }
    }

    final imageCache = <String, pw.MemoryImage>{};
    for (final relativePath in referencedPaths) {
      final decodedImage = await _loadPdfImage(
        relativePath: relativePath,
        mediaService: mediaService,
        imageTranscoder: imageTranscoder,
      );
      if (decodedImage != null) {
        imageCache[relativePath] = decodedImage;
      }
    }

    AlbumStudioPdfRenderer.addStudioPagesToDocument(
      document: document,
      collection: collection,
      studioDocument: studioDocument,
      photoById: photoById,
      imageCache: imageCache,
      format: format,
      resolver: resolver,
    );

    return document.save();
  }

  static Future<pw.MemoryImage?> _loadPdfImage({
    required String relativePath,
    required MediaSandboxService mediaService,
    Future<Uint8List> Function(Uint8List)? imageTranscoder,
  }) async {
    final trimmed = relativePath.trim();
    if (trimmed.isEmpty || !MediaSandboxService.isStrictlyRelative(trimmed)) {
      return null;
    }
    try {
      final file = await mediaService.getFileFromRelativePath(trimmed);
      if (!file.existsSync()) return null;
      final rawBytes = file.readAsBytesSync();
      if (rawBytes.isEmpty) return null;
      final pdfBytes = await ImageFormatTranscoder.ensurePdfCompatibleBytes(
        rawBytes,
        customTranscoder: imageTranscoder,
      );
      return pw.MemoryImage(pdfBytes);
    } catch (_) {
      return null;
    }
  }
}
