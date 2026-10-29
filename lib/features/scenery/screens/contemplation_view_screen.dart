import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../editor/services/audio_sanctum_service.dart';
import '../models/shanshui_atmosphere.dart';
import '../services/shanshui_atmosphere_resolver.dart';
import '../widgets/shanshui_scenery_painting.dart';

/// Fullscreen 3:2 interactive Zen Contemplation View (沉浸画卷观景台).
/// Provides interactive touch ripples, atmospheric switchers, real-time sync,
/// and paired offline procedural soundscapes from [AudioSanctumService].
class ContemplationViewScreen extends StatefulWidget {
  final ShanshuiAtmosphereState initialAtmosphere;
  final ShanshuiAtmosphereState realTimeAtmosphere;
  final AudioSanctumService audioService;
  final bool? enableAmbientAnimation;

  const ContemplationViewScreen({
    super.key,
    required this.initialAtmosphere,
    required this.realTimeAtmosphere,
    required this.audioService,
    this.enableAmbientAnimation,
  });

  @override
  State<ContemplationViewScreen> createState() => _ContemplationViewScreenState();
}

class _ContemplationViewScreenState extends State<ContemplationViewScreen>
    with WidgetsBindingObserver {
  late ShanshuiAtmosphereState _atmosphere;
  bool _isSoundscapeActive = false;

  bool get _isOutOfSync => !_atmosphere.matchesEnvironment(widget.realTimeAtmosphere);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _atmosphere = widget.initialAtmosphere;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isSoundscapeActive) {
        widget.audioService.stop();
        setState(() => _isSoundscapeActive = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isSoundscapeActive) {
      widget.audioService.stop();
    }
    super.dispose();
  }

  void _syncRealTime() {
    setState(() {
      _atmosphere = widget.realTimeAtmosphere;
    });
    _updateSoundscapeIfActive();
  }

  Future<void> _toggleSoundscape() async {
    if (_isSoundscapeActive) {
      await widget.audioService.stop();
      setState(() => _isSoundscapeActive = false);
    } else {
      final preset = ShanshuiAtmosphereResolver.resolveSoundscape(_atmosphere);
      await widget.audioService.selectPreset(preset);
      setState(() => _isSoundscapeActive = true);
    }
  }

  Future<void> _updateSoundscapeIfActive() async {
    if (_isSoundscapeActive) {
      final preset = ShanshuiAtmosphereResolver.resolveSoundscape(_atmosphere);
      await widget.audioService.selectPreset(preset);
    }
  }

  void _onSelectSeason(ShanshuiSeason season) {
    setState(() {
      _atmosphere = _atmosphere.copyWith(season: season, isManualPreview: true);
    });
    _updateSoundscapeIfActive();
  }

  void _onSelectTimeOfDay(ShanshuiTimeOfDay timeOfDay) {
    setState(() {
      _atmosphere = _atmosphere.copyWith(timeOfDay: timeOfDay, isManualPreview: true);
    });
    _updateSoundscapeIfActive();
  }

  void _onSelectWeather(ShanshuiWeather weather) {
    setState(() {
      _atmosphere = _atmosphere.copyWith(weather: weather, isManualPreview: true);
    });
    _updateSoundscapeIfActive();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<InkDiaryTokens>() ?? InkDiaryTokens.light;

    return Scaffold(
      backgroundColor: const Color(0xFF141210),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back / Close
                  IconButton(
                    key: const Key('contemplation_close_button'),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFFD6D0C4), size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  // Atmospheric Title, Poem & Seal
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tokens.cinnabar,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _atmosphere.season.sealText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_atmosphere.season.nameZh} · ${_atmosphere.weather.badgeZh}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFF7F4EB),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                '「${_atmosphere.season.poem}」',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFC8BFA8),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions: Sync Real-Time & Soundscape
                  Row(
                    children: [
                      if (_isOutOfSync)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            key: const Key('contemplation_sync_realtime_button'),
                            onTap: _syncRealTime,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E2924),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: tokens.cinnabar.withValues(alpha: 0.6)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.history_rounded, size: 14, color: tokens.cinnabar),
                                  const SizedBox(width: 4),
                                  Text(
                                    '恢复实时',
                                    style: TextStyle(
                                      color: tokens.cinnabar,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      IconButton(
                        key: const Key('contemplation_soundscape_button'),
                        icon: Icon(
                          _isSoundscapeActive ? Icons.headphones_rounded : Icons.headphones_outlined,
                          color: _isSoundscapeActive ? tokens.cinnabar : const Color(0xFFD6D0C4),
                          size: 22,
                        ),
                        tooltip: _isSoundscapeActive ? '静音' : '开启白噪音',
                        onPressed: _toggleSoundscape,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main 3:2 Canvas Stage
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    key: const Key('contemplation_lake_canvas'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ShanshuiSceneryPainting(
                      atmosphere: _atmosphere,
                      aspectRatio: 3.0 / 2.0,
                      fullPoem: true,
                      showCalligraphy: true,
                      enableAmbientAnimation: widget.enableAmbientAnimation,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Switcher Controls
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: const Color(0xFF1E1A17),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seasons row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ShanshuiSeason.values.map((season) {
                          final isSelected = _atmosphere.season == season;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              key: Key('contemplation_season_chip_${season.id}'),
                              label: Text(season.shortNameZh),
                              selected: isSelected,
                              onSelected: (_) => _onSelectSeason(season),
                              selectedColor: tokens.cinnabar,
                              backgroundColor: const Color(0xFF292420),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFFC8BFA8),
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Time of Day & Weather row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...ShanshuiTimeOfDay.values.map((timeOfDay) {
                            final isSelected = _atmosphere.timeOfDay == timeOfDay;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                key: Key('contemplation_time_chip_${timeOfDay.id}'),
                                label: Text(timeOfDay.nameZh),
                                selected: isSelected,
                                onSelected: (_) => _onSelectTimeOfDay(timeOfDay),
                                selectedColor: const Color(0xFF4A4036),
                                backgroundColor: const Color(0xFF24201C),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFFA69F91),
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }),
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFF38322C),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          ...ShanshuiWeather.values.map((weather) {
                            final isSelected = _atmosphere.weather == weather;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                key: Key('contemplation_weather_chip_${weather.id}'),
                                label: Text(weather.nameZh),
                                selected: isSelected,
                                onSelected: (_) => _onSelectWeather(weather),
                                selectedColor: const Color(0xFF3A4D59),
                                backgroundColor: const Color(0xFF24201C),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFFA69F91),
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
