import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';

/// Top horizontal groove artifact representing the twin calligraphy brushes (双管毛笔).
/// Animates a gentle brush lift on tap and displays a poetic placeholder in the drawer sub-panel.
class ArtifactTwinBrushes extends StatefulWidget {
  final bool isSelected;
  final VoidCallback? onTap;

  const ArtifactTwinBrushes({
    super.key,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<ArtifactTwinBrushes> createState() => _ArtifactTwinBrushesState();
}

class _ArtifactTwinBrushesState extends State<ArtifactTwinBrushes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _liftAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _liftAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    if (widget.isSelected) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant ArtifactTwinBrushes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '双管毛笔: 笔锋运墨动效 (敬请期待)',
      selected: widget.isSelected,
      child: GestureDetector(
        key: const Key('chest_artifact_twin_brushes'),
        onTap: () {
          widget.onTap?.call();
        },
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6B1A1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isSelected
                      ? const Color(0xFFD4AF37)
                      : const Color(0xFF8B262A),
                  width: widget.isSelected ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: widget.isSelected ? 0.35 : 0.2,
                    ),
                    blurRadius: widget.isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: TwinBambooBrushesPainter(
                        hoverProgress: _liftAnimation.value,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    bottom: 8,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1A17),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: widget.isSelected
                                ? const Color(0xFFD4AF37)
                                : const Color(0xFF8C7148),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '双管笔槽',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontKaiti,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE6C875),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Renders the authentic Twin Bamboo Calligraphy Brushes inside the velvet groove.
class TwinBambooBrushesPainter extends CustomPainter {
  final double hoverProgress;

