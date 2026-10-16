import 'dart:io';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages SQLCipher AES-256 encryption keys stored securely in hardware Keystore/Keychain.
class DatabaseKeyManager {
  static const String _keyStorageName = 'memodiary_sqlcipher_key';
  final FlutterSecureStorage _secureStorage;
  static String? _cachedFallbackKey;
  static bool _secureStorageFailed = false;

  DatabaseKeyManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  /// Retrieves the existing 256-bit AES encryption key or creates a cryptographically secure key.
  Future<String> getOrCreateKey() async {
    if (_cachedFallbackKey != null) {
      return _cachedFallbackKey!;
    }

    // On Linux desktop, check if fallback key file already exists to avoid calling libsecret entirely
    if (Platform.isLinux) {
      try {
        final docs = await getApplicationDocumentsDirectory();
        final fallbackFile = File(p.join(docs.path, '.memodiary_key'));
        if (await fallbackFile.exists()) {
          final content = (await fallbackFile.readAsString()).trim();
          if (content.length == 64) {
            _cachedFallbackKey = content;
            return content;
          }
        }
      } catch (_) {}
    }

    if (!_secureStorageFailed) {
      try {
        String? key = await _secureStorage.read(key: _keyStorageName);
        if (key != null && key.isNotEmpty) {
          return key;
        }
        key = _generateSecureKey();
        await _secureStorage.write(key: _keyStorageName, value: key);
        return key;
      } catch (_) {
        _secureStorageFailed = true;
      }
    }

    // Graceful fallback for Linux desktop / WSL environments where gnome-keyring is unavailable
    try {
      final docs = await getApplicationDocumentsDirectory();
      final fallbackFile = File(p.join(docs.path, '.memodiary_key'));
      if (await fallbackFile.exists()) {
        _cachedFallbackKey = (await fallbackFile.readAsString()).trim();
        return _cachedFallbackKey!;
      }
      final newKey = _generateSecureKey();
      await fallbackFile.writeAsString(newKey);
      _cachedFallbackKey = newKey;
      return newKey;
    } catch (_) {
      _cachedFallbackKey ??= _generateSecureKey();
      return _cachedFallbackKey!;
    }
  }

  /// Explicitly clear the stored database key (e.g., during app data wipe)
  Future<void> clearKey() async {
    _cachedFallbackKey = null;
    try {
      await _secureStorage.delete(key: _keyStorageName);
    } catch (_) {}
    try {
      final docs = await getApplicationDocumentsDirectory();
      final fallbackFile = File(p.join(docs.path, '.memodiary_key'));
      if (await fallbackFile.exists()) {
        await fallbackFile.delete();
      }
    } catch (_) {}
  }

  /// Generates a 256-bit (32 bytes) cryptographically random hexadecimal key.
  String _generateSecureKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

