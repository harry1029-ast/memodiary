import 'dart:io';
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'media_sandbox_codecs.dart';
import 'media_sandbox_types.dart';

export 'media_sandbox_types.dart';

/// Service managing sandboxed media isolation, WebP compression, video sandboxing,
/// duration capping (<=60s), and strictly relative paths.
class MediaSandboxService {
  static const Set<String> defaultSupportedMediaExtensions = <String>{
    '.webp',
    '.mp4',
    '.png',
    '.jpg',
    '.jpeg',
  };

  final Future<Directory> Function() _getBaseDir;
  final ImageCompressor _compressor;
  final VideoDurationExtractor _durationExtractor;
  final VideoThumbnailGenerator _thumbnailGenerator;
  final AspectRatioExtractor _aspectRatioExtractor;
  final Uuid _uuid;

  MediaSandboxService({
    Future<Directory> Function()? baseDirProvider,
    ImageCompressor? compressor,
    VideoDurationExtractor? durationExtractor,
    VideoThumbnailGenerator? thumbnailGenerator,
    AspectRatioExtractor? aspectRatioExtractor,
    Uuid? uuid,
  })  : _getBaseDir = baseDirProvider ?? getApplicationDocumentsDirectory,
        _compressor = compressor ?? defaultMediaImageCompressor,
        _durationExtractor = durationExtractor ?? defaultVideoDurationExtractor,
        _thumbnailGenerator = thumbnailGenerator ?? _defaultThumbnailGenerator,
        _aspectRatioExtractor =
            aspectRatioExtractor ?? extractMediaImageAspectRatio,
        _uuid = uuid ?? const Uuid();

  /// Default procedural vector poster thumbnail generator (Watchpoint 1).
  static Future<File?> _defaultThumbnailGenerator(
    File videoFile,
    String targetThumbnailPath, {
    int? durationSeconds,
  }) {
    return generateProceduralVideoPoster(
      targetThumbnailPath: targetThumbnailPath,
      durationSeconds: durationSeconds,
    );
  }

  /// Procedural vector placeholder generated using dart:ui (Zero native C/FFmpeg crash risk).
  static Future<File> generateProceduralVideoPoster({
    required String targetThumbnailPath,
    int? durationSeconds,
    int width = 640,
    int height = 360,
  }) {
    return renderProceduralVideoPoster(
      targetThumbnailPath: targetThumbnailPath,
      durationSeconds: durationSeconds,
      width: width,
      height: height,
    );
  }

  /// Copies an image from source into the sandboxed `media/` directory,
  /// compresses it to WebP (max 1600px, 80% quality), and returns strictly
  /// its relative path (e.g. 'media/{uuid}.webp') for SQLite storage.
  Future<String> copyAndCompressImage(File sourceFile) async {
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source image does not exist', sourceFile.path);
    }

