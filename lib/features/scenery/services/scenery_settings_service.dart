import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/shanshui_atmosphere.dart';

/// Persists user preferences for the Shanshui Scenery Card (collapsed state and
/// optional permanently pinned atmosphere override) in encrypted local storage.
class ScenerySettingsService {
  static const String _keyCollapsed = 'memodiary_scenery_card_collapsed';
  static const String _keyThoughtSparkHidden = 'memodiary_thought_spark_hidden';
  static const String _keyPinnedSeason = 'memodiary_scenery_pinned_season';
  static const String _keyPinnedTime = 'memodiary_scenery_pinned_time';
  static const String _keyPinnedWeather = 'memodiary_scenery_pinned_weather';

  final FlutterSecureStorage _storage;

  ScenerySettingsService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Whether the timeline Shanshui Scenery Card is collapsed into the ~42px Xuan status strip.
  /// Defaults to `false` (expanded 16:9 painting).
  Future<bool> getIsCollapsed() async {
    try {
      final stored = await _storage.read(key: _keyCollapsed);
      return stored == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Persists whether the timeline Shanshui Scenery Card is collapsed.
  Future<void> setIsCollapsed(bool isCollapsed) async {
    try {
      await _storage.write(
        key: _keyCollapsed,
        value: isCollapsed ? 'true' : 'false',
      );
    } catch (_) {
      // Gracefully absorb storage errors in restricted environments
    }
  }

  /// Whether the Thought Spark dock inside Shanshui Scenery Card is hidden to reveal the full painting.
  Future<bool> getIsThoughtSparkHidden() async {
    try {
      final stored = await _storage.read(key: _keyThoughtSparkHidden);
      return stored == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Persists whether the Thought Spark dock is hidden.
  Future<void> setIsThoughtSparkHidden(bool isHidden) async {
    try {
      await _storage.write(
        key: _keyThoughtSparkHidden,
        value: isHidden ? 'true' : 'false',
      );
    } catch (_) {
      // Gracefully absorb storage errors in restricted environments
    }
  }

  /// Reads the user's permanently pinned [ShanshuiAtmosphereState], or `null` if real-time sync is active.
  Future<ShanshuiAtmosphereState?> getPinnedAtmosphere() async {
    try {
      final rawSeason = await _storage.read(key: _keyPinnedSeason);
      final rawTime = await _storage.read(key: _keyPinnedTime);
      final rawWeather = await _storage.read(key: _keyPinnedWeather);

      final season = ShanshuiSeason.fromId(rawSeason);
      final timeOfDay = ShanshuiTimeOfDay.fromId(rawTime);
      final weather = ShanshuiWeather.fromId(rawWeather);

      if (season == null || timeOfDay == null || weather == null) {
        return null;
      }

      return ShanshuiAtmosphereState(
        season: season,
        timeOfDay: timeOfDay,
        weather: weather,
        isManualPreview: false,
      );
    } catch (_) {
      return null;
    }
  }

  /// Pins a favorite [atmosphere] permanently, or clears the override when `null` is passed.
  Future<void> setPinnedAtmosphere(ShanshuiAtmosphereState? atmosphere) async {
    try {
      if (atmosphere == null) {
        await _storage.delete(key: _keyPinnedSeason);
        await _storage.delete(key: _keyPinnedTime);
        await _storage.delete(key: _keyPinnedWeather);
        return;
      }

      await _storage.write(key: _keyPinnedSeason, value: atmosphere.season.id);
      await _storage.write(key: _keyPinnedTime, value: atmosphere.timeOfDay.id);
      await _storage.write(key: _keyPinnedWeather, value: atmosphere.weather.id);
    } catch (_) {
      // Gracefully absorb storage errors in restricted environments
    }
  }
}

