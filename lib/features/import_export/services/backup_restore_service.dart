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
    final snapshot = await database.exportAllTablesSnapshot();
    onProgress?.call(0.15);

    // 2. Discover and hash all physical sandboxed media files
    final baseDir = await mediaService.getBaseDirectory();
    final mediaDir = Directory(p.join(baseDir.path, 'media'));

    final candidateRelPaths = <String>{};
    for (final m in snapshot.mediaAttachments) {
      if (m.relativePath.isNotEmpty &&
          MediaSandboxService.isStrictlyRelative(m.relativePath)) {
        candidateRelPaths.add(m.relativePath.replaceAll('\\', '/'));
      }
      if (m.thumbnailPath != null &&
          m.thumbnailPath!.isNotEmpty &&
          MediaSandboxService.isStrictlyRelative(m.thumbnailPath!)) {
        candidateRelPaths.add(m.thumbnailPath!.replaceAll('\\', '/'));
      }
    }

    if (await mediaDir.exists()) {
      await for (final entity in mediaDir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          final rel = 'media/${p.basename(entity.path)}';
          candidateRelPaths.add(rel);
        }
      }
    }

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
    final recordMaps = mediaRecords.map((r) => r.toJson()).toList();

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
      final manifestJsonStr = await Isolate.run(() async {
        final tempZipFile = File(p.join(workDirPath, 'decrypted.zip'));

        if (header.isEncrypted) {
          await BackupCrypto.decryptFileChunked(
            sourceFile: File(sourcePath),
            destinationFile: tempZipFile,
            passphrase: passphrase!,
          );
        } else {
          await BackupCrypto.unwrapUnencryptedZip(
            sourceMdbak: File(sourcePath),
            destinationZip: tempZipFile,
          );
        }

        final inputStream = InputFileStream(tempZipFile.path);
        try {
          final Archive archive;
          try {
            archive = ZipDecoder().decodeStream(inputStream);
          } catch (e) {
            throw BackupCorruptedException('Invalid or corrupted ZIP payload: $e');
          }

          // Zip-Slip & symlink defense on every archive entry
          for (final entry in archive.files) {
            final normalized = entry.name.replaceAll('\\', '/');
            if (entry.isSymbolicLink ||
                !MediaSandboxService.isStrictlyRelative(normalized)) {
              throw BackupCorruptedException(
                'Unsafe path detected in backup archive: ${entry.name}',
              );
            }
          }

          final manifestEntry = archive.find('manifest.json');
          final shaEntry = archive.find('manifest.sha256');
          if (manifestEntry == null || shaEntry == null) {
            throw const BackupCorruptedException(
              'Backup archive is missing manifest.json or manifest.sha256.',
            );
          }

          final manifestBytes = manifestEntry.readBytes();
          final shaBytes = shaEntry.readBytes();
          if (manifestBytes == null || shaBytes == null) {
            throw const BackupCorruptedException(
              'Unable to read manifest.json or manifest.sha256 from archive.',
            );
          }

          final expectedManifestSha =
              utf8.decode(shaBytes, allowMalformed: true).trim().toLowerCase();
          final actualManifestSha =
              crypto.sha256.convert(manifestBytes).toString().toLowerCase();

          if (actualManifestSha != expectedManifestSha) {
            throw const BackupCorruptedException(
              'Manifest SHA-256 checksum mismatch: backup metadata is corrupted.',
            );
          }

          final manifestStr = utf8.decode(manifestBytes);
          final manifest = BackupManifest.fromJsonString(manifestStr);

          // Validate all DB media attachment paths are strictly relative
          for (final att in manifest.snapshot.mediaAttachments) {
            if (!MediaSandboxService.isStrictlyRelative(att.relativePath)) {
              throw BackupCorruptedException(
                'Invalid media attachment relativePath in manifest: ${att.relativePath}',
              );
            }
            if (att.thumbnailPath != null &&
                att.thumbnailPath!.isNotEmpty &&
                !MediaSandboxService.isStrictlyRelative(att.thumbnailPath!)) {
              throw BackupCorruptedException(
                'Invalid media attachment thumbnailPath in manifest: ${att.thumbnailPath}',
              );
            }
          }

          // Extract and verify every media file into stagingMediaDir
          final stagingDir = Directory(stagingDirPath);
          await stagingDir.create(recursive: true);

          for (final mediaRecord in manifest.mediaFiles) {
            final rel = mediaRecord.relativePath.replaceAll('\\', '/');
            if (!MediaSandboxService.isStrictlyRelative(rel) ||
                !rel.startsWith('media/') ||
                p.dirname(rel) != 'media') {
              throw BackupCorruptedException(
                'Invalid media file path in manifest: ${mediaRecord.relativePath}',
              );
            }

            final archiveMedia = archive.find(rel);
            if (archiveMedia == null || !archiveMedia.isFile) {
              throw BackupCorruptedException(
                'Media file listed in manifest is missing from archive: $rel',
              );
            }

            final mediaBytes = archiveMedia.readBytes();
            if (mediaBytes == null) {
              throw BackupCorruptedException(
                'Failed to read media file bytes from archive: $rel',
              );
            }

            if (mediaBytes.length != mediaRecord.sizeBytes) {
              throw BackupCorruptedException(
                'Media file size mismatch for $rel (expected ${mediaRecord.sizeBytes}, got ${mediaBytes.length}).',
              );
            }

            final actualMediaSha =
                crypto.sha256.convert(mediaBytes).toString().toLowerCase();
            if (actualMediaSha != mediaRecord.sha256.toLowerCase()) {
              throw BackupCorruptedException(
                'Media file SHA-256 mismatch for $rel.',
              );
            }

            final stagedFile = File(p.join(stagingDirPath, p.basename(rel)));
            await stagedFile.writeAsBytes(mediaBytes, flush: true);
          }

          return manifestStr;
        } finally {
          await inputStream.close();
        }
      });

      onProgress?.call(0.65);

      final manifest = BackupManifest.fromJsonString(manifestJsonStr);

      // 3. Execute atomic SQLite Replace Transaction
      try {
        await database.replaceAllFromBackup(manifest.snapshot);
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

