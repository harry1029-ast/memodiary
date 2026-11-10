import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the entry editor's app-wide preferences in the existing local
/// settings store. Never part of an entry.
class EditorSettingsService {
  static const String _keyWritingDockHidden = 'memodiary_editor_writing_dock_hidden';

  final FlutterSecureStorage _storage;

  EditorSettingsService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            );

  /// Whether the diarist put the Writing Dock away. Defaults to `false`.
  Future<bool> getIsWritingDockHidden() async {
    try {
      return await _storage.read(key: _keyWritingDockHidden) == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setIsWritingDockHidden(bool isHidden) async {
    try {
      await _storage.write(key: _keyWritingDockHidden, value: isHidden ? 'true' : 'false');
    } catch (_) {
      // Storage errors in restricted environments are absorbed.
    }
  }
}
