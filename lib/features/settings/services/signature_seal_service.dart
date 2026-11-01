import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages persistence of the diarist's global Cinnabar Signature Seal inscription (2 to 4 characters).
/// Defaults to '心迹安放' if unset or invalid.
class SignatureSealService {
  static const String _keySealText = 'memodiary_signature_seal_text';
  static const String defaultSealText = '心迹安放';

  final FlutterSecureStorage _storage;

  SignatureSealService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Retrieves the diarist's saved signature seal text (2–4 characters).
  Future<String> getSealText() async {
    try {
      final stored = await _storage.read(key: _keySealText);
      if (stored == null) return defaultSealText;
      final clean = stored.trim();
      if (clean.length < 2 || clean.length > 4) {
        return defaultSealText;
      }
      return clean;
    } catch (_) {
      return defaultSealText;
    }
  }

  /// Persists a valid 2–4 character signature seal inscription.
  Future<void> setSealText(String text) async {
    final clean = text.trim();
    if (clean.length >= 2 && clean.length <= 4) {
      try {
        await _storage.write(key: _keySealText, value: clean);
      } catch (_) {
        // Absorb storage write failure gracefully
      }
    }
  }
}

