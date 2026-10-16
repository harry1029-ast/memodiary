import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/database_key_manager.dart';
import '../services/auth_service_test.dart';

void main() {
  late FakeSecureStorage fakeStorage;
  late DatabaseKeyManager keyManager;

  setUp(() {
    fakeStorage = FakeSecureStorage();
    keyManager = DatabaseKeyManager(secureStorage: fakeStorage);
  });

  group('DatabaseKeyManager Tests', () {
    test('generates and persists 256-bit hex encryption key', () async {
      final key1 = await keyManager.getOrCreateKey();

      // 32 bytes hex encoded = 64 characters
      expect(key1.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(key1), isTrue);

      // Re-calling retrieves the same persisted key
      final key2 = await keyManager.getOrCreateKey();
      expect(key2, equals(key1));
    });

    test('clearKey deletes the stored key', () async {
      final key1 = await keyManager.getOrCreateKey();
      expect(fakeStorage.data.containsKey('memodiary_sqlcipher_key'), isTrue);

      await keyManager.clearKey();
      expect(fakeStorage.data.containsKey('memodiary_sqlcipher_key'), isFalse);

      final key3 = await keyManager.getOrCreateKey();
      expect(key3, isNot(equals(key1)));
    });
  });
}

