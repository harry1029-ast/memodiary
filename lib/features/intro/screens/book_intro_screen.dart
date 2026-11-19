import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/calendar/lunar_calendar.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/services/ocr/ocr_queue_manager.dart';
import '../../../core/utils/ambient_animation_utils.dart';
import '../../albums/screens/album_collections_screen.dart';
import '../../timeline/screens/timeline_screen.dart';
import '../models/book_intro_folio_data.dart';
import '../models/intro_sky_atmosphere.dart';
import '../widgets/book_3d_stage.dart';
import '../widgets/bottom_seal_slider.dart';
import '../widgets/living_ink_background_painter.dart';

/// The interactive 3D Book Intro opening gateway for 云皓日记.
/// Renders a continuous 24-hour Shanshui sky synced to local time with a 1-tap
/// Sun/Moon toggle («映月切换»), a thread-bound 3D book cover, and dual portals («私人日记» & «旅行相册»).
class BookIntroScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final bool startOpened;
  final OcrQueueManager? ocrQueueManager;

  /// Supplies current local date and time for the lunar card and 24-hour sky (defaults to now).
  final DateTime Function()? clock;

  /// Controls whether the continuous ambient background loop ticks (disabled under `flutter test` by default).
  final bool? enableAmbientAnimation;

  const BookIntroScreen({
    super.key,
    required this.database,
    required this.mediaService,
    this.startOpened = false,
    this.ocrQueueManager,
    this.clock,
    this.enableAmbientAnimation,
  });

  @override
  State<BookIntroScreen> createState() => _BookIntroScreenState();
}

