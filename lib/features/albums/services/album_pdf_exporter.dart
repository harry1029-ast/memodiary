import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../import_export/services/image_format_transcoder.dart';
import '../../import_export/services/pdf_font_resolver.dart';
import '../models/album_spread.dart';
import '../models/album_studio_models.dart';
import '../widgets/album_collection_card.dart';
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
/// Compiles synthesized [AlbumSpread] pages or WYSIWYG [AlbumStudioDocument]
/// layouts into a print-ready PDF with Xuan-paper vector backgrounds,
/// double-hairline literati borders, Cinnabar seals, aspect-ratio-preserving
/// image cells, and single-page hard bounds.
class AlbumPdfExporter {
  const AlbumPdfExporter._();

  // Literati Xuan-paper & Cinnabar palette for vector PDF rendering
  static final PdfColor _xuanGround = PdfColor.fromInt(0xFFFCF9F2);
  static final PdfColor _xuanPureLeaf = PdfColor.fromInt(0xFFFFFFFF);
  static final PdfColor _agedFiber = PdfColor.fromInt(0xFFEFE9DC);
  static final PdfColor _deckleBorder = PdfColor.fromInt(0xFFD8D1C3);
  static final PdfColor _jiaomo = PdfColor.fromInt(0xFF1E1E1E);
  static final PdfColor _nongmo = PdfColor.fromInt(0xFF2D2D2D);
  static final PdfColor _danmo = PdfColor.fromInt(0xFF68645E);
  static final PdfColor _qingmo = PdfColor.fromInt(0xFF9E998F);
  static final PdfColor _cinnabar = PdfColor.fromInt(0xFFB83B2E);
  static final PdfColor _cinnabarDark = PdfColor.fromInt(0xFF982B1F);

  /// Generates a complete PDF photobook byte payload for [collection] and [photos].
  static Future<Uint8List> generatePhotobookPdf({
    required AlbumCollection collection,
    required List<AlbumPhoto> photos,
    required MediaSandboxService mediaService,
    AlbumPdfPageFormat format = AlbumPdfPageFormat.a4Landscape,
    PdfFontResolver? fontResolver,
    Future<Uint8List> Function(Uint8List)? imageTranscoder,
  }) async {
    final resolver = fontResolver ?? PdfFontResolver.cjk();

    final rawStudioJson = collection.studioLayoutJson?.trim();
    if (rawStudioJson != null && rawStudioJson.isNotEmpty) {
      try {
        final studioDoc = AlbumStudioDocument.fromJsonString(rawStudioJson);
        if (studioDoc.pages.isNotEmpty) {
          return await generatePhotobookFromStudioDocument(
            collection: collection,
            studioDocument: studioDoc,
            photos: photos,
            mediaService: mediaService,
            format: format,
            fontResolver: resolver,
            imageTranscoder: imageTranscoder,
          );
        }
      } catch (_) {
        // Fallback to synthesized spreads if legacy/corrupt studio JSON
      }
    }

    final spreads = AlbumLayoutEngine.synthesize(
      collection: collection,
      photos: photos,
    );

    return generatePhotobookFromSpreads(
      spreads: spreads,
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

  /// Generates a PDF photobook directly from pre-synthesized [spreads].
  static Future<Uint8List> generatePhotobookFromSpreads({
    required List<AlbumSpread> spreads,
    required MediaSandboxService mediaService,
    AlbumPdfPageFormat format = AlbumPdfPageFormat.a4Landscape,
    PdfFontResolver? fontResolver,
    Future<Uint8List> Function(Uint8List)? imageTranscoder,
  }) async {
    final resolver = fontResolver ?? PdfFontResolver.cjk();
    final document = pw.Document();
    final pageFormat = format.pdfFormat;
    final totalPages = spreads.length;

    // Pre-resolve and transcode all referenced relative image paths into pw.MemoryImage
    final imageCache = <String, pw.MemoryImage>{};
    for (final spread in spreads) {
      final paths = _collectSpreadImagePaths(spread);
      for (final relativePath in paths) {
        if (imageCache.containsKey(relativePath)) continue;
        final decodedImage = await _loadPdfImage(
          relativePath: relativePath,
          mediaService: mediaService,
          imageTranscoder: imageTranscoder,
        );
        if (decodedImage != null) {
          imageCache[relativePath] = decodedImage;
        }
      }
    }

    for (final spread in spreads) {
      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return _buildSpreadPageFrame(
              spread: spread,
              totalPages: totalPages,
              resolver: resolver,
              imageCache: imageCache,
            );
          },
        ),
      );
    }

