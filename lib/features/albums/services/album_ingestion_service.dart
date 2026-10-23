import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../data/album_repository.dart';
import 'exif_date_reader.dart';

/// Immutable progress snapshot emitted during a multi-photo ingestion batch.
class IngestionProgress {
  final int processed;
  final int total;
  final int failed;
  final bool isDone;
  final bool isCancelled;

  const IngestionProgress({
    required this.processed,
    required this.total,
    required this.failed,
    this.isDone = false,
    this.isCancelled = false,
  });

  double get fraction => total <= 0 ? 0.0 : (processed / total).clamp(0.0, 1.0);
}

/// Final summary returned when a multi-photo ingestion batch finishes or is cancelled.
class IngestionResult {
  final int imported;
  final int failed;
  final bool wasCancelled;
  final bool wasTruncatedToMax;

  const IngestionResult({
    required this.imported,
    required this.failed,
    required this.wasCancelled,
    this.wasTruncatedToMax = false,
  });
}

/// Service orchestrating sequential multi-photo ingestion (up to 50 photos per batch).
///
/// Architectural note on concurrency & Isolates:
/// `flutter_image_compress` invokes native platform codecs via platform channels, which
/// already execute image encoding off the main UI thread on Android/iOS and cannot be
/// called inside a plain `Isolate.run` without `BackgroundIsolateBinaryMessenger` setup.
/// Therefore, this service processes photos sequentially on the caller isolate (preventing
/// OOM memory spikes from decoding 50 high-res photos simultaneously), yields between
/// items so UI animations stay at 60 FPS, and commits all generated records in a single
/// atomic `AlbumRepository.addPhotosBatch` SQLite transaction.
class AlbumIngestionService {
  static const int maxBatchSize = 50;

  final AlbumRepository repository;
  final MediaSandboxService mediaService;
  final Future<DateTime?> Function(File source) _captureDateReader;
  final DateTime Function() _clock;
  final Uuid _uuid;

  AlbumIngestionService({
    required this.repository,
    required this.mediaService,
    Future<DateTime?> Function(File source)? captureDateReader,
    DateTime Function()? clock,
    Uuid? uuid,
  })  : _captureDateReader =
            captureDateReader ?? ExifDateReader.readCaptureDate,
        _clock = clock ?? DateTime.now,
        _uuid = uuid ?? const Uuid();

  /// Sequentially ingests up to [maxBatchSize] photos into [collectionId].
  ///
  /// - Reads EXIF capture date from each source file BEFORE WebP compression strips EXIF,
  ///   falling back to `_clock()`.
  /// - Compresses each photo to 1600px full-res WebP and 300px thumbnail WebP.
  /// - If cancelled partway through, commits all photos processed so far.
  /// - Skips unreadable/corrupted files and cleans up any half-written sandbox files.
  Future<IngestionResult> ingest({
    required String collectionId,
    required List<File> sources,
    void Function(IngestionProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    if (sources.isEmpty) {
      onProgress?.call(
        const IngestionProgress(
          processed: 0,
          total: 0,
          failed: 0,
          isDone: true,
        ),
      );
      return const IngestionResult(
        imported: 0,
        failed: 0,
        wasCancelled: false,
      );
    }

    final wasTruncated = sources.length > maxBatchSize;
    final cappedSources =
        wasTruncated ? sources.sublist(0, maxBatchSize) : sources;
    final total = cappedSources.length;

    final existingPhotos = await repository.getPhotosForCollection(collectionId);
    var nextSortOrder = existingPhotos.isEmpty
        ? 0
        : existingPhotos
                .map((photo) => photo.sortOrder)
                .reduce((left, right) => left > right ? left : right) +
            1;

    final pendingCompanions = <AlbumPhotosCompanion>[];
    var processedCount = 0;
    var failedCount = 0;
    var cancelled = false;

    onProgress?.call(
      IngestionProgress(
        processed: 0,
        total: total,
        failed: 0,
      ),
    );

    for (final sourceFile in cappedSources) {
      if (isCancelled?.call() == true) {
        cancelled = true;
        break;
      }

      AlbumPhotoSandboxResult? sandboxed;
      try {
        // 1. Read EXIF capture timestamp from original file prior to WebP compression
        final exifDate = await _captureDateReader(sourceFile);
        final shotAt = exifDate ?? _clock();

        // 2. Compress full-res (1600px) and thumbnail (300px) WebP into media/ sandbox
        sandboxed = await mediaService.copyAndProcessAlbumPhoto(sourceFile);

        final now = _clock();
        pendingCompanions.add(
          AlbumPhotosCompanion.insert(
            id: _uuid.v4(),
            collectionId: collectionId,
            relativeImagePath: sandboxed.relativeImagePath,
            relativeThumbnailPath: sandboxed.relativeThumbnailPath,
            shotAt: Value(shotAt),
            sortOrder: Value(nextSortOrder++),
            aspectRatio: Value(sandboxed.aspectRatio),
            createdAt: Value(now),
          ),
        );
      } catch (_) {
        failedCount++;
        // Clean up any partial sandbox files if compression partially succeeded
        if (sandboxed != null) {
          await mediaService.deleteMedia(sandboxed.relativeImagePath);
          await mediaService.deleteMedia(sandboxed.relativeThumbnailPath);
        }
      }

      processedCount++;
      onProgress?.call(
        IngestionProgress(
          processed: processedCount,
          total: total,
          failed: failedCount,
        ),
      );

      // Yield to the event loop between items so progress UI animations stay at 60 FPS
      await Future<void>.delayed(Duration.zero);
    }

    if (pendingCompanions.isNotEmpty) {
      await repository.addPhotosBatch(collectionId, pendingCompanions);
    }

    onProgress?.call(
      IngestionProgress(
        processed: processedCount,
        total: total,
        failed: failedCount,
        isDone: true,
        isCancelled: cancelled,
      ),
    );

    return IngestionResult(
      imported: pendingCompanions.length,
      failed: failedCount,
      wasCancelled: cancelled,
      wasTruncatedToMax: wasTruncated,
    );
  }
}