  TwinBambooBrushesPainter({required this.hoverProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final canvasWidth = size.width;
    final canvasHeight = size.height;

    // Upper Wolf-Hair Brush (紫毫 · 狼毫濃墨)
    canvas.save();
    canvas.translate(0, -3.5 * hoverProgress);
    canvas.rotate(-0.015 * hoverProgress);

    final shaftPaint1 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD7B377), Color(0xFFA67B3E), Color(0xFF6B4C23)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
        Rect.fromLTWH(
          canvasWidth * 0.08,
          canvasHeight * 0.20,
          canvasWidth * 0.54,
          8,
        ),
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          canvasWidth * 0.08,
          canvasHeight * 0.20,
          canvasWidth * 0.54,
          7.5,
        ),
        const Radius.circular(3),
      ),
      shaftPaint1,
    );

    // Dark horn end-cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          canvasWidth * 0.05,
          canvasHeight * 0.20,
          canvasWidth * 0.03,
          7.5,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF1F1B18),
    );

    // Dark horn ferrule
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          canvasWidth * 0.62,
          canvasHeight * 0.19,
          canvasWidth * 0.06,
          8.5,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF1F1B18),
    );

    // Spotted bamboo markings (湘妃斑竹)
    final bambooSpotPaint = Paint()..color = const Color(0x6652361B);
    canvas.drawCircle(Offset(canvasWidth * 0.20, canvasHeight * 0.24), 1.2, bambooSpotPaint);
    canvas.drawCircle(Offset(canvasWidth * 0.34, canvasHeight * 0.23), 1.4, bambooSpotPaint);
    canvas.drawCircle(Offset(canvasWidth * 0.48, canvasHeight * 0.25), 1.2, bambooSpotPaint);

    // Purple wolf-hair brush tip (紫毫 · 狼毫濃墨)
    final tipPath1 = Path()
      ..moveTo(canvasWidth * 0.68, canvasHeight * 0.20)
      ..quadraticBezierTo(
        canvasWidth * 0.74,
        canvasHeight * 0.21,
        canvasWidth * 0.79,
        canvasHeight * 0.24,
      )
      ..quadraticBezierTo(
        canvasWidth * 0.74,
        canvasHeight * 0.27,
        canvasWidth * 0.68,
        canvasHeight * 0.28,
      )
      ..close();
    canvas.drawPath(tipPath1, Paint()..color = const Color(0xFF422129));
    canvas.restore();

    // Lower Goat-Hair Brush (秋山 · 兼毫行書)
    canvas.save();
    canvas.translate(0, -5.5 * hoverProgress);
    canvas.rotate(-0.028 * hoverProgress);

    final shaftPaint2 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE4C58C), Color(0xFFB5894A), Color(0xFF785628)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
        Rect.fromLTWH(
          canvasWidth * 0.06,
          canvasHeight * 0.54,
          canvasWidth * 0.56,
          8.5,
        ),
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          canvasWidth * 0.06,
          canvasHeight * 0.54,
          canvasWidth * 0.56,
          8.5,
        ),
        const Radius.circular(3),
      ),
      shaftPaint2,
    );

    // Spotted bamboo markings on lower shaft
    canvas.drawCircle(Offset(canvasWidth * 0.18, canvasHeight * 0.58), 1.3, bambooSpotPaint);
    canvas.drawCircle(Offset(canvasWidth * 0.32, canvasHeight * 0.57), 1.5, bambooSpotPaint);
    canvas.drawCircle(Offset(canvasWidth * 0.46, canvasHeight * 0.59), 1.2, bambooSpotPaint);

    // Dark horn end-cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          canvasWidth * 0.03,
          canvasHeight * 0.54,
          canvasWidth * 0.03,
          8.5,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF1C1815),
    );

    // Dark horn ferrule
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          canvasWidth * 0.62,
          canvasHeight * 0.53,
          canvasWidth * 0.07,
          9.5,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF1F1B18),
    );

    // White goat-hair brush tip
    final tipPath2 = Path()
      ..moveTo(canvasWidth * 0.69, canvasHeight * 0.54)
      ..quadraticBezierTo(
        canvasWidth * 0.75,
        canvasHeight * 0.55,
        canvasWidth * 0.81,
        canvasHeight * 0.58,
      )
      ..quadraticBezierTo(
        canvasWidth * 0.75,
        canvasHeight * 0.62,
        canvasWidth * 0.69,
        canvasHeight * 0.63,
      )
      ..close();
    canvas.drawPath(tipPath2, Paint()..color = const Color(0xFFF3EFEA));
    canvas.restore();

    // Dual Gold Bridge Clasps
    final claspPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE5C478), Color(0xFF9E772F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
        Rect.fromLTWH(0, canvasHeight * 0.14, canvasWidth, canvasHeight * 0.65),
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          canvasWidth * 0.18,
          canvasHeight * 0.14,
          5.0,
          canvasHeight * 0.64,
        ),
        const Radius.circular(2.5),
      ),
      claspPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          canvasWidth * 0.54,
          canvasHeight * 0.12,
          5.5,
          canvasHeight * 0.66,
        ),
        const Radius.circular(2.5),
      ),
      claspPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TwinBambooBrushesPainter oldDelegate) =>
      oldDelegate.hoverProgress != hoverProgress;
}

/// In-chest contextual sub-panel for the Twin Bamboo Brushes artifact
class TwinBrushesSubPanel extends StatelessWidget {
  final VoidCallback? onClose;

  const TwinBrushesSubPanel({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('chest_subpanel_twin_brushes'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              const Icon(Icons.brush_outlined, size: 24, color: Color(0xFFFFDF85)),
              if (onClose != null)
                GestureDetector(
                  key: const Key('chest_subpanel_close_button'),
                  onTap: onClose,
                  child: Semantics(
                    button: true,
                    label: '收拢面板',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.transparent,
                      child: const Icon(Icons.close, size: 16, color: Color(0xFFD4C5B0)),
                    ),
                  ),
                )
              else
                const SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '笔锋运墨动效 · 敬请期待',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF3D99B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '双管并提，疾涩相参，运笔入微之境将随墨潮而至。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFFD4C5B0),
            ),
          ),
        ],
      ),
    );
  }
}