    return document.save();
  }

  static List<String> _collectSpreadImagePaths(AlbumSpread spread) {
    switch (spread) {
      case final CoverSpread coverSpread:
        final path = coverSpread.coverImagePath?.trim();
        return (path != null && path.isNotEmpty) ? [path] : const [];
      case final SingleHeroSpread heroSpread:
        return [heroSpread.photo.relativeImagePath];
      case final DuoSpread duoSpread:
        return [
          duoSpread.firstPhoto.relativeImagePath,
          duoSpread.secondPhoto.relativeImagePath,
        ];
      case final QuadSpread quadSpread:
        return quadSpread.photos
            .map((photo) => photo.relativeImagePath)
            .toList();
      case EpilogueSpread():
        return const [];
    }
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

  /// Wraps each spread in a Xuan-paper outer border + 4pt inset inner hairline border
  /// with strict single-page flex bounds.
  static pw.Widget _buildSpreadPageFrame({
    required AlbumSpread spread,
    required int totalPages,
    required PdfFontResolver resolver,
    required Map<String, pw.MemoryImage> imageCache,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        color: _xuanGround,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _deckleBorder, width: 1.2),
      ),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          color: _xuanPureLeaf,
          borderRadius: pw.BorderRadius.circular(7),
          border: pw.Border.all(color: _deckleBorder, width: 0.6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Expanded(
              child: switch (spread) {
                final CoverSpread coverSpread =>
                  _buildCoverSpreadPdf(coverSpread, resolver, imageCache),
                final SingleHeroSpread heroSpread =>
                  _buildSingleHeroSpreadPdf(heroSpread, resolver, imageCache),
                final DuoSpread duoSpread =>
                  _buildDuoSpreadPdf(duoSpread, resolver, imageCache),
                final QuadSpread quadSpread =>
                  _buildQuadSpreadPdf(quadSpread, resolver, imageCache),
                final EpilogueSpread epilogueSpread =>
                  _buildEpilogueSpreadPdf(epilogueSpread, resolver),
              },
            ),
            pw.SizedBox(height: 10),
            _buildPageFooterPdf(spread.pageNumber, totalPages, resolver),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildCoverSpreadPdf(
    CoverSpread coverSpread,
    PdfFontResolver resolver,
    Map<String, pw.MemoryImage> imageCache,
  ) {
    final dateRange = AlbumCollectionCard.formatDateRange(
      coverSpread.startDate,
      coverSpread.endDate,
    );
    final sealLabel = (coverSpread.destinationTag != null &&
            coverSpread.destinationTag!.trim().isNotEmpty)
        ? coverSpread.destinationTag!.trim()
        : '拾光';
    final descriptionText = (coverSpread.description != null &&
            coverSpread.description!.trim().isNotEmpty)
        ? coverSpread.description!.trim()
        : '山河沿路，笔底留痕。';
    final coverMemoryImage = coverSpread.coverImagePath != null
        ? imageCache[coverSpread.coverImagePath!]
        : null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    resolver.sanitizeText('MEMODIARY TRAVEL ALBUM · 旅行影像纪念册'),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                    style: pw.TextStyle(
                      font: resolver.regularFont,
                      fontSize: 9,
                      color: _qingmo,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    resolver.sanitizeText(coverSpread.title),
                    maxLines: 2,
                    overflow: pw.TextOverflow.clip,
                    style: pw.TextStyle(
                      font: resolver.boldFont,
                      fontSize: 22,
                      color: _jiaomo,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    resolver.sanitizeText(
                      '$dateRange  ·  ${coverSpread.photoCount} Photos',
                    ),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                    style: pw.TextStyle(
                      font: resolver.regularFont,
                      fontSize: 10,
                      color: _danmo,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            _buildCinnabarSealPdf(sealLabel, resolver, size: 36),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Expanded(
          child: _buildAspectPreservingImageBox(
            memoryImage: coverMemoryImage,
            resolver: resolver,
            fallbackLabel: coverSpread.title,
            fit: pw.BoxFit.cover,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _agedFiber,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _deckleBorder, width: 0.5),
          ),
          child: pw.Text(
            resolver.sanitizeText(descriptionText),
            maxLines: 3,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              font: resolver.regularFont,
              fontSize: 10.5,
              color: _nongmo,
              lineSpacing: 2.5,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSingleHeroSpreadPdf(
    SingleHeroSpread heroSpread,
    PdfFontResolver resolver,
    Map<String, pw.MemoryImage> imageCache,
  ) {
    final photo = heroSpread.photo;
    final memoryImage = imageCache[photo.relativeImagePath];
    final location = photo.locationTag?.trim();
    final shotDate = photo.shotAt != null
        ? DateFormat('yyyy.MM.dd HH:mm').format(photo.shotAt!)
        : null;
    final caption = (photo.caption != null && photo.caption!.trim().isNotEmpty)
        ? photo.caption!.trim()
        : '静观山水，未题片语。';

    final metadataParts = <String>[
      if (location != null && location.isNotEmpty) location,
      if (shotDate != null) shotDate,
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Expanded(
          child: _buildAspectPreservingImageBox(
            memoryImage: memoryImage,
            resolver: resolver,
            fallbackLabel: photo.relativeImagePath,
            fit: pw.BoxFit.contain,
          ),
        ),
        pw.SizedBox(height: 10),
        if (metadataParts.isNotEmpty) ...[
          pw.Text(
            resolver.sanitizeText(metadataParts.join('  ·  ')),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              font: resolver.boldFont,
              fontSize: 9.5,
              color: _cinnabar,
            ),
          ),
          pw.SizedBox(height: 4),
        ],
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _agedFiber,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _deckleBorder, width: 0.5),
          ),
          child: pw.Text(
            resolver.sanitizeText(caption),
            maxLines: 4,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              font: resolver.regularFont,
              fontSize: 10.5,
              color: _jiaomo,
              lineSpacing: 2.2,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDuoSpreadPdf(
    DuoSpread duoSpread,
    PdfFontResolver resolver,
    Map<String, pw.MemoryImage> imageCache,
  ) {
    final firstCell = _buildDuoCellPdf(
      duoSpread.firstPhoto,
      resolver,
      imageCache[duoSpread.firstPhoto.relativeImagePath],
    );
    final secondCell = _buildDuoCellPdf(
      duoSpread.secondPhoto,
      resolver,
      imageCache[duoSpread.secondPhoto.relativeImagePath],
    );

    if (duoSpread.orientation == DuoLayoutOrientation.sideBySide) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Expanded(child: firstCell),
          pw.SizedBox(width: 12),
          pw.Expanded(child: secondCell),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Expanded(child: firstCell),
        pw.SizedBox(height: 10),
        pw.Expanded(child: secondCell),
      ],
    );
  }

  static pw.Widget _buildDuoCellPdf(
    AlbumPhoto photo,
    PdfFontResolver resolver,
    pw.MemoryImage? memoryImage,
  ) {
    final location = photo.locationTag?.trim();
    final caption = photo.caption?.trim();

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _agedFiber,
        borderRadius: pw.BorderRadius.circular(7),
        border: pw.Border.all(color: _deckleBorder, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Expanded(
            child: _buildAspectPreservingImageBox(
              memoryImage: memoryImage,
              resolver: resolver,
              fallbackLabel: photo.relativeImagePath,
              fit: pw.BoxFit.cover,
            ),
          ),
          if ((location != null && location.isNotEmpty) ||
              (caption != null && caption.isNotEmpty)) ...[
            pw.SizedBox(height: 6),
            if (location != null && location.isNotEmpty)
              pw.Text(
                resolver.sanitizeText(location),
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  font: resolver.boldFont,
                  fontSize: 9,
                  color: _cinnabar,
                ),
              ),
            if (caption != null && caption.isNotEmpty)
              pw.Text(
                resolver.sanitizeText(caption),
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  font: resolver.regularFont,
                  fontSize: 9.5,
                  color: _jiaomo,
                ),
              ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildQuadSpreadPdf(
    QuadSpread quadSpread,
    PdfFontResolver resolver,
    Map<String, pw.MemoryImage> imageCache,
  ) {
    final photos = quadSpread.photos;
    final topRow = photos.take(2).toList();
    final bottomRow = photos.skip(2).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Expanded(
                child: _buildQuadCellPdf(
                  topRow[0],
                  resolver,
                  imageCache[topRow[0].relativeImagePath],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildQuadCellPdf(
                  topRow[1],
                  resolver,
                  imageCache[topRow[1].relativeImagePath],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Expanded(
                child: _buildQuadCellPdf(
                  bottomRow[0],
                  resolver,
                  imageCache[bottomRow[0].relativeImagePath],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: bottomRow.length > 1
                    ? _buildQuadCellPdf(
                        bottomRow[1],
                        resolver,
                        imageCache[bottomRow[1].relativeImagePath],
                      )
                    : pw.Container(
                        decoration: pw.BoxDecoration(
                          color: _agedFiber,
                          borderRadius: pw.BorderRadius.circular(6),
                          border:
                              pw.Border.all(color: _deckleBorder, width: 0.5),
                        ),
                        alignment: pw.Alignment.center,
                        child: _buildCinnabarSealPdf('拾光', resolver, size: 32),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildQuadCellPdf(
    AlbumPhoto photo,
    PdfFontResolver resolver,
    pw.MemoryImage? memoryImage,
  ) {
    final location = photo.locationTag?.trim();
    final caption = photo.caption?.trim();
    final label = (location != null && location.isNotEmpty)
        ? location
        : (caption != null && caption.isNotEmpty ? caption : null);

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: _agedFiber,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _deckleBorder, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Expanded(
            child: _buildAspectPreservingImageBox(
              memoryImage: memoryImage,
              resolver: resolver,
              fallbackLabel: photo.relativeImagePath,
              fit: pw.BoxFit.cover,
            ),
          ),
          if (label != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              resolver.sanitizeText(label),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                font: resolver.regularFont,
                fontSize: 8.5,
                color: _nongmo,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildEpilogueSpreadPdf(
    EpilogueSpread epilogueSpread,
    PdfFontResolver resolver,
  ) {
    final route = epilogueSpread.routeSummary;

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: _agedFiber,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _deckleBorder, width: 0.6),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            resolver.sanitizeText('EPILOGUE · 卷末回望'),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              font: resolver.regularFont,
              fontSize: 10,
              color: _qingmo,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            resolver.sanitizeText(epilogueSpread.title),
            textAlign: pw.TextAlign.center,
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              font: resolver.boldFont,
              fontSize: 20,
              color: _jiaomo,
            ),
          ),
          pw.SizedBox(height: 14),
          if (route != null && route.isNotEmpty) ...[
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: pw.BoxDecoration(
                color: _xuanPureLeaf,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: _deckleBorder, width: 0.6),
              ),
              child: pw.Text(
                resolver.sanitizeText(route),
                textAlign: pw.TextAlign.center,
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  font: resolver.boldFont,
                  fontSize: 11,
                  color: _nongmo,
                ),
              ),
            ),
            pw.SizedBox(height: 14),
          ],
          pw.Text(
            resolver.sanitizeText(
              'Total Photos: ${epilogueSpread.totalPhotos}'
              '${epilogueSpread.totalLocations > 0 ? "  ·  Stops: ${epilogueSpread.totalLocations}" : ""}',
            ),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              font: resolver.regularFont,
              fontSize: 10.5,
              color: _danmo,
            ),
          ),
          pw.SizedBox(height: 18),
          _buildCinnabarSealPdf(epilogueSpread.sealText, resolver, size: 42),
          pw.SizedBox(height: 8),
          pw.Text(
            resolver.sanitizeText('MemoDiary · 拾光日记'),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              font: resolver.regularFont,
              fontSize: 9,
              color: _qingmo,
            ),
          ),
        ],
      ),
    );
  }

  /// Preserves image aspect ratio inside clipped rectangular bounds (`pw.ClipRRect`)
  /// using `pw.BoxFit.cover` or `pw.BoxFit.contain` so portrait/landscape photos never stretch.
  static pw.Widget _buildAspectPreservingImageBox({
    required pw.MemoryImage? memoryImage,
    required PdfFontResolver resolver,
    required String fallbackLabel,
    required pw.BoxFit fit,
  }) {
    if (memoryImage == null) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          color: _agedFiber,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: _deckleBorder, width: 0.5),
        ),
        alignment: pw.Alignment.center,
        child: pw.Text(
          resolver.sanitizeText(fallbackLabel),
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            font: resolver.italicFont,
            fontSize: 9,
            color: _danmo,
          ),
        ),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _agedFiber,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      alignment: pw.Alignment.center,
      child: pw.ClipRRect(
        horizontalRadius: 6,
        verticalRadius: 6,
        child: pw.Image(
          memoryImage,
          fit: fit,
        ),
      ),
    );
  }

  static pw.Widget _buildCinnabarSealPdf(
    String text,
    PdfFontResolver resolver, {
    double size = 36,
  }) {
    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: _cinnabar,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: _cinnabarDark, width: 1.0),
      ),
      child: pw.Text(
        resolver.sanitizeText(text),
        textAlign: pw.TextAlign.center,
        maxLines: 1,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(
          font: resolver.boldFont,
          fontSize: size <= 34 ? 9 : 11,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildPageFooterPdf(
    int pageNumber,
    int totalPages,
    PdfFontResolver resolver,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          resolver.sanitizeText('MemoDiary Travel Photobook'),
          style: pw.TextStyle(
            font: resolver.regularFont,
            fontSize: 8.5,
            color: _qingmo,
          ),
        ),
        pw.Text(
          'Page $pageNumber / $totalPages',
          style: pw.TextStyle(
            font: resolver.regularFont,
            fontSize: 8.5,
            color: _danmo,
          ),
        ),
      ],
    );
  }
}

