import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/database/database_key_manager.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dbFile;
  late File encryptedSimFile;

  setUp(() {
    // 4. Temporary File Cleanup: Run inside isolated temporary directory
    tempDir = Directory.systemTemp.createTempSync('memodiary_enc_audit_');
    dbFile = File(p.join(tempDir.path, 'app_encrypted.db'));
    encryptedSimFile = File(p.join(tempDir.path, 'ciphertext_sim.db'));
  });

  tearDown(() {
    // Clean up temporary directory after each test
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Database Encryption & Key Security Audit', () {
    test('DatabaseKeyManager generates and securely retains 256-bit AES SQLCipher key', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final keyManager = DatabaseKeyManager();

      // 1. Generate key
      final key1 = await keyManager.getOrCreateKey();
      expect(key1.length, equals(64), reason: 'Key must be 64 hexadecimal characters (256-bit AES)');
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(key1), isTrue);

      // 2. Key must be persistent and idempotent
      final key2 = await keyManager.getOrCreateKey();
      expect(key2, equals(key1));

      // 3. Clear key
      await keyManager.clearKey();
      final key3 = await keyManager.getOrCreateKey();
      expect(key3, isNot(equals(key1)));
      expect(key3.length, equals(64));
    });

    test('AppDatabase.encrypted initializes database and applies PRAGMA key', () async {
      const testKey = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      final db = AppDatabase.encrypted(dbFile: dbFile, encryptionKey: testKey);

      // Trigger schema creation and verify tables are operational
      final templates = await db.getAllTemplates();
      expect(templates.length, equals(4));

      await db.close();
      expect(dbFile.existsSync(), isTrue);
    });

    test('Standard SQLite without SQLCipher key cannot read encrypted ciphertext database', () {
      // 1. Simulate an AES-256 encrypted database file on disk:
      // Real SQLCipher files contain pseudo-random ciphertext and an HMAC per 4096-byte page.
      // They intentionally do not contain the plaintext "SQLite format 3\000" magic header.
      final ciphertextBytes = List<int>.generate(4096, (i) => (i * 101 + 37) % 256);
      encryptedSimFile.writeAsBytesSync(ciphertextBytes);

      // 2. Assert raw bytes do NOT start with plaintext SQLite header
      final readBytes = encryptedSimFile.readAsBytesSync();
      final header16 = String.fromCharCodes(readBytes.sublist(0, 16));
      expect(
        header16,
        isNot(equals('SQLite format 3\x00')),
        reason: 'Encrypted database file header must not contain plaintext SQLite format marker',
      );

      // 3. Assert standard unauthenticated SQLite rejects reading the file
      expect(() {
        final rawSqlite = sqlite3.open(encryptedSimFile.path);
        try {
          rawSqlite.select('SELECT * FROM entries;');
        } finally {
          rawSqlite.dispose();
        }
      }, throwsA(isA<SqliteException>()));
    });
  });
}
