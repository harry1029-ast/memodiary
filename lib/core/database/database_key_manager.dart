import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages SQLCipher AES-256 encryption keys stored securely in hardware Keystore/Keychain.
class DatabaseKeyManager {
  static const String _keyStorageName = 'memodiary_sqlcipher_key';
  final FlutterSecureStorage _secureStorage;

  DatabaseKeyManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  /// Retrieves the existing 256-bit AES encryption key or creates a cryptographically secure key.
  Future<String> getOrCreateKey() async {
    String? key = await _secureStorage.read(key: _keyStorageName);
    if (key == null || key.isEmpty) {
      key = _generateSecureKey();
      await _secureStorage.write(key: _keyStorageName, value: key);
    }
    return key;
  }

  /// Explicitly clear the stored database key (e.g., during app data wipe)
  Future<void> clearKey() async {
    await _secureStorage.delete(key: _keyStorageName);
  }

  /// Generates a 256-bit (32 bytes) cryptographically random hexadecimal key.
  String _generateSecureKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

