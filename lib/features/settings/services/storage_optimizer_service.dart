import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';

/// Storage usage metrics for the application
class StorageStats {
  final int activeEntriesCount;
  final int deletedEntriesCount;
  final int totalMediaFiles;
  final int totalMediaBytes;
  final int orphanMediaFiles;
  final int orphanMediaBytes;

  const StorageStats({
    required this.activeEntriesCount,
    required this.deletedEntriesCount,
    required this.totalMediaFiles,
    required this.totalMediaBytes,
    required this.orphanMediaFiles,
    required this.orphanMediaBytes,
  });

  String get totalMediaFormatted => _formatBytes(totalMediaBytes);
  String get orphanMediaFormatted => _formatBytes(orphanMediaBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Service managing storage diagnostics, sandboxed media auditing, and orphan file cleanup.
class StorageOptimizerService {
  /// Computes comprehensive storage metrics by comparing physical files with SQLite records.
  static Future<StorageStats> analyzeStorage({
    required AppDatabase database,
    required MediaSandboxService mediaService,
  }) async {
    final activeEntries = await database.entriesDao.getAllActiveEntries();
    final deletedEntries = await database.entriesDao.getDeletedEntries();
    final referencedPaths =
        await database.mediaOcrDao.getAllReferencedMediaPaths();
    final mediaFiles = await mediaService.listMediaFiles();

    var totalMediaBytes = 0;
    var orphanCount = 0;
    var orphanBytes = 0;

    for (final mediaFile in mediaFiles) {
      totalMediaBytes += mediaFile.sizeBytes;
      if (!referencedPaths.contains(mediaFile.relativePath)) {
        orphanCount++;
        orphanBytes += mediaFile.sizeBytes;
      }
    }

    return StorageStats(
      activeEntriesCount: activeEntries.length,
      deletedEntriesCount: deletedEntries.length,
      totalMediaFiles: mediaFiles.length,
      totalMediaBytes: totalMediaBytes,
      orphanMediaFiles: orphanCount,
      orphanMediaBytes: orphanBytes,
    );
  }

  /// Identifies and permanently deletes physical sandbox media files that have
  /// zero references across diary attachments, album photos, and collection covers.
  static Future<int> purgeOrphanMedia({
    required AppDatabase database,
    required MediaSandboxService mediaService,
  }) async {
    final referencedPaths =
        await database.mediaOcrDao.getAllReferencedMediaPaths();
    final mediaFiles = await mediaService.listMediaFiles();
    final orphanPaths = mediaFiles
        .where((mediaFile) => !referencedPaths.contains(mediaFile.relativePath))
        .map((mediaFile) => mediaFile.relativePath);
    return mediaService.deleteMediaPaths(orphanPaths);
  }
}

