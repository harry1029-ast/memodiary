import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../albums/data/album_repository.dart';
import '../../albums/screens/album_collections_screen.dart';
import '../../timeline/screens/timeline_screen.dart';
import '../models/book_intro_folio_data.dart';
import '../utils/chinese_calendar_helper.dart';
import '../widgets/book_3d_stage.dart';
import '../widgets/bottom_seal_slider.dart';
import '../widgets/living_ink_background_painter.dart';

/// The interactive 3D Book Intro opening gateway for MemoDiary.
/// Incorporates the physical thread-bound Chinese book, living water-ink landscape,
/// and dual interactive portals («私人日记» & «旅行画册»).
class BookIntroScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final AlbumRepository? albumRepository;
  final bool startOpened;

  const BookIntroScreen({
    super.key,
    required this.database,
    required this.mediaService,
    this.albumRepository,
    this.startOpened = false,
  });

  @override
  State<BookIntroScreen> createState() => _BookIntroScreenState();
}

class _BookIntroScreenState extends State<BookIntroScreen>
    with TickerProviderStateMixin {
  // Continuous ticker driving atmospheric background ink animations
  late final AnimationController _ambientLoopController;

  // Controller driving the 3D book leaf opening momentum
  late final AnimationController _bookFlipController;

  // Decoupled repository for travel album metadata
  late final AlbumRepository _albumRepository;

  double _swipeProgress = 0.0; // 0.0 (Closed) -> 1.0 (Open)
  int _lastHapticMilestone = 0;
  double _dragStartX = 0.0;
  double _dragStartProgress = 0.0;

  // Dynamic context for right folio cards
  BookIntroFolioData _folioData = const BookIntroFolioData();

  @override
  void initState() {
    super.initState();

    _albumRepository = widget.albumRepository ??
        AlbumRepository(
          database: widget.database,
          mediaService: widget.mediaService,
        );

    _folioData = _folioData.copyWith(
      lunarDateText: ChineseCalendarHelper.formatMonthDay(DateTime.now()),
    );

    // 1. Continuous atmospheric animation loop (60s cycle)
    _ambientLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    // 2. 3D Book opening momentum controller with direct listener
    _bookFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: widget.startOpened ? 1.0 : 0.0,
    )..addListener(() {
        setState(() {
          _swipeProgress = _bookFlipController.value;
        });
      });

    _swipeProgress = widget.startOpened ? 1.0 : 0.0;

    // 3. Load live travel album context via repository
    _loadLatestTravelAlbum();
  }

  Future<void> _loadLatestTravelAlbum() async {
    try {
      final latest = await _albumRepository.getLatestCollection();

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
    super.dispose();
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

    // Subtle drag milestone haptics
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
    // Swiping left (decreasing dx) increases opening progress
    final totalDelta = _dragStartX - details.globalPosition.dx;
    // 130px swipe distance for effortless light drag
    final next = (_dragStartProgress + totalDelta / 130.0).clamp(0.0, 1.0);
    _onSliderProgressChanged(next);
  }

  void _onBookDragEnd(DragEndDetails details) {
    final vel = details.primaryVelocity ?? 0.0;
    // Light flick (80px/s) to the left commits to opening; to the right commits to closing
    if (vel < -80.0) {
      _animateBookTo(1.0);
    } else if (vel > 80.0) {
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

  void _navigateToPersonalDiary() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimelineScreen(
          database: widget.database,
          mediaService: widget.mediaService,
        ),
      ),
    );
  }

  void _navigateToTravelAlbum() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumCollectionsScreen(
          database: widget.database,
          mediaService: widget.mediaService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E9),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. LIVING INK WASH BACKGROUND CANVAS
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ambientLoopController,
                builder: (context, _) {
                  final elapsedSeconds = _ambientLoopController.value * 60.0;
                  return CustomPaint(
                    painter: LivingInkBackgroundPainter(
                      coverOpenRatio: _swipeProgress,
                      animationTime: elapsedSeconds,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),

            // 2. FOREGROUND INTERACTION LAYER
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Main Title: 拾光 · 云笺日记
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '拾光 · 云笺日记',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4.5,
                          color: Color(0xFF1C1A17),
                          fontFamily: 'Noto Serif SC',
                          shadows: [
                            Shadow(
                              color: Color(0xD9FFFFFF),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3D Animated Book Stage with direct effortless swiping and tap-to-flip
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_swipeProgress < 0.35) {
                            _animateBookTo(1.0);
                          }
                        },
                        onHorizontalDragStart: _onBookDragStart,
                        onHorizontalDragUpdate: _onBookDragUpdate,
                        onHorizontalDragEnd: _onBookDragEnd,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Book3DStage(
                            coverOpenRatio: _swipeProgress,
                            folioData: _folioData,
                            onPersonalDiaryTap: _navigateToPersonalDiary,
                            onTravelAlbumTap: _navigateToTravelAlbum,
                            onBookTap: () {
                              if (_swipeProgress < 0.35) {
                                _animateBookTo(1.0);
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                    // Bottom Seal Slider Bar
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: BottomSealSlider(
                        progress: _swipeProgress,
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
          ],
        ),
      ),
    );
  }
}