class _BookIntroScreenState extends State<BookIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambientLoopController;
  late final AnimationController _bookFlipController;
  late final AnimationController _timeTransitionController;

  double _swipeProgress = 0.0; // 0.0 (Closed) -> 1.0 (Open)
  int _lastHapticMilestone = 0;
  double _dragStartX = 0.0;
  double _dragStartProgress = 0.0;

  late double _timeHours;
  double _transitionStartHour = 21.4;
  double _transitionDiffHour = 0.0;

  BookIntroFolioData _folioData = const BookIntroFolioData();

  @override
  void initState() {
    super.initState();

    final now = (widget.clock ?? DateTime.now)();
    _timeHours = now.hour + now.minute / 60.0;

    final todayLunar = LunarCalendar.fromSolar(now);
    _folioData = _folioData.copyWith(
      lunarDateText: todayLunar.monthDayName ?? todayLunar.yearName,
    );

    final shouldAnimate =
        shouldRunAmbientAnimation(widget.enableAmbientAnimation);
    _ambientLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    if (shouldAnimate) {
      _ambientLoopController.repeat();
    }

    _bookFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: widget.startOpened ? 1.0 : 0.0,
    )..addListener(() {
        setState(() {
          _swipeProgress = _bookFlipController.value;
        });
      });

    _timeTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        final curvedT = Curves.easeInOutCubic.transform(
          _timeTransitionController.value,
        );
        setState(() {
          _timeHours = (_transitionStartHour + _transitionDiffHour * curvedT) % 24.0;
        });
      });

    _swipeProgress = widget.startOpened ? 1.0 : 0.0;
    _loadLatestTravelAlbum();
  }

  Future<void> _loadLatestTravelAlbum() async {
    try {
      final latest = await widget.database.albumsDao.getLatestCollection();

      if (mounted && latest != null) {
        setState(() {
          _folioData = _folioData.copyWith(
            travelTripTitle:
                latest.title.isNotEmpty ? latest.title : null,
            travelRouteSummary:
                (latest.routeSummary != null && latest.routeSummary!.isNotEmpty)
                    ? latest.routeSummary
                    : null,
            travelDestinationTag:
                (latest.destinationTag != null && latest.destinationTag!.isNotEmpty)
                    ? latest.destinationTag
                    : null,
          );
        });
      }
    } catch (_) {
      // Gracefully retain curated defaults
    }
  }

  @override
  void dispose() {
    _ambientLoopController.dispose();
    _bookFlipController.dispose();
    _timeTransitionController.dispose();
    super.dispose();
  }

  void _toggleDayNightSky() {
    HapticFeedback.selectionClick();
    final isCurrentlyNight = _timeHours >= 18.0 || _timeHours < 6.0;
    final targetHour = isCurrentlyNight ? 11.5 : 21.4;
    _transitionStartHour = _timeHours;
    double diff = targetHour - _transitionStartHour;
    if (diff < 0) {
      diff += 24.0;
    }
    _transitionDiffHour = diff;
    _timeTransitionController.forward(from: 0.0);
  }

  void _openBookIfClosed() {
    if (_swipeProgress < 0.35) {
      _animateBookTo(1.0);
    }
  }

  void _animateBookTo(double targetValue) {
    final startValue = _bookFlipController.value;
    final diff = (targetValue - startValue).abs();
    final durationMs = (400 + diff * 500).round();

    _bookFlipController
        .animateTo(
          targetValue,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.easeInOutCubic,
        )
        .then((_) {
      HapticFeedback.mediumImpact();
    });
  }

  void _onSliderProgressChanged(double newProgress) {
    _bookFlipController.value = newProgress;

    final currentMilestone = (newProgress * 4).floor();
    if (currentMilestone != _lastHapticMilestone) {
      _lastHapticMilestone = currentMilestone;
      HapticFeedback.selectionClick();
    }
  }

  void _toggleBookOpen() {
    if (_swipeProgress >= 0.5) {
      _animateBookTo(0.0);
    } else {
      _animateBookTo(1.0);
    }
  }

  void _onBookDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragStartProgress = _swipeProgress;
  }

  void _onBookDragUpdate(DragUpdateDetails details) {
    final totalDelta = _dragStartX - details.globalPosition.dx;
    final next = (_dragStartProgress + totalDelta / 130.0).clamp(0.0, 1.0);
    _onSliderProgressChanged(next);
  }

  void _onBookDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity < -80.0) {
      _animateBookTo(1.0);
    } else if (velocity > 80.0) {
      _animateBookTo(0.0);
    } else if (_dragStartProgress < 0.5 && _swipeProgress >= 0.12) {
      _animateBookTo(1.0);
    } else if (_dragStartProgress >= 0.5 && _swipeProgress <= 0.88) {
      _animateBookTo(0.0);
    } else if (_swipeProgress >= 0.5) {
      _animateBookTo(1.0);
    } else {
      _animateBookTo(0.0);
    }
  }

  void _syncTimeToClock() {
    _timeTransitionController.stop();
    final now = (widget.clock ?? DateTime.now)();
    final todayLunar = LunarCalendar.fromSolar(now);
    setState(() {
      _timeHours = now.hour + now.minute / 60.0;
      _folioData = _folioData.copyWith(
        lunarDateText: todayLunar.monthDayName ?? todayLunar.yearName,
      );
    });
  }

  Future<void> _pushAndResetSkyOnReturn(Widget destination) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => destination),
    );
    if (!mounted) return;
    _syncTimeToClock();
  }

  void _navigateToPersonalDiary() {
    _pushAndResetSkyOnReturn(
      TimelineScreen(
        database: widget.database,
        mediaService: widget.mediaService,
        ocrQueueManager: widget.ocrQueueManager,
      ),
    );
  }

  void _navigateToTravelAlbum() {
    _pushAndResetSkyOnReturn(
      AlbumCollectionsScreen(
        database: widget.database,
        mediaService: widget.mediaService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sky = InterpolatedIntroSky.fromHour(_timeHours);

    return Scaffold(
      backgroundColor: sky.nearMountain,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final celestial = CelestialOrbPosition.fromHour(
            _timeHours,
            Size(constraints.maxWidth, constraints.maxHeight),
          );

          return Stack(
            children: [
              // 1. DYNAMIC 24-HOUR SHANSHUI BACKGROUND CANVAS
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ambientLoopController,
                  builder: (context, _) {
                    final elapsedSeconds = _ambientLoopController.value * 60.0;
                    return CustomPaint(
                      painter: LivingInkBackgroundPainter(
                        coverOpenRatio: _swipeProgress,
                        animationTime: elapsedSeconds,
                        timeHours: _timeHours,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),

              // 2. FOREGROUND INTERACTION LAYER
              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Main Title & Slogan: 云皓日记
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '云皓日记',
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4.5,
                                  color: sky.isNight
                                      ? const Color(0xFFF4F6FA)
                                      : const Color(0xFF1A2433),
                                  fontFamily: 'Noto Serif SC',
                                  fontFamilyFallback: const [
                                    'Songti SC',
                                    'SimSun',
                                    'Georgia',
                                    'serif',
                                  ],
                                  shadows: [
                                    Shadow(
                                      color: sky.isNight
                                          ? const Color(0xBF0A101C)
                                          : const Color(0xA6FFFFFF),
                                      blurRadius: sky.isNight ? 14 : 8,
                                      offset: Offset(0, sky.isNight ? 2 : 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '云伴皓光，收录旅途与心事',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.65,
                                  color: sky.isNight
                                      ? const Color(0xFFC5D4EC)
                                      : const Color(0xFF3E526A),
                                  fontFamily: 'Ma Shan Zheng',
                                  fontFamilyFallback: const [
                                    'Kaiti SC',
                                    'STKaiti',
                                    'serif',
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 3D Animated Book Stage with direct effortless swiping and tap-to-flip
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _openBookIfClosed,
                            onHorizontalDragStart: _onBookDragStart,
                            onHorizontalDragUpdate: _onBookDragUpdate,
                            onHorizontalDragEnd: _onBookDragEnd,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Book3DStage(
                                coverOpenRatio: _swipeProgress,
                                folioData: _folioData,
                                isNight: sky.isNight,
                                lightAngleDeg: celestial.lightAngleDeg,
                                onPersonalDiaryTap: _navigateToPersonalDiary,
                                onTravelAlbumTap: _navigateToTravelAlbum,
                                onBookTap: _openBookIfClosed,
                              ),
                            ),
                          ),
                        ),

                        // Bottom Seal Slider Bar
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: BottomSealSlider(
                            progress: _swipeProgress,
                            isNight: sky.isNight,
                            onProgressChanged: (val) {
                              if (val == 0.0 || val == 1.0) {
                                _animateBookTo(val);
                              } else {
                                _onSliderProgressChanged(val);
                              }
                            },
                            onToggle: _toggleBookOpen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. INTERACTIVE CELESTIAL SUN / MOON TOGGLE (映月切换)
              Positioned(
                left: celestial.x - 40,
                top: celestial.y - 40,
                width: 80,
                height: 80,
                child: Semantics(
                  button: true,
                  label: '映月切换',
                  child: GestureDetector(
                    key: const Key('intro_celestial_toggle_button'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleDayNightSky,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
