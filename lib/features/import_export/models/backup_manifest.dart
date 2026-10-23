import 'dart:convert';
import 'dart:io';
import 'package:memodiary/core/database/app_database.dart';

/// Base exception for all backup and restore errors.
class BackupException implements Exception {
  final String message;
  const BackupException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the file is not a valid `.mdbak` container or has an invalid header.
class BackupFormatException extends BackupException {
  const BackupFormatException(super.message);
}

/// Thrown when the provided passphrase fails KCV verification or AES-GCM authentication.
class WrongPassphraseException extends BackupException {
  const WrongPassphraseException([
    super.message = 'Incorrect passphrase or missing passphrase for encrypted backup.',
  ]);
}

/// Thrown when archive payload, manifest checksum, or media file SHA-256 verification fails.
class BackupCorruptedException extends BackupException {
  const BackupCorruptedException(super.message);
}

/// Thrown when the backup format version or database schema version is newer than supported.
class BackupVersionException extends BackupException {
  const BackupVersionException(super.message);
}

/// Metadata and SHA-256 integrity hash for a single sandboxed media file inside the backup archive.
class BackupMediaRecord {
  final String relativePath;
  final String sha256;
  final int sizeBytes;

  const BackupMediaRecord({
    required this.relativePath,
    required this.sha256,
    required this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
        'relativePath': relativePath,
        'sha256': sha256,
        'sizeBytes': sizeBytes,
      };

  factory BackupMediaRecord.fromJson(Map<String, dynamic> json) {
    final relativePath = json['relativePath'];
    final sha256 = json['sha256'];
    final sizeBytes = json['sizeBytes'];
    if (relativePath is! String || sha256 is! String || sizeBytes is! int) {
      throw const BackupCorruptedException(
        'Invalid media record in backup manifest.',
      );
    }
    return BackupMediaRecord(
      relativePath: relativePath,
      sha256: sha256,
      sizeBytes: sizeBytes,
    );
  }
}

/// Complete snapshot of all SQLite tables (core diary tables + travel memory albums).
class BackupDatabaseSnapshot {
  final List<Template> templates;
  final List<Notebook> notebooks;
  final List<Entry> entries;
  final List<MediaAttachment> mediaAttachments;
  final List<AlbumCollection> albumCollections;
  final List<AlbumPhoto> albumPhotos;

  const BackupDatabaseSnapshot({
    required this.templates,
    required this.notebooks,
    required this.entries,
    required this.mediaAttachments,
    this.albumCollections = const [],
    this.albumPhotos = const [],
  });

