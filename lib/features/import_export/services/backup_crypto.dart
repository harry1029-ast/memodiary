import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart';
import '../models/backup_manifest.dart';

/// Derived 256-bit AES encryption key and 256-bit HMAC key-check key.
class DerivedBackupKeys {
  final Uint8List encryptionKey;
  final Uint8List macKey;

  const DerivedBackupKeys({
    required this.encryptionKey,
    required this.macKey,
  });
}

/// Parsed `.mdbak` binary container header.
class MdbakHeader {
  final int formatVersion;
  final bool isEncrypted;
  final Uint8List? salt;
  final int? iterations;
  final Uint8List? noncePrefix;
  final Uint8List? keyCheckValue;
  final int payloadOffset;

  const MdbakHeader({
    required this.formatVersion,
    required this.isEncrypted,
    this.salt,
    this.iterations,
    this.noncePrefix,
    this.keyCheckValue,
    required this.payloadOffset,
  });
}

/// Pure-Dart cryptographic engine for `.mdbak` full-archive backups.
///
/// Implements:
/// - PBKDF2-HMAC-SHA256 key derivation (64-byte output: 32B AES-256 key + 32B HMAC key)
/// - 32-byte Key Check Value (`HMAC-SHA256(macKey, "MDBAK-KCV")`) for fast wrong-password rejection
/// - 1 MiB chunked AES-256-GCM authenticated encryption with per-chunk nonces and final-chunk AAD flag
class BackupCrypto {
  /// 8-byte magic header: `"MDBAK\0\0\1"`
  static final Uint8List magicHeaderV1 = Uint8List.fromList([
    0x4D, // 'M'
    0x44, // 'D'
    0x42, // 'B'
    0x41, // 'A'
    0x4B, // 'K'
    0x00,
    0x00,
    0x01, // Version 1
  ]);

  static const int defaultIterations = 200000;
  static const int defaultChunkSize = 1024 * 1024; // 1 MiB
  static const int saltLength = 16;
  static const int noncePrefixLength = 8;
  static const int kcvLength = 32;
  static const int gcmTagLength = 16;
  static const int gcmTagBits = 128;

  static const int plainHeaderSize = 9; // 8B magic + 1B flags
  static const int encryptedHeaderSize =
      9 + saltLength + 4 + noncePrefixLength + kcvLength; // 69 bytes

  static final Uint8List _kcvMessage =
      Uint8List.fromList(utf8.encode('MDBAK-KCV'));

