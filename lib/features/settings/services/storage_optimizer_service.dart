import 'dart:io';
import 'package:path/path.dart' as p;
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
    final activeEntries = await database.getAllActiveEntries();
    final deletedEntries = await database.getDeletedEntries();
    final referencedPaths = await database.getAllMediaRelativePaths();
    final dummyFile = await mediaService.getFileFromRelativePath('media/.probe');
    final mediaDir = dummyFile.parent;

    int totalMediaCount = 0;
    int totalMediaBytes = 0;
    int orphanCount = 0;
    int orphanBytes = 0;

    if (mediaDir.existsSync()) {
      final entities = mediaDir.listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          final size = entity.lengthSync();
          final fileName = p.basename(entity.path);
          final relPath = 'media/$fileName';

          totalMediaCount++;
          totalMediaBytes += size;

          // Check if file is referenced in SQLite media_attachments
          if (!referencedPaths.contains(relPath)) {
            orphanCount++;
            orphanBytes += size;
          }
        }
      }
    }

    return StorageStats(
      activeEntriesCount: activeEntries.length,
      deletedEntriesCount: deletedEntries.length,
      totalMediaFiles: totalMediaCount,
      totalMediaBytes: totalMediaBytes,
      orphanMediaFiles: orphanCount,
      orphanMediaBytes: orphanBytes,
    );
  }

  /// Identifies and permanently deletes physical sandbox media files that have
  /// zero references in SQLite `media_attachments`. Reclaims orphaned storage.
  static Future<int> purgeOrphanMedia({
    required AppDatabase database,
    required MediaSandboxService mediaService,
  }) async {
    final referencedPaths = await database.getAllMediaRelativePaths();
    final dummyFile = await mediaService.getFileFromRelativePath('media/.probe');
    final mediaDir = dummyFile.parent;

    if (!await mediaDir.exists()) return 0;

    int purgedCount = 0;
    final entities = mediaDir.listSync(followLinks: false);

    for (final entity in entities) {
      if (entity is File) {
        final fileName = p.basename(entity.path);
        final relPath = 'media/$fileName';

        if (!referencedPaths.contains(relPath)) {
          try {
            await entity.delete();
            purgedCount++;
          } catch (_) {
            // Ignore if file is locked
          }
        }
      }
    }

    return purgedCount;
  }
}