  Map<String, dynamic> toJson() => {
        'templates': templates.map((t) => t.toJson()).toList(),
        'notebooks': notebooks.map((n) => n.toJson()).toList(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'mediaAttachments': mediaAttachments.map((m) => m.toJson()).toList(),
        'albumCollections': albumCollections.map((c) => c.toJson()).toList(),
        'albumPhotos': albumPhotos.map((p) => p.toJson()).toList(),
      };

  factory BackupDatabaseSnapshot.fromJson(Map<String, dynamic> json) {
    try {
      final rawTemplates = (json['templates'] as List<dynamic>? ?? [])
          .map((e) => Template.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final rawNotebooks = (json['notebooks'] as List<dynamic>? ?? [])
          .map((e) => Notebook.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final rawEntries = (json['entries'] as List<dynamic>? ?? [])
          .map((e) => Entry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final rawMedia = (json['mediaAttachments'] as List<dynamic>? ?? [])
          .map((e) =>
              MediaAttachment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final rawAlbumCollections =
          (json['albumCollections'] as List<dynamic>? ?? [])
              .map((e) =>
                  AlbumCollection.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
      final rawAlbumPhotos = (json['albumPhotos'] as List<dynamic>? ?? [])
          .map((e) => AlbumPhoto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      return BackupDatabaseSnapshot(
        templates: rawTemplates,
        notebooks: rawNotebooks,
        entries: rawEntries,
        mediaAttachments: rawMedia,
        albumCollections: rawAlbumCollections,
        albumPhotos: rawAlbumPhotos,
      );
    } catch (e) {
      throw BackupCorruptedException(
        'Failed to deserialize database tables from manifest: $e',
      );
    }
  }
}

/// Top-level manifest stored as `manifest.json` inside the `.mdbak` ZIP payload.
class BackupManifest {
  static const String expectedFormat = 'memodiary-backup';
  static const int currentFormatVersion = 1;
  static const int maxSupportedSchemaVersion = 3;

  final String format;
  final int formatVersion;
  final int appSchemaVersion;
  final DateTime createdAt;
  final BackupDatabaseSnapshot snapshot;
  final List<BackupMediaRecord> mediaFiles;

  const BackupManifest({
    this.format = expectedFormat,
    this.formatVersion = currentFormatVersion,
    required this.appSchemaVersion,
    required this.createdAt,
    required this.snapshot,
    required this.mediaFiles,
  });

  Map<String, dynamic> toJson() => {
        'format': format,
        'formatVersion': formatVersion,
        'appSchemaVersion': appSchemaVersion,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'counts': {
          'templates': snapshot.templates.length,
          'notebooks': snapshot.notebooks.length,
          'entries': snapshot.entries.length,
          'mediaAttachments': snapshot.mediaAttachments.length,
          'albumCollections': snapshot.albumCollections.length,
          'albumPhotos': snapshot.albumPhotos.length,
        },
        'tables': snapshot.toJson(),
        'mediaFiles': mediaFiles.map((m) => m.toJson()).toList(),
      };

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    final format = json['format'];
    if (format != expectedFormat) {
      throw BackupFormatException(
        'Unrecognized backup manifest format: $format',
      );
    }

    final formatVersion = json['formatVersion'];
    if (formatVersion is! int || formatVersion < 1) {
      throw BackupFormatException(
        'Invalid backup formatVersion: $formatVersion',
      );
    }
    if (formatVersion > currentFormatVersion) {
      throw BackupVersionException(
        'Backup format version $formatVersion is newer than supported ($currentFormatVersion).',
      );
    }

    final appSchemaVersion = json['appSchemaVersion'];
    if (appSchemaVersion is! int || appSchemaVersion < 1) {
      throw BackupFormatException(
        'Invalid appSchemaVersion: $appSchemaVersion',
      );
    }
    if (appSchemaVersion > maxSupportedSchemaVersion) {
      throw BackupVersionException(
        'Database schema version $appSchemaVersion is newer than supported ($maxSupportedSchemaVersion).',
      );
    }

    final createdAtRaw = json['createdAt'];
    final createdAt = createdAtRaw is String
        ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now().toUtc())
        : DateTime.now().toUtc();

    final tablesRaw = json['tables'];
    if (tablesRaw is! Map) {
      throw const BackupCorruptedException('Missing tables section in manifest.');
    }

    final snapshot = BackupDatabaseSnapshot.fromJson(
      Map<String, dynamic>.from(tablesRaw),
    );

    final mediaListRaw = json['mediaFiles'];
    if (mediaListRaw is! List) {
      throw const BackupCorruptedException(
        'Missing mediaFiles section in manifest.',
      );
    }
    final mediaFiles = mediaListRaw
        .map((m) => BackupMediaRecord.fromJson(
              Map<String, dynamic>.from(m as Map),
            ))
        .toList();

    return BackupManifest(
      format: format as String,
      formatVersion: formatVersion,
      appSchemaVersion: appSchemaVersion,
      createdAt: createdAt,
      snapshot: snapshot,
      mediaFiles: mediaFiles,
    );
  }

  factory BackupManifest.fromJsonString(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) {
        throw const BackupCorruptedException('Manifest root is not a JSON object.');
      }
      return BackupManifest.fromJson(Map<String, dynamic>.from(decoded));
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupCorruptedException('Malformed manifest JSON: $e');
    }
  }
}

/// Header inspection summary of a `.mdbak` file before full decryption/extraction.
class BackupInspection {
  final int formatVersion;
  final bool isEncrypted;
  final int? pbkdf2Iterations;
  final int fileSizeBytes;

  const BackupInspection({
    required this.formatVersion,
    required this.isEncrypted,
    this.pbkdf2Iterations,
    required this.fileSizeBytes,
  });
}

/// Summary returned after creating a backup archive.
class BackupResult {
  final File file;
  final int templatesCount;
  final int notebooksCount;
  final int entriesCount;
  final int mediaFilesCount;
  final int albumCollectionsCount;
  final int albumPhotosCount;
  final int totalBytes;
  final bool isEncrypted;

  const BackupResult({
    required this.file,
    required this.templatesCount,
    required this.notebooksCount,
    required this.entriesCount,
    required this.mediaFilesCount,
    this.albumCollectionsCount = 0,
    this.albumPhotosCount = 0,
    required this.totalBytes,
    required this.isEncrypted,
  });
}

/// Summary returned after restoring a backup archive.
class RestoreResult {
  final int templatesRestored;
  final int notebooksRestored;
  final int entriesRestored;
  final int mediaFilesRestored;
  final int albumCollectionsRestored;
  final int albumPhotosRestored;

  const RestoreResult({
    required this.templatesRestored,
    required this.notebooksRestored,
    required this.entriesRestored,
    required this.mediaFilesRestored,
    this.albumCollectionsRestored = 0,
    this.albumPhotosRestored = 0,
  });
}

