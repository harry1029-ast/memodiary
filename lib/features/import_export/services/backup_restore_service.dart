import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/backup_manifest.dart';
import 'backup_archive_helper.dart';
import 'backup_crypto.dart';

/// Service orchestrating full-archive `.mdbak` creation, inspection, and atomic restoration.
///
/// Guarantees:
/// 1. All 4 SQLite tables (`templates`, `notebooks`, `entries`, `media_attachments`) and all
///    physical sandboxed media (`media/*.webp`, `media/*.mp4`) are bundled with SHA-256 hashes.
/// 2. Optional AES-256-GCM chunked encryption with PBKDF2-HMAC-SHA256 key derivation.
/// 3. Atomic restore pipeline: verifies header, passphrase KCV, manifest SHA-256, path safety
///    (Zip-Slip defense), and every media file SHA-256 in a staging directory BEFORE touching
///    the live SQLite database or live `media/` folder.
class BackupRestoreService {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final Future<Directory> Function() _tempDirProvider;
  final Future<Directory> Function() _baseDirProvider;

  BackupRestoreService({
    required this.database,
    required this.mediaService,
    Future<Directory> Function()? tempDirProvider,
    Future<Directory> Function()? baseDirProvider,
  })  : _tempDirProvider =
            tempDirProvider ?? (() async => Directory.systemTemp),
        _baseDirProvider = baseDirProvider ?? mediaService.getBaseDirectory;

  /// Inspects the `.mdbak` file header without decrypting or unpacking the archive.
  Future<BackupInspection> inspectBackup(File source) async {
    final header = await BackupCrypto.readHeader(source);
    final fileSize = await source.length();
    return BackupInspection(
      formatVersion: header.formatVersion,
      isEncrypted: header.isEncrypted,
      pbkdf2Iterations: header.iterations,
      fileSizeBytes: fileSize,
    );
  }

  Future<File> _getMetadataFile() async {
    final baseDir = await _baseDirProvider();
    return File(p.join(baseDir.path, 'backup_meta.json'));
  }

