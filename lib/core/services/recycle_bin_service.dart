import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';

/// Service managing the soft-delete lifecycle, 30-day auto-purge,
/// and physical media disk file cleanup in MemoDiary.
class RecycleBinService {
  /// Permanently deletes an entry from SQLite first, then removes any
  /// unreferenced physical media files from the sandbox.
  static Future<void> permanentDeleteEntry({
    required String entryId,
    required AppDatabase database,
    required MediaSandboxService mediaService,
  }) async {
    final orphanPaths = await database.entriesDao
        .hardDeleteEntryAndCollectMediaPaths(entryId);
    await mediaService.deleteMediaPaths(orphanPaths);
  }

  /// Automatically purges all soft-deleted entries older than the retention duration (default: 30 days).
  /// Commits SQLite row deletion first and cleans up unreferenced sandboxed media afterward.
  static Future<int> purgeExpiredEntries({
    required AppDatabase database,
    required MediaSandboxService mediaService,
    Duration retention = const Duration(days: 30),
  }) async {
    final expiredEntries = await database.entriesDao
        .getExpiredDeletedEntries(retention: retention);
    for (final entry in expiredEntries) {
      await permanentDeleteEntry(
        entryId: entry.id,
        database: database,
        mediaService: mediaService,
      );
    }
    return expiredEntries.length;
  }

  /// Empties all soft-deleted entries currently in the recycle bin.
  static Future<int> emptyRecycleBin({
    required AppDatabase database,
    required MediaSandboxService mediaService,
  }) async {
    final deletedEntries = await database.entriesDao.getDeletedEntries();
    for (final entry in deletedEntries) {
      await permanentDeleteEntry(
        entryId: entry.id,
        database: database,
        mediaService: mediaService,
      );
    }
    return deletedEntries.length;
  }

  /// Calculates the remaining days before a soft-deleted [entry] is permanently purged.
  static int getDaysUntilPermanentDelete(
    Entry entry, {
    Duration retention = const Duration(days: 30),
    DateTime? referenceNow,
  }) {
    final now = referenceNow ?? DateTime.now();
    final expiryDate = entry.updatedAt.add(retention);
    final remaining = expiryDate.difference(now).inDays;
    return remaining > 0 ? remaining : 0;
  }
}