  /// Generates cryptographically secure random bytes.
  static Uint8List randomBytes(int length) {
    final rng = Random.secure();
    final out = Uint8List(length);
    for (int i = 0; i < length; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }

  /// Derives a 32-byte AES-256 encryption key and a 32-byte HMAC key-check key
  /// from [passphrase] and [salt] using PBKDF2-HMAC-SHA256.
  static DerivedBackupKeys deriveKeys({
    required String passphrase,
    required Uint8List salt,
    int iterations = defaultIterations,
  }) {
    if (iterations < 1) {
      throw ArgumentError.value(
        iterations,
        'iterations',
        'PBKDF2 iteration count must be >= 1.',
      );
    }
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    derivator.init(Pbkdf2Parameters(salt, iterations, 64));

    final passphraseBytes = Uint8List.fromList(utf8.encode(passphrase));
    final derived = derivator.process(passphraseBytes);

    return DerivedBackupKeys(
      encryptionKey: Uint8List.fromList(derived.sublist(0, 32)),
      macKey: Uint8List.fromList(derived.sublist(32, 64)),
    );
  }

  /// Computes the 32-byte Key Check Value (`HMAC-SHA256(macKey, "MDBAK-KCV")`).
  static Uint8List computeKeyCheckValue(Uint8List macKey) {
    final hmac = crypto.Hmac(crypto.sha256, macKey);
    final digest = hmac.convert(_kcvMessage);
    return Uint8List.fromList(digest.bytes);
  }

  /// Constant-time byte array comparison to prevent timing side-channel leaks.
  static bool constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Reads and validates the `.mdbak` header from [file].
  static Future<MdbakHeader> readHeader(File file) async {
    if (!await file.exists()) {
      throw const BackupFormatException('Backup file does not exist.');
    }
    final fileLen = await file.length();
    if (fileLen < plainHeaderSize) {
      throw const BackupFormatException(
        'File is too short to be a valid MemoDiary backup (.mdbak).',
      );
    }

    final raf = await file.open(mode: FileMode.read);
    try {
      final prefix = await raf.read(plainHeaderSize);
      // Verify first 7 bytes "MDBAK\0\0"
      for (int i = 0; i < 7; i++) {
        if (prefix[i] != magicHeaderV1[i]) {
          throw const BackupFormatException(
            'Invalid file magic header: not a MemoDiary backup archive.',
          );
        }
      }
      final version = prefix[7];
      if (version < 1) {
        throw BackupFormatException('Invalid container version: $version');
      }
      if (version > 1) {
        throw BackupVersionException(
          'Backup container version $version is newer than supported (1).',
        );
      }

      final flags = prefix[8];
      final isEncrypted = (flags & 0x01) != 0;

      if (!isEncrypted) {
        return MdbakHeader(
          formatVersion: version,
          isEncrypted: false,
          payloadOffset: plainHeaderSize,
        );
      }

      if (fileLen < encryptedHeaderSize) {
        throw const BackupCorruptedException(
          'Encrypted backup header is truncated.',
        );
      }

      final rest = await raf.read(encryptedHeaderSize - plainHeaderSize);
      final salt = Uint8List.fromList(rest.sublist(0, 16));
      final iterData = ByteData.sublistView(rest, 16, 20);
      final iterations = iterData.getUint32(0, Endian.big);
      if (iterations < 1) {
        throw const BackupCorruptedException(
          'Invalid PBKDF2 iteration count in header.',
        );
      }
      final noncePrefix = Uint8List.fromList(rest.sublist(20, 28));
      final kcv = Uint8List.fromList(rest.sublist(28, 60));

      return MdbakHeader(
        formatVersion: version,
        isEncrypted: true,
        salt: salt,
        iterations: iterations,
        noncePrefix: noncePrefix,
        keyCheckValue: kcv,
        payloadOffset: encryptedHeaderSize,
      );
    } finally {
      await raf.close();
    }
  }

  /// Writes an unencrypted `.mdbak` container wrapping [sourceZip] into [destination].
  static Future<void> wrapUnencryptedZip({
    required File sourceZip,
    required File destination,
  }) async {
    final sink = destination.openWrite();
    try {
      final header = Uint8List(plainHeaderSize);
      header.setRange(0, 8, magicHeaderV1);
      header[8] = 0x00; // flags: unencrypted
      sink.add(header);
      await sink.addStream(sourceZip.openRead());
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  /// Extracts the raw ZIP payload from an unencrypted `.mdbak` container.
  static Future<void> unwrapUnencryptedZip({
    required File sourceMdbak,
    required File destinationZip,
  }) async {
    final header = await readHeader(sourceMdbak);
    if (header.isEncrypted) {
      throw const WrongPassphraseException(
        'Backup is encrypted; a passphrase is required.',
      );
    }
    final totalLen = await sourceMdbak.length();
    if (totalLen <= plainHeaderSize) {
      throw const BackupCorruptedException(
        'Unencrypted backup contains no ZIP payload.',
      );
    }

    final sink = destinationZip.openWrite();
    try {
      await sink.addStream(sourceMdbak.openRead(plainHeaderSize));
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  /// Encrypts [sourceFile] into [destinationFile] using chunked AES-256-GCM.
  static Future<void> encryptFileChunked({
    required File sourceFile,
    required File destinationFile,
    required String passphrase,
    int pbkdf2Iterations = defaultIterations,
    int chunkSize = defaultChunkSize,
  }) async {
    if (passphrase.isEmpty) {
      throw ArgumentError('Passphrase cannot be empty for encrypted backup.');
    }
    if (chunkSize < 16) {
      throw ArgumentError.value(chunkSize, 'chunkSize', 'Must be >= 16 bytes.');
    }

    final salt = randomBytes(saltLength);
    final noncePrefix = randomBytes(noncePrefixLength);
    final keys = deriveKeys(
      passphrase: passphrase,
      salt: salt,
      iterations: pbkdf2Iterations,
    );
    final kcv = computeKeyCheckValue(keys.macKey);

    // Construct 69-byte header
    final headerBytes = Uint8List(encryptedHeaderSize);
    headerBytes.setRange(0, 8, magicHeaderV1);
    headerBytes[8] = 0x01; // flags: bit 0 = encrypted
    headerBytes.setRange(9, 25, salt);
    final iterView = ByteData.sublistView(headerBytes, 25, 29);
    iterView.setUint32(0, pbkdf2Iterations, Endian.big);
    headerBytes.setRange(29, 37, noncePrefix);
    headerBytes.setRange(37, 69, kcv);

    final totalPlainLength = await sourceFile.length();
    final rafIn = await sourceFile.open(mode: FileMode.read);
    final rafOut = await destinationFile.open(mode: FileMode.write);

    try {
      await rafOut.writeFrom(headerBytes);

      if (totalPlainLength == 0) {
        // Write a single authenticated empty final chunk
        final encryptedChunk = _encryptSingleChunk(
          plainChunk: Uint8List(0),
          encKey: keys.encryptionKey,
          noncePrefix: noncePrefix,
          chunkCounter: 0,
          isFinal: true,
        );
        final lenBytes = Uint8List(4);
        ByteData.sublistView(lenBytes)
            .setUint32(0, encryptedChunk.length, Endian.big);
        await rafOut.writeFrom(lenBytes);
        await rafOut.writeFrom(encryptedChunk);
        return;
      }

      int bytesProcessed = 0;
      int chunkCounter = 0;

      while (bytesProcessed < totalPlainLength) {
        final remaining = totalPlainLength - bytesProcessed;
        final toRead = remaining < chunkSize ? remaining : chunkSize;
        final plainChunk = await rafIn.read(toRead);
        if (plainChunk.isEmpty) {
          break;
        }
        bytesProcessed += plainChunk.length;
        final isFinal = bytesProcessed == totalPlainLength;

        final encryptedChunk = _encryptSingleChunk(
          plainChunk: plainChunk,
          encKey: keys.encryptionKey,
          noncePrefix: noncePrefix,
          chunkCounter: chunkCounter,
          isFinal: isFinal,
        );

        final lenBytes = Uint8List(4);
        ByteData.sublistView(lenBytes)
            .setUint32(0, encryptedChunk.length, Endian.big);
        await rafOut.writeFrom(lenBytes);
        await rafOut.writeFrom(encryptedChunk);

        chunkCounter++;
      }
    } finally {
      await rafIn.close();
      await rafOut.close();
    }
  }

  /// Decrypts an encrypted `.mdbak` [sourceFile] into [destinationFile].
  ///
  /// Verifies the magic header, Key Check Value (`WrongPassphraseException`),
  /// per-chunk AES-256-GCM tags, and final-chunk truncation marker (`BackupCorruptedException`).
  static Future<void> decryptFileChunked({
    required File sourceFile,
    required File destinationFile,
    required String passphrase,
  }) async {
    final header = await readHeader(sourceFile);
    if (!header.isEncrypted) {
      throw const BackupFormatException(
        'Backup archive is not encrypted; use unwrapUnencryptedZip instead.',
      );
    }
    if (passphrase.isEmpty) {
      throw const WrongPassphraseException('Passphrase is required.');
    }

    final keys = deriveKeys(
      passphrase: passphrase,
      salt: header.salt!,
      iterations: header.iterations!,
    );
    final expectedKcv = computeKeyCheckValue(keys.macKey);
    if (!constantTimeEquals(expectedKcv, header.keyCheckValue!)) {
      throw const WrongPassphraseException(
        'Incorrect backup passphrase.',
      );
    }

    final totalFileLength = await sourceFile.length();
    if (totalFileLength <= encryptedHeaderSize) {
      throw const BackupCorruptedException(
        'Truncated encrypted archive: missing authenticated payload chunks.',
      );
    }

    final rafIn = await sourceFile.open(mode: FileMode.read);
    final rafOut = await destinationFile.open(mode: FileMode.write);
    bool succeeded = false;

    try {
      await rafIn.setPosition(encryptedHeaderSize);
      int pos = encryptedHeaderSize;
      int chunkCounter = 0;

      while (pos < totalFileLength) {
        if (pos + 4 > totalFileLength) {
          throw const BackupCorruptedException(
            'Truncated chunk length prefix in encrypted archive.',
          );
        }
        final lenBuf = await rafIn.read(4);
        final chunkCipherLen =
            ByteData.sublistView(lenBuf).getUint32(0, Endian.big);

        if (chunkCipherLen < gcmTagLength ||
            pos + 4 + chunkCipherLen > totalFileLength) {
          throw const BackupCorruptedException(
            'Corrupted or truncated chunk payload in encrypted archive.',
          );
        }

        final cipherChunk = await rafIn.read(chunkCipherLen);
        pos += 4 + chunkCipherLen;
        final isFinal = pos == totalFileLength;

        final plainChunk = _decryptSingleChunk(
          cipherChunk: cipherChunk,
          encKey: keys.encryptionKey,
          noncePrefix: header.noncePrefix!,
          chunkCounter: chunkCounter,
          isFinal: isFinal,
        );

        if (plainChunk.isNotEmpty) {
          await rafOut.writeFrom(plainChunk);
        }
        chunkCounter++;
      }
      succeeded = true;
    } finally {
      await rafIn.close();
      await rafOut.close();
      if (!succeeded && await destinationFile.exists()) {
        await destinationFile.delete();
      }
    }
  }

  static Uint8List _buildChunkNonce(Uint8List noncePrefix, int chunkCounter) {
    final nonce = Uint8List(12);
    nonce.setRange(0, 8, noncePrefix);
    ByteData.sublistView(nonce, 8, 12).setUint32(0, chunkCounter, Endian.big);
    return nonce;
  }

  static Uint8List _buildChunkAad({required bool isFinal}) {
    final aad = Uint8List(10);
    aad.setRange(0, 8, magicHeaderV1);
    aad[8] = 0x01; // encrypted flag
    aad[9] = isFinal ? 0x01 : 0x00;
    return aad;
  }

  static Uint8List _encryptSingleChunk({
    required Uint8List plainChunk,
    required Uint8List encKey,
    required Uint8List noncePrefix,
    required int chunkCounter,
    required bool isFinal,
  }) {
    final nonce = _buildChunkNonce(noncePrefix, chunkCounter);
    final aad = _buildChunkAad(isFinal: isFinal);

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      true,
      AEADParameters(
        KeyParameter(encKey),
        gcmTagBits,
        nonce,
        aad,
      ),
    );
    return cipher.process(plainChunk);
  }

  static Uint8List _decryptSingleChunk({
    required Uint8List cipherChunk,
    required Uint8List encKey,
    required Uint8List noncePrefix,
    required int chunkCounter,
    required bool isFinal,
  }) {
    final nonce = _buildChunkNonce(noncePrefix, chunkCounter);
    final aad = _buildChunkAad(isFinal: isFinal);

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      false,
      AEADParameters(
        KeyParameter(encKey),
        gcmTagBits,
        nonce,
        aad,
      ),
    );

    try {
      return cipher.process(cipherChunk);
    } on InvalidCipherTextException catch (e) {
      throw BackupCorruptedException(
        'AES-GCM authentication failed at chunk $chunkCounter: ${e.message}',
      );
    } catch (e) {
      throw BackupCorruptedException(
        'Failed to decrypt chunk $chunkCounter: $e',
      );
    }
  }
}