    final baseDir = await _getBaseDir();
    final mediaDir = Directory(p.join(baseDir.path, 'media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final id = _uuid.v4();
    final relativePath = p.join('media', '$id.webp');
    final targetPath = p.join(baseDir.path, relativePath);

    final result = await _compressor(
      sourceFile.path,
      targetPath,
      minWidth: 1600,
      minHeight: 1600,
      quality: 80,
    );

    if (result == null || !await result.exists()) {
      throw const FileSystemException('Failed to compress and save image to sandbox');
    }

    // Always normalize to forward slashes for cross-platform relative path consistency
    return relativePath.replaceAll('\\', '/');
  }

  /// Copies an album photo from [sourceFile] into the sandboxed `media/` directory,
  /// generating both a 1600px full-res WebP (`media/{uuid}.webp`, 80% quality) and
  /// a 300px preview thumbnail WebP (`media/{uuid}_thumb.webp`, 75% quality),
  /// plus extracting its width/height aspect ratio (defaulting to 1.0 if undecodable).
  Future<AlbumPhotoSandboxResult> copyAndProcessAlbumPhoto(
    File sourceFile,
  ) async {
    if (!sourceFile.existsSync()) {
      throw FileSystemException('Source image does not exist', sourceFile.path);
    }

    final baseDir = await _getBaseDir();
    final mediaDir = Directory(p.join(baseDir.path, 'media'));
    if (!mediaDir.existsSync()) {
      mediaDir.createSync(recursive: true);
    }

    final id = _uuid.v4();
    final imageRelPath = p.join('media', '$id.webp');
    final thumbRelPath = p.join('media', '${id}_thumb.webp');
    final imageTargetPath = p.join(baseDir.path, imageRelPath);
    final thumbTargetPath = p.join(baseDir.path, thumbRelPath);

    final fullResResult = await _compressor(
      sourceFile.path,
      imageTargetPath,
      minWidth: 1600,
      minHeight: 1600,
      quality: 80,
    );

    if (fullResResult == null || !fullResResult.existsSync()) {
      throw const FileSystemException(
        'Failed to compress and save full-res album photo to sandbox',
      );
    }

    final thumbResult = await _compressor(
      sourceFile.path,
      thumbTargetPath,
      minWidth: 300,
      minHeight: 300,
      quality: 75,
    );

    if (thumbResult == null || !thumbResult.existsSync()) {
      fullResResult.copySync(thumbTargetPath);
    }

    final aspectRatio = await _aspectRatioExtractor(fullResResult);

    return AlbumPhotoSandboxResult(
      relativeImagePath: imageRelPath.replaceAll('\\', '/'),
      relativeThumbnailPath: thumbRelPath.replaceAll('\\', '/'),
      aspectRatio: aspectRatio,
    );
  }

  /// Removes all physical `.webp` full-res, thumbnail, and cover files associated with
  /// [collectionId] from the `media/` sandbox directory (unless referenced by another
  /// collection or photo) before deleting the collection and its photos from [database].
  Future<void> deleteCollectionAndMedia({
    required String collectionId,
    required AppDatabase database,
  }) async {
    final collection = await (database.select(database.albumCollections)
          ..where((tbl) => tbl.id.equals(collectionId)))
        .getSingleOrNull();
    final photos = await (database.select(database.albumPhotos)
          ..where((tbl) => tbl.collectionId.equals(collectionId)))
        .get();

    final candidatePaths = <String>{};
    if (collection?.coverImagePath != null &&
        collection!.coverImagePath!.isNotEmpty) {
      candidatePaths.add(collection.coverImagePath!);
    }
    for (final photo in photos) {
      if (photo.relativeImagePath.isNotEmpty) {
        candidatePaths.add(photo.relativeImagePath);
      }
      if (photo.relativeThumbnailPath.isNotEmpty) {
        candidatePaths.add(photo.relativeThumbnailPath);
      }
    }

    // Check if any candidate path is still referenced outside this collection
    final otherCollections = await (database.select(database.albumCollections)
          ..where((tbl) => tbl.id.isNotValue(collectionId)))
        .get();
    final otherPhotos = await (database.select(database.albumPhotos)
          ..where((tbl) => tbl.collectionId.isNotValue(collectionId)))
        .get();

    final externallyReferenced = <String>{
      for (final otherCol in otherCollections)
        if (otherCol.coverImagePath != null) otherCol.coverImagePath!,
      for (final otherPhoto in otherPhotos) ...[
        otherPhoto.relativeImagePath,
        otherPhoto.relativeThumbnailPath,
      ],
    };

    for (final relPath in candidatePaths) {
      if (!externallyReferenced.contains(relPath) &&
          isStrictlyRelative(relPath)) {
        await deleteMedia(relPath);
      }
    }

    await database.transaction(() async {
      await (database.delete(database.albumPhotos)
            ..where((tbl) => tbl.collectionId.equals(collectionId)))
          .go();
      await (database.delete(database.albumCollections)
            ..where((tbl) => tbl.id.equals(collectionId)))
          .go();
    });
  }

  /// Removes the physical `.webp` full-res and thumbnail files for a single [photoId]
  /// (and clears `coverImagePath` on its parent collection if it pointed to this photo)
  /// before deleting the photo record from [database].
  Future<void> deletePhotoAndMedia({
    required String photoId,
    required AppDatabase database,
  }) async {
    final photo = await (database.select(database.albumPhotos)
          ..where((tbl) => tbl.id.equals(photoId)))
        .getSingleOrNull();
    if (photo == null) return;

    final candidatePaths = <String>{
      if (photo.relativeImagePath.isNotEmpty) photo.relativeImagePath,
      if (photo.relativeThumbnailPath.isNotEmpty) photo.relativeThumbnailPath,
    };

    // If parent collection's coverImagePath matches this photo, clear or reassign it
    final parentCollection = await (database.select(database.albumCollections)
          ..where((tbl) => tbl.id.equals(photo.collectionId)))
        .getSingleOrNull();

    final otherPhotos = await (database.select(database.albumPhotos)
          ..where((tbl) => tbl.id.isNotValue(photoId)))
        .get();
    final otherCollections = await (database.select(database.albumCollections)
          ..where((tbl) => tbl.id.isNotValue(photo.collectionId)))
        .get();

    final externallyReferenced = <String>{
      for (final otherCol in otherCollections)
        if (otherCol.coverImagePath != null) otherCol.coverImagePath!,
      for (final otherPhoto in otherPhotos) ...[
        otherPhoto.relativeImagePath,
        otherPhoto.relativeThumbnailPath,
      ],
      if (parentCollection?.coverImagePath != null &&
          !candidatePaths.contains(parentCollection!.coverImagePath))
        parentCollection.coverImagePath!,
    };

    for (final relPath in candidatePaths) {
      if (!externallyReferenced.contains(relPath) &&
          isStrictlyRelative(relPath)) {
        await deleteMedia(relPath);
      }
    }

    await database.transaction(() async {
      await (database.delete(database.albumPhotos)
            ..where((tbl) => tbl.id.equals(photoId)))
          .go();

      if (parentCollection?.coverImagePath != null &&
          candidatePaths.contains(parentCollection!.coverImagePath)) {
        final remainingPhotos = await (database.select(database.albumPhotos)
              ..where((tbl) => tbl.collectionId.equals(photo.collectionId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
            .get();
        final nextCover = remainingPhotos.isNotEmpty
            ? remainingPhotos.first.relativeImagePath
            : null;
        await (database.update(database.albumCollections)
              ..where((tbl) => tbl.id.equals(photo.collectionId)))
            .write(
          AlbumCollectionsCompanion(
            coverImagePath: Value(nextCover),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  /// Copies a short video (<=60s) into the sandboxed `media/` directory as `media/{uuid}.mp4`,
  /// generates its companion first-frame poster thumbnail as `media/{uuid}_thumb.webp`,
  /// and returns a [VideoSandboxResult] with strictly relative paths.
  Future<VideoSandboxResult> copyAndSandboxVideo(
    File sourceFile, {
    Duration maxDuration = const Duration(seconds: 60),
  }) async {
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source video does not exist', sourceFile.path);
    }

    // 1. Validate video duration
    final duration = await _durationExtractor(sourceFile);
    if (duration != null && duration > maxDuration) {
      throw VideoDurationExceededException(
        durationSeconds: duration.inSeconds,
        maxAllowedSeconds: maxDuration.inSeconds,
      );
    }

    final baseDir = await _getBaseDir();
    final mediaDir = Directory(p.join(baseDir.path, 'media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final id = _uuid.v4();
    final videoRelPath = p.join('media', '$id.mp4');
    final thumbRelPath = p.join('media', '${id}_thumb.webp');
    final videoTargetPath = p.join(baseDir.path, videoRelPath);
    final thumbTargetPath = p.join(baseDir.path, thumbRelPath);

    // 2. Copy video into sandboxed storage
    await sourceFile.copy(videoTargetPath);

    // 3. Generate companion poster thumbnail
    final durationSec = duration?.inSeconds ?? 0;
    final thumbFile = await _thumbnailGenerator(
      File(videoTargetPath),
      thumbTargetPath,
      durationSeconds: durationSec,
    );

    if (thumbFile == null || !await thumbFile.exists()) {
      await generateProceduralVideoPoster(
        targetThumbnailPath: thumbTargetPath,
        durationSeconds: durationSec,
      );
    }

    return VideoSandboxResult(
      relativePath: videoRelPath.replaceAll('\\', '/'),
      thumbnailPath: thumbRelPath.replaceAll('\\', '/'),
      durationSeconds: durationSec,
    );
  }

  /// Returns the base directory containing the sandboxed `media/` folder.
  Future<Directory> getBaseDirectory() => _getBaseDir();

  /// Resolves a sandboxed relative path (e.g. 'media/{uuid}.webp') into an absolute File
  Future<File> getFileFromRelativePath(String relativePath) async {
    final baseDir = await _getBaseDir();
    final fullPath = p.join(baseDir.path, relativePath);
    return File(fullPath);
  }

  /// Resolves a sandboxed relative path into an absolute string path.
  Future<String> resolveAbsolutePath(String relativePath) async {
    final file = await getFileFromRelativePath(relativePath);
    return file.path;
  }

  /// Deletes a sandboxed media file given its relative path
  Future<bool> deleteMedia(String relativePath) async {
    final file = await getFileFromRelativePath(relativePath);
    if (file.existsSync()) {
      file.deleteSync();
      return true;
    }
    return false;
  }

  /// Lists supported media files in `media/`, skipping dotfiles (`.*`).
  Future<List<MediaSandboxFile>> listMediaFiles({
    Set<String>? allowedExtensions,
  }) async {
    final normalizedExts = (allowedExtensions ?? defaultSupportedMediaExtensions)
        .map((ext) {
          final lower = ext.trim().toLowerCase();
          return lower.startsWith('.') ? lower : '.$lower';
        })
        .toSet();
    if (normalizedExts.isEmpty) return const [];

    final baseDir = await _getBaseDir();
    final mediaDir = Directory(p.join(baseDir.path, 'media'));
    if (!mediaDir.existsSync()) return const [];

    final files = <MediaSandboxFile>[];
    for (final entity in mediaDir.listSync(followLinks: false)) {
      if (entity is! File) continue;
      final fileName = p.basename(entity.path);
      if (fileName.startsWith('.')) continue;
      final ext = p.extension(fileName).toLowerCase();
      if (!normalizedExts.contains(ext)) continue;
      files.add(
        MediaSandboxFile(
          relativePath: 'media/$fileName',
          sizeBytes: entity.lengthSync(),
        ),
      );
    }
    files.sort((left, right) => left.relativePath.compareTo(right.relativePath));
    return files;
  }

  /// Batch-deletes strictly relative media paths, tolerating missing or unsafe paths.
  Future<int> deleteMediaPaths(Iterable<String> relativePaths) async {
    final baseDir = await _getBaseDir();
    final seen = <String>{};
    var deletedCount = 0;
    for (final rawPath in relativePaths) {
      final normalized = rawPath.trim().replaceAll('\\', '/');
      if (!isStrictlyRelative(normalized) || !seen.add(normalized)) continue;
      final file = File(p.join(baseDir.path, normalized));
      try {
        if (file.existsSync()) {
          file.deleteSync();
          deletedCount++;
        }
      } catch (_) {}
    }
    return deletedCount;
  }

  /// Validates that a path is strictly relative and does not leak system gallery roots or traverse directories
  static bool isStrictlyRelative(String path) {
    if (path.isEmpty) return false;
    if (path.startsWith('/') || path.startsWith('\\')) return false;
    if (RegExp(r'^[a-zA-Z]:').hasMatch(path)) return false; // Windows drive letters
    final segments = path.split(RegExp(r'[/\\]'));
    if (segments.contains('..')) return false;
    return true;
  }
}
