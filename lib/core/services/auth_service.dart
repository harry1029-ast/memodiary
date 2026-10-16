import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Service managing device biometrics and encrypted PIN authentication.
class AuthService {
  static const String _pinHashKey = 'memodiary_pin_hash';
  static const String _pinSaltKey = 'memodiary_pin_salt';
  static const String _biometricEnabledKey = 'memodiary_biometric_enabled';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  AuthService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            ),
        _localAuth = localAuth ?? LocalAuthentication();

  /// Whether a PIN has been set and lock is active
  Future<bool> isLockEnabled() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Sets or updates the local PIN with a cryptographic salt and SHA-256 hash
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: hash);
  }

  /// Verifies entered PIN against stored salt + SHA-256 hash
  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _pinSaltKey);
    final storedHash = await _storage.read(key: _pinHashKey);

    if (salt == null || storedHash == null) {
      return false;
    }

    final computedHash = _hashPin(pin, salt);
    return computedHash == storedHash;
  }

  /// Disables lock by removing stored PIN and biometric settings
  Future<void> removePin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    await _storage.delete(key: _biometricEnabledKey);
  }

  /// Whether biometric authentication is enabled by user
  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Toggle biometric unlock preference
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled ? 'true' : 'false');
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

