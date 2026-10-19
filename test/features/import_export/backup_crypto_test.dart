import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/import_export/models/backup_manifest.dart';
import 'package:memodiary/features/import_export/services/backup_crypto.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('backup_crypto_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('BackupCrypto — Key Derivation & Header Inspection', () {
    test('deriveKeys produces deterministic 32B encKey and 32B macKey for same salt & passphrase', () {
      final salt = Uint8List.fromList(List<int>.generate(16, (i) => i + 1));
      final keys1 = BackupCrypto.deriveKeys(
        passphrase: 'correct-horse-battery-staple',
        salt: salt,
        iterations: 1000,
      );
      final keys2 = BackupCrypto.deriveKeys(
        passphrase: 'correct-horse-battery-staple',
        salt: salt,
        iterations: 1000,
      );
      final keysDifferentPass = BackupCrypto.deriveKeys(
        passphrase: 'wrong-passphrase',
        salt: salt,
        iterations: 1000,
      );

      expect(keys1.encryptionKey.length, 32);
      expect(keys1.macKey.length, 32);
      expect(keys1.encryptionKey, equals(keys2.encryptionKey));
      expect(keys1.macKey, equals(keys2.macKey));
      expect(keys1.encryptionKey, isNot(equals(keysDifferentPass.encryptionKey)));
      expect(keys1.macKey, isNot(equals(keysDifferentPass.macKey)));
    });

    test('salts and nonce prefixes are randomly generated per encryption call', () async {
      final src = File(p.join(tempDir.path, 'plain.bin'))
        ..writeAsBytesSync([1, 2, 3, 4, 5]);
      final out1 = File(p.join(tempDir.path, 'enc1.mdbak'));
      final out2 = File(p.join(tempDir.path, 'enc2.mdbak'));

      await BackupCrypto.encryptFileChunked(
        sourceFile: src,
        destinationFile: out1,
        passphrase: 'secret-password',
        pbkdf2Iterations: 1000,
      );
      await BackupCrypto.encryptFileChunked(
        sourceFile: src,
        destinationFile: out2,
        passphrase: 'secret-password',
        pbkdf2Iterations: 1000,
      );

      final h1 = await BackupCrypto.readHeader(out1);
      final h2 = await BackupCrypto.readHeader(out2);

      expect(h1.isEncrypted, isTrue);
      expect(h2.isEncrypted, isTrue);
      expect(h1.iterations, 1000);
      expect(h1.salt, isNot(equals(h2.salt)));
      expect(h1.noncePrefix, isNot(equals(h2.noncePrefix)));
    });
  });

  group('BackupCrypto — Chunked AES-256-GCM Round-Trip & Boundary Cases', () {
    test('encrypts and decrypts empty file (0 bytes) with authenticated final chunk', () async {
      final src = File(p.join(tempDir.path, 'empty.bin'))..writeAsBytesSync([]);
      final enc = File(p.join(tempDir.path, 'empty.mdbak'));
      final dec = File(p.join(tempDir.path, 'empty_dec.bin'));

      await BackupCrypto.encryptFileChunked(
        sourceFile: src,
        destinationFile: enc,
        passphrase: 'passphrase-empty',
        pbkdf2Iterations: 1000,
      );

      await BackupCrypto.decryptFileChunked(
        sourceFile: enc,
        destinationFile: dec,
        passphrase: 'passphrase-empty',
      );

      expect(dec.readAsBytesSync(), isEmpty);
    });

    test('encrypts and decrypts exact 1-chunk boundary and multi-chunk (2.5 chunks) payloads', () async {
      const testChunkSize = 1024; // 1 KiB chunk size for fast boundary test
      final exactOneChunk = Uint8List.fromList(
        List<int>.generate(testChunkSize, (i) => i % 256),
      );
      final multiChunk = Uint8List.fromList(
        List<int>.generate((testChunkSize * 2) + 512, (i) => (i * 7) % 256),
      );

      for (final payload in [exactOneChunk, multiChunk]) {
        final src = File(p.join(tempDir.path, 'src_${payload.length}.bin'))
          ..writeAsBytesSync(payload);
        final enc = File(p.join(tempDir.path, 'enc_${payload.length}.mdbak'));
        final dec = File(p.join(tempDir.path, 'dec_${payload.length}.bin'));

        await BackupCrypto.encryptFileChunked(
          sourceFile: src,
          destinationFile: enc,
          passphrase: 'my-strong-passphrase',
          pbkdf2Iterations: 1000,
          chunkSize: testChunkSize,
        );

        await BackupCrypto.decryptFileChunked(
          sourceFile: enc,
          destinationFile: dec,
          passphrase: 'my-strong-passphrase',
        );

        expect(dec.readAsBytesSync(), equals(payload));
      }
    });
  });

  group('BackupCrypto — Tamper, Truncation & Wrong Passphrase Rejection', () {
    test('wrong passphrase fails KCV check with WrongPassphraseException immediately', () async {
      final src = File(p.join(tempDir.path, 'secret.bin'))
        ..writeAsBytesSync(List<int>.generate(2048, (i) => i % 251));
      final enc = File(p.join(tempDir.path, 'secret.mdbak'));
      final dec = File(p.join(tempDir.path, 'secret_dec.bin'));

      await BackupCrypto.encryptFileChunked(
        sourceFile: src,
        destinationFile: enc,
        passphrase: 'correct-password',
        pbkdf2Iterations: 1000,
      );

      await expectLater(
        () => BackupCrypto.decryptFileChunked(
          sourceFile: enc,
          destinationFile: dec,
          passphrase: 'wrong-password',
        ),
        throwsA(isA<WrongPassphraseException>()),
      );
      expect(dec.existsSync(), isFalse);
    });

    test('flipped byte in ciphertext fails AES-GCM authentication tag with BackupCorruptedException', () async {
      final src = File(p.join(tempDir.path, 'data.bin'))
        ..writeAsBytesSync(List<int>.generate(512, (i) => i % 256));
      final enc = File(p.join(tempDir.path, 'data.mdbak'));
      final dec = File(p.join(tempDir.path, 'data_dec.bin'));

      await BackupCrypto.encryptFileChunked(
        sourceFile: src,
        destinationFile: enc,
        passphrase: 'test-password',
        pbkdf2Iterations: 1000,
      );

      // Flip a byte inside the ciphertext payload (after 69B header + 4B len)
      final bytes = enc.readAsBytesSync();
      bytes[80] ^= 0xFF;
      enc.writeAsBytesSync(bytes);

      await expectLater(
        () => BackupCrypto.decryptFileChunked(
          sourceFile: enc,
          destinationFile: dec,
          passphrase: 'test-password',
        ),
        throwsA(isA<BackupCorruptedException>()),
      );
      expect(dec.existsSync(), isFalse);
    });

    test('truncated final chunk is rejected by final-chunk AAD flag', () async {
      const testChunkSize = 512;
      // 2 chunks: 512B + 256B
      final src = File(p.join(tempDir.path, 'two_chunks.bin'))
        ..writeAsBytesSync(List<int>.generate(768, (i) => i % 256));
      final enc = File(p.join(tempDir.path, 'two_chunks.mdbak'));
      final dec = File(p.join(tempDir.path, 'two_chunks_dec.bin'));

      await BackupCrypto.encryptFileChunked(
        sourceFile: src,
        destinationFile: enc,
        passphrase: 'truncation-test',
        pbkdf2Iterations: 1000,
        chunkSize: testChunkSize,
      );

      // Truncate the second chunk completely so only header (69B) + chunk 0 (4B len + 512B + 16B tag) remain
      final fullBytes = enc.readAsBytesSync();
      final truncatedAtFirstChunkBoundary =
          fullBytes.sublist(0, BackupCrypto.encryptedHeaderSize + 4 + 512 + 16);
      enc.writeAsBytesSync(truncatedAtFirstChunkBoundary);

      await expectLater(
        () => BackupCrypto.decryptFileChunked(
          sourceFile: enc,
          destinationFile: dec,
          passphrase: 'truncation-test',
        ),
        throwsA(isA<BackupCorruptedException>()),
      );
      expect(dec.existsSync(), isFalse);
    });

    test('invalid magic header throws BackupFormatException', () async {
      final invalidFile = File(p.join(tempDir.path, 'not_a_backup.mdbak'))
        ..writeAsStringSync('NOT_A_MEMODIARY_BACKUP_ARCHIVE');

      await expectLater(
        () => BackupCrypto.readHeader(invalidFile),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}