  /// Returns the timestamp of the last successful backup, or null if no backup has occurred.
  Future<DateTime?> getLastBackupTimestamp() async {
    try {
      final file = await _getMetadataFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final raw = data['lastBackupAt'] as String?;
      return raw != null ? DateTime.tryParse(raw) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _recordLastBackupTimestamp(DateTime timestamp) async {
    try {
      final file = await _getMetadataFile();
      await file.writeAsString(
        jsonEncode({'lastBackupAt': timestamp.toUtc().toIso8601String()}),
        flush: true,
      );
    } catch (_) {}
  }

  /// Creates a portable `.mdbak` full-archive backup at [destination].
  ///
  /// If [passphrase] is non-null and non-empty, the archive is encrypted with
  /// chunked AES-256-GCM using [pbkdf2Iterations].
  Future<BackupResult> createBackup({
    required File destination,
    String? passphrase,
    int pbkdf2Iterations = BackupCrypto.defaultIterations,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.05);

    // 1. Snapshot all SQLite tables inside a consistent read transaction
    final snapshot = await database.backupDao.exportAllTablesSnapshot();
    onProgress?.call(0.15);

    // 2. Discover and hash all physical sandboxed media files
    final baseDir = await mediaService.getBaseDirectory();
    final referencedPaths =
        await database.mediaOcrDao.getAllReferencedMediaPaths();
    final sandboxFiles = await mediaService.listMediaFiles();

    final candidateRelPaths = <String>{
      ...referencedPaths.where(MediaSandboxService.isStrictlyRelative),
      ...sandboxFiles.map((mediaFile) => mediaFile.relativePath),
    };

    final sortedRelPaths = candidateRelPaths.toList()..sort();
    final mediaRecords = <BackupMediaRecord>[];

    for (final relPath in sortedRelPaths) {
      final file = File(p.join(baseDir.path, relPath));
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final digest = crypto.sha256.convert(bytes).toString();
        mediaRecords.add(
          BackupMediaRecord(
            relativePath: relPath,
            sha256: digest,
            sizeBytes: bytes.length,
          ),
        );
      }
    }
    onProgress?.call(0.35);

    // 3. Build manifest JSON and its SHA-256 integrity hash
    final manifest = BackupManifest(
      appSchemaVersion: database.schemaVersion,
      createdAt: DateTime.now().toUtc(),
      snapshot: snapshot,
      mediaFiles: mediaRecords,
    );
    final manifestJson = manifest.toJsonString();
    final manifestSha256 =
        crypto.sha256.convert(utf8.encode(manifestJson)).toString();

    // 4. Bundle ZIP and encrypt inside background Isolate
    final tempRoot = await _tempDirProvider();
    final workDir = Directory(
      p.join(tempRoot.path, 'memodiary_backup_work_${const Uuid().v4()}'),
    );
    await workDir.create(recursive: true);

    final isEncrypted = passphrase != null && passphrase.isNotEmpty;
    final baseDirPath = baseDir.path;
    final workDirPath = workDir.path;
    final destPath = destination.path;
    final recordMaps = mediaRecords.map((record) => record.toJson()).toList();

    try {
      await destination.parent.create(recursive: true);

      await Isolate.run(() async {
        final tempZipPath = p.join(workDirPath, 'payload.zip');
        final encoder = ZipFileEncoder();
        encoder.create(tempZipPath);
        try {
          encoder.addArchiveFile(
            ArchiveFile.string('manifest.json', manifestJson),
          );
          encoder.addArchiveFile(
            ArchiveFile.string('manifest.sha256', manifestSha256),
          );

          for (final map in recordMaps) {
            final relPath = map['relativePath'] as String;
            final srcFile = File(p.join(baseDirPath, relPath));
            if (srcFile.existsSync()) {
              await encoder.addFile(srcFile, relPath);
            }
          }
        } finally {
          await encoder.close();
        }

        final tempZipFile = File(tempZipPath);
        final outFile = File(destPath);

        if (isEncrypted) {
          await BackupCrypto.encryptFileChunked(
            sourceFile: tempZipFile,
            destinationFile: outFile,
            passphrase: passphrase,
            pbkdf2Iterations: pbkdf2Iterations,
          );
        } else {
          await BackupCrypto.wrapUnencryptedZip(
            sourceZip: tempZipFile,
            destination: outFile,
          );
        }
      });

      onProgress?.call(1.0);
      final totalBytes = await destination.length();

      final result = BackupResult(
        file: destination,
        templatesCount: snapshot.templates.length,
        notebooksCount: snapshot.notebooks.length,
        entriesCount: snapshot.entries.length,
        mediaFilesCount: mediaRecords.length,
        albumCollectionsCount: snapshot.albumCollections.length,
        albumPhotosCount: snapshot.albumPhotos.length,
        totalBytes: totalBytes,
        isEncrypted: isEncrypted,
      );

      await _recordLastBackupTimestamp(manifest.createdAt);

      return result;
    } finally {
      if (await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
    }
  }

  /// Atomically restores the database and sandboxed media from a `.mdbak` [source] file.
  ///
  /// If any check (magic header, passphrase KCV, AES-GCM tags, manifest SHA-256,
  /// media SHA-256, Zip-Slip path check, or SQLite foreign-key transaction) fails,
  /// no existing database rows or media files are altered.
  Future<RestoreResult> restoreBackup({
    required File source,
    String? passphrase,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.05);

    // 1. Validate container header before doing any work
    final header = await BackupCrypto.readHeader(source);
    if (header.isEncrypted && (passphrase == null || passphrase.isEmpty)) {
      throw const WrongPassphraseException(
        'This backup is encrypted. Please provide a passphrase.',
      );
    }

    final baseDir = await mediaService.getBaseDirectory();
    final tempRoot = await _tempDirProvider();
    final runId = const Uuid().v4();
    final workDir = Directory(
      p.join(tempRoot.path, 'memodiary_restore_work_$runId'),
    );
    final stagingMediaDir = Directory(
      p.join(baseDir.path, 'media_restore_staging_$runId'),
    );

    await workDir.create(recursive: true);

    try {
      final sourcePath = source.path;
      final workDirPath = workDir.path;
      final stagingDirPath = stagingMediaDir.path;

      // 2. Decrypt/unwrap and verify ZIP + SHA-256 hashes inside background Isolate
      final isEncrypted = header.isEncrypted;
      final manifestJsonStr = await Isolate.run(
        () => unpackAndVerifyBackupArchive(
          isEncrypted: isEncrypted,
          sourcePath: sourcePath,
          workDirPath: workDirPath,
          stagingDirPath: stagingDirPath,
          passphrase: passphrase,
        ),
      );

      onProgress?.call(0.65);

      final manifest = BackupManifest.fromJsonString(manifestJsonStr);

      // 3. Execute atomic SQLite Replace Transaction
      try {
        await database.backupDao.replaceAllFromBackup(manifest.snapshot);
      } catch (e) {
        throw BackupCorruptedException(
          'Database restore transaction failed and was rolled back: $e',
        );
      }

      onProgress?.call(0.85);

      // 4. Swap staged media files into live media/ directory after DB commit succeeds
      final liveMediaDir = Directory(p.join(baseDir.path, 'media'));
      await liveMediaDir.create(recursive: true);

      // Remove existing media files
      await for (final entity
          in liveMediaDir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          await entity.delete();
        }
      }

      // Move staged media files into live media/ directory
      if (await stagingMediaDir.exists()) {
        await for (final entity
            in stagingMediaDir.list(recursive: false, followLinks: false)) {
          if (entity is File) {
            final targetPath = p.join(liveMediaDir.path, p.basename(entity.path));
            try {
              await entity.rename(targetPath);
            } catch (_) {
              await entity.copy(targetPath);
              await entity.delete();
            }
          }
        }
      }

      onProgress?.call(1.0);

      return RestoreResult(
        templatesRestored: manifest.snapshot.templates.length,
        notebooksRestored: manifest.snapshot.notebooks.length,
        entriesRestored: manifest.snapshot.entries.length,
        mediaFilesRestored: manifest.mediaFiles.length,
        albumCollectionsRestored: manifest.snapshot.albumCollections.length,
        albumPhotosRestored: manifest.snapshot.albumPhotos.length,
      );
    } finally {
      if (await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
      if (await stagingMediaDir.exists()) {
        await stagingMediaDir.delete(recursive: true);
      }
    }
  }
}

