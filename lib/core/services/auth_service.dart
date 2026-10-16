import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service managing device biometrics and encrypted PIN authentication.
class AuthService {
  static const String _pinHashKey = 'memodiary_pin_hash';
  static const String _pinSaltKey = 'memodiary_pin_salt';
  static const String _biometricEnabledKey = 'memodiary_biometric_enabled';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static bool _storageBackendFailed = false;
  static final Map<String, String> _memoryFallback = {};

  AuthService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            ),
        _localAuth = localAuth ?? LocalAuthentication();

  Future<File?> _getFallbackFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File(p.join(dir.path, '.memodiary_auth.json'));
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadFallbackIfNeeded() async {
    if (_memoryFallback.isNotEmpty) return;
    try {
      final file = await _getFallbackFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        map.forEach((k, v) => _memoryFallback[k] = v.toString());
      }
    } catch (_) {}
  }

  Future<void> _saveFallback() async {
    try {
      final file = await _getFallbackFile();
      if (file != null) {
        await file.writeAsString(jsonEncode(_memoryFallback));
      }
    } catch (_) {}
  }

  Future<String?> _readSafe(String key) async {
    if (_storageBackendFailed) {
      await _loadFallbackIfNeeded();
      return _memoryFallback[key];
    }
    try {
      return await _storage.read(key: key);
    } catch (_) {
      _storageBackendFailed = true;
      await _loadFallbackIfNeeded();
      return _memoryFallback[key];
    }
  }

  Future<void> _writeSafe(String key, String value) async {
    if (_storageBackendFailed) {
      _memoryFallback[key] = value;
      await _saveFallback();
      return;
    }
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _storageBackendFailed = true;
      _memoryFallback[key] = value;
      await _saveFallback();
    }
  }

  Future<void> _deleteSafe(String key) async {
    _memoryFallback.remove(key);
    await _saveFallback();
    if (_storageBackendFailed) return;
    try {
      await _storage.delete(key: key);
    } catch (_) {
      _storageBackendFailed = true;
    }
  }

  /// Whether a PIN has been set and lock is active
  Future<bool> isLockEnabled() async {
    final hash = await _readSafe(_pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Sets or updates the local PIN with a cryptographic salt and SHA-256 hash
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _writeSafe(_pinSaltKey, salt);
    await _writeSafe(_pinHashKey, hash);
  }

  /// Verifies entered PIN against stored salt + SHA-256 hash
  Future<bool> verifyPin(String pin) async {
    final salt = await _readSafe(_pinSaltKey);
    final storedHash = await _readSafe(_pinHashKey);

    if (salt == null || storedHash == null) {
      return false;
    }

    final computedHash = _hashPin(pin, salt);
    return computedHash == storedHash;
  }

  /// Disables lock by removing stored PIN and biometric settings
  Future<void> removePin() async {
    await _deleteSafe(_pinHashKey);
    await _deleteSafe(_pinSaltKey);
    await _deleteSafe(_biometricEnabledKey);
  }

  /// Whether biometric authentication is enabled by user
  Future<bool> isBiometricEnabled() async {
    final enabled = await _readSafe(_biometricEnabledKey);
    return enabled == 'true';
  }

  /// Toggle biometric unlock preference
  Future<void> setBiometricEnabled(bool enabled) async {
    await _writeSafe(_biometricEnabledKey, enabled ? 'true' : 'false');
  }

  /// Checks if device hardware supports biometric authentication
  Future<bool> canCheckBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Performs native biometric prompt (Face ID, Fingerprint)
  Future<bool> authenticateBiometric({
    String localizedReason = 'Unlock MemoDiary with biometrics',
  }) async {
    try {
      final canAuth = await canCheckBiometrics();
      if (!canAuth) return false;

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }
}

