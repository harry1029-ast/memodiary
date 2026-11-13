import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:path/path.dart' as p;
import '../models/backup_manifest.dart';
import 'backup_crypto.dart';

/// Decrypts/unwraps a `.mdbak` backup archive, verifies manifest and media SHA-256
/// integrity, checks Zip-Slip/path safety, and extracts verified media files into
/// [stagingDirPath]. Returns the verified `manifest.json` payload string.
Future<String> unpackAndVerifyBackupArchive({
  required bool isEncrypted,
  required String sourcePath,
  required String workDirPath,
  required String stagingDirPath,
  String? passphrase,
}) async {
  final tempZipFile = File(p.join(workDirPath, 'decrypted.zip'));

  if (isEncrypted) {
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
    } catch (error) {
      throw BackupCorruptedException('Invalid or corrupted ZIP payload: $error');
    }

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
    _validateSnapshotMediaPaths(manifest.snapshot);

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
}

void _validateSnapshotMediaPaths(BackupDatabaseSnapshot snapshot) {
  for (final att in snapshot.mediaAttachments) {
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

  for (final col in snapshot.albumCollections) {
    if (col.coverImagePath != null &&
        col.coverImagePath!.isNotEmpty &&
        !MediaSandboxService.isStrictlyRelative(col.coverImagePath!)) {
      throw BackupCorruptedException(
        'Invalid album collection coverImagePath in manifest: ${col.coverImagePath}',
      );
    }
  }

  for (final photo in snapshot.albumPhotos) {
    if (!MediaSandboxService.isStrictlyRelative(photo.relativeImagePath)) {
      throw BackupCorruptedException(
        'Invalid album photo relativeImagePath in manifest: ${photo.relativeImagePath}',
      );
    }
    if (!MediaSandboxService.isStrictlyRelative(photo.relativeThumbnailPath)) {
      throw BackupCorruptedException(
        'Invalid album photo relativeThumbnailPath in manifest: ${photo.relativeThumbnailPath}',
      );
    }
  }
}
