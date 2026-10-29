import '../../editor/services/audio_sanctum_service.dart';
import '../models/shanshui_atmosphere.dart';

/// Deterministic pure-Dart resolver mapping local device date/time and entry
/// meteorological metadata into a [ShanshuiAtmosphereState] and paired soundscape.
class ShanshuiAtmosphereResolver {
  const ShanshuiAtmosphereResolver._();

  /// Resolves the real-world [ShanshuiAtmosphereState] from [now] and optional [latestEntryWeather].
  static ShanshuiAtmosphereState resolve({
    required DateTime now,
    String? latestEntryWeather,
  }) {
    return ShanshuiAtmosphereState(
      season: resolveSeason(now.month),
      timeOfDay: resolveTimeOfDay(now.hour),
      weather: resolveWeather(latestEntryWeather),
      isManualPreview: false,
    );
  }

  /// Maps calendar month (1..12) into the four classical seasons.
  static ShanshuiSeason resolveSeason(int month) {
    if (month >= 3 && month <= 5) return ShanshuiSeason.spring;
    if (month >= 6 && month <= 8) return ShanshuiSeason.summer;
    if (month >= 9 && month <= 11) return ShanshuiSeason.fall;
    return ShanshuiSeason.winter;
  }

  /// Maps 24-hour local clock hour (0..23) into Dawn, Day, Dusk, or Night.
  static ShanshuiTimeOfDay resolveTimeOfDay(int hour) {
    if (hour >= 5 && hour < 7) return ShanshuiTimeOfDay.dawn;
    if (hour >= 7 && hour < 17) return ShanshuiTimeOfDay.day;
    if (hour >= 17 && hour < 19) return ShanshuiTimeOfDay.dusk;
    return ShanshuiTimeOfDay.night;
  }

  /// Maps a diary entry weather tag into [ShanshuiWeather], defaulting to [ShanshuiWeather.sunny].
  static ShanshuiWeather resolveWeather(String? rawWeatherTag) {
    if (rawWeatherTag == null || rawWeatherTag.isEmpty) {
      return ShanshuiWeather.sunny;
    }

    switch (rawWeatherTag.trim().toLowerCase()) {
      case 'sunny':
      case 'clear':
        return ShanshuiWeather.sunny;
      case 'cloudy':
      case 'windy':
      case 'overcast':
      case 'foggy':
        return ShanshuiWeather.cloudy;
      case 'rainy':
      case 'rain':
      case 'drizzle':
        return ShanshuiWeather.rainy;
      case 'stormy':
      case 'thunder':
      case 'thunderstorm':
        return ShanshuiWeather.stormy;
      case 'snowy':
      case 'snow':
        return ShanshuiWeather.snowy;
      default:
        return ShanshuiWeather.sunny;
    }
  }

  /// Contextually pairs an active [ShanshuiAtmosphereState] with an offline [SoundscapePreset].
  static SoundscapePreset resolveSoundscape(ShanshuiAtmosphereState atmosphere) {
    if (atmosphere.weather == ShanshuiWeather.rainy ||
        atmosphere.weather == ShanshuiWeather.stormy) {
      return SoundscapePreset.gentleRain;
    }
    if (atmosphere.season == ShanshuiSeason.winter ||
        atmosphere.timeOfDay == ShanshuiTimeOfDay.night) {
      return SoundscapePreset.vintageLibrary;
    }
    return SoundscapePreset.bambooBreeze;
  }
}

