import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';

/// Service managing the soft-delete lifecycle, 30-day auto-purge,
/// and physical media disk file cleanup in MemoDiary.
class RecycleBinService {
  /// Permanently deletes an entry from SQLite after removing all physical media files from the sandbox.
  static Future<void> permanentDeleteEntry({
    required String entryId,
    required AppDatabase database,
    required MediaSandboxService mediaService,
  }) async {
    // 1. Retrieve all linked media attachments to clean up physical storage first
    final attachments = await database.getMediaForEntry(entryId);
    for (final attachment in attachments) {
      await mediaService.deleteMedia(attachment.relativePath);
      if (attachment.thumbnailPath != null &&
          attachment.thumbnailPath!.isNotEmpty) {
        await mediaService.deleteMedia(attachment.thumbnailPath!);
      }
    }

    // 2. Permanently delete SQLite records (media attachments + entry)
    await database.hardDeleteEntryRecords(entryId);
  }

  /// Automatically purges all soft-deleted entries older than the retention duration (default: 30 days).
  /// Reclaims device storage by deleting physical sandboxed media before DB row deletion.
  static Future<int> purgeExpiredEntries({
    required AppDatabase database,
    required MediaSandboxService mediaService,
    Duration retention = const Duration(days: 30),
  }) async {
    final expiredEntries =
        await database.getExpiredDeletedEntries(retention: retention);
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
    final deletedEntries = await database.getDeletedEntries();
    for (final entry in deletedEntries) {
      await permanentDeleteEntry(
        entryId: entry.id,
        database: database,
        mediaService: mediaService,
      );
    }
    return deletedEntries.length;
  }
}

