import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/utils/ambient_animation_utils.dart';
import 'window_sill_ornaments_painter.dart';

/// Merged carved wooden Window Sill Ledge (`窗台案沿`) with brass corner brackets (`铜包角`)
/// and four study ornaments (`案沿清供`): pine bonsai & brush stand on the left,
/// interactive brass candlestick & celadon incense burner on the right.
class WindowSillLedge extends StatefulWidget {
  final bool isCandleLit;
  final VoidCallback onToggleCandle;
  final bool? enableAmbientAnimation;
  final bool isVisible;

  const WindowSillLedge({
    super.key,
    required this.isCandleLit,
    required this.onToggleCandle,
    this.enableAmbientAnimation,
    this.isVisible = true,
  });

  @override
  State<WindowSillLedge> createState() => _WindowSillLedgeState();
}

class _WindowSillLedgeState extends State<WindowSillLedge>
    with TickerProviderStateMixin {
  late final AnimationController _candleController;
  late final AnimationController _incenseController;

  bool get _effectiveAnimate =>
      shouldRunAmbientAnimation(widget.enableAmbientAnimation);

  @override
  void initState() {
    super.initState();
    _candleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _incenseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _syncAnimations();
  }

  @override
  void didUpdateWidget(WindowSillLedge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCandleLit != widget.isCandleLit ||
        oldWidget.isVisible != widget.isVisible ||
        oldWidget.enableAmbientAnimation != widget.enableAmbientAnimation) {
      _syncAnimations();
    }
  }

  void _syncAnimations() {
    final canAnimate = _effectiveAnimate && widget.isVisible;
    if (canAnimate && widget.isCandleLit) {
      if (!_candleController.isAnimating) {
        _candleController.repeat();
      }
    } else {
      _candleController.stop();
    }

    if (canAnimate) {
      if (!_incenseController.isAnimating) {
        _incenseController.repeat();
      }
    } else {
      _incenseController.stop();
    }
  }

  @override
  void dispose() {
    _candleController.dispose();
    _incenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;

    return SizedBox(
      key: const Key('timeline_window_sill_ledge'),
      height: 44.0,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Carved wooden sill shelf + front brass-bracketed lip (~38dp visual sill)
          Positioned(
            left: 0,
            right: 0,
            top: 6.0,
            bottom: 0,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [palette.sillTop, palette.sillBottom],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: palette.woodFrameHighlight,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                // Carved Front Lip with Brass Corner Brackets (铜包角)
                Container(
                  height: 11.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [palette.lipTop, palette.lipBottom],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: palette.accentSecondary.withValues(alpha: 0.42),
                        width: 0.8,
                      ),
                      bottom: BorderSide(
                        color: Colors.black.withValues(alpha: 0.85),
                        width: 1.0,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: BrassCornerBracketsPainter(
                      brassColor: palette.accentSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Left study ornaments: Pine Bonsai + Brush Stand (enlarged ~1.45x, extending slightly onto sill frame)
          Positioned(
            left: 14,
            bottom: 9,
            child: IgnorePointer(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  SizedBox(
                    width: 50,
                    height: 46,
                    child: CustomPaint(painter: PineBonsaiPainter()),
                  ),
                  SizedBox(width: 6),
                  SizedBox(
                    width: 41,
                    height: 44,
                    child: CustomPaint(painter: BrushStandPainter()),
                  ),
                ],
              ),
            ),
          ),

          // Right study ornaments: Interactive Brass Candlestick (>=44x44) + Celadon Incense Burner
          Positioned(
            right: 12,
            bottom: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Semantics(
                  button: true,
                  toggled: widget.isCandleLit,
                  label: widget.isCandleLit ? '熄灭红烛' : '点亮红烛',
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      key: const Key('timeline_candlestick_button'),
                      onTap: widget.onToggleCandle,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 48,
                        height: 44,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            Positioned(
                              bottom: 9,
                              child: AnimatedBuilder(
                                animation: _candleController,
                                builder: (context, _) {
                                  return CustomPaint(
                                    size: const Size(32, 50),
                                    painter: BrassCandlestickPainter(
                                      isLit: widget.isCandleLit,
                                      flickerPhase: _candleController.value,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: AnimatedBuilder(
                      animation: _incenseController,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(40, 40),
                          painter: CeladonIncensePainter(
                            smokePhase: _incenseController.value,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
