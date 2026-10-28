import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service managing user preferences for the 3D Book Intro opening screen.
class BookIntroSettingsService {
  static const String _keyShowOnLaunch = 'memodiary_show_book_intro_on_launch';
  final FlutterSecureStorage _storage;

  BookIntroSettingsService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Whether the interactive 3D Book Intro should be displayed on cold app launch.
  /// Defaults to true on first launch.
  Future<bool> getShouldShowOnLaunch() async {
    try {
      final value = await _storage.read(key: _keyShowOnLaunch);
      if (value == null) {
        return true; // Default to true
      }
      return value == 'true';
    } catch (_) {
      return true;
    }
  }

  /// Sets whether the interactive 3D Book Intro should be displayed on cold app launch.
  Future<void> setShouldShowOnLaunch(bool shouldShow) async {
    try {
      await _storage.write(
        key: _keyShowOnLaunch,
        value: shouldShow ? 'true' : 'false',
      );
    } catch (_) {
      // Gracefully handle storage errors
    }
  }
}

