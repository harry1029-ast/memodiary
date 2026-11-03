import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'folio_chassis_painter.dart';
import 'folio_corner_curl_widget.dart';
import 'folio_leaf_model.dart';
import 'folio_reading_perspective.dart';
import 'folio_silk_bookmark_painter.dart';
import 'folio_substrate_painter.dart';

/// Responsive 3D stage rendering the Thread-Bound Folio on the scholar's desk.
class Folio3DStage extends StatefulWidget {
  final List<FolioLeaf> leaves;
  final FolioSubstrateTheme theme;
  final int currentPageIndex;
  final ValueChanged<int>? onPageChanged;
  final Widget Function(BuildContext context, FolioLeaf leaf, bool isTurningLeaf) leafBuilder;
  final bool enableAmbientAnimation;

  const Folio3DStage({
    super.key,
    required this.leaves,
    required this.theme,
    this.currentPageIndex = 0,
    this.onPageChanged,
    required this.leafBuilder,
    this.enableAmbientAnimation = true,
  });

  @override
  State<Folio3DStage> createState() => Folio3DStageState();
}

class Folio3DStageState extends State<Folio3DStage>
    with TickerProviderStateMixin {
  late int _currentPageIndex;
  bool _isFlipping = false, _isDraggingCorner = false;
  int _flipDirection = 1, _targetPageIndex = 0, _dragDirection = 1;
  double _dragStartX = 0.0;
  late final AnimationController _flipController;
  AnimationController? _motesController;

  AnimationController get flipController => _flipController;
  bool get isFlipping => _isFlipping;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.currentPageIndex;
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    final isTest = Platform.environment['FLUTTER_TEST'] == 'true';
    if (widget.enableAmbientAnimation && !isTest) {
      _motesController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 10),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Folio3DStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPageIndex != oldWidget.currentPageIndex && !_isFlipping) {
      _currentPageIndex = widget.currentPageIndex;
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _motesController?.dispose();
    super.dispose();
  }

  /// Flips the page forward (+1) or backward (-1).
  Future<void> flipPage(int direction) async {
    if (_isFlipping || widget.leaves.isEmpty) return;
    final nextIndex = _currentPageIndex + direction;
    if (nextIndex < 0 || nextIndex >= widget.leaves.length) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isFlipping = true;
      _flipDirection = direction;
      _targetPageIndex = nextIndex;
    });

    _flipController.value = direction == 1 ? 0.0 : 1.0;
    await _flipController.animateTo(
      direction == 1 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );

    if (!mounted) return;
    setState(() {
      _currentPageIndex = nextIndex;
      _isFlipping = false;
    });
    widget.onPageChanged?.call(_currentPageIndex);
  }

  void _startCornerDrag(DragStartDetails details, int direction) {
    if (_isFlipping && !_isDraggingCorner) return;
    final nextIndex = _currentPageIndex + direction;
    if (nextIndex < 0 || nextIndex >= widget.leaves.length) return;

    setState(() {
      _isDraggingCorner = true;
      _isFlipping = true;
      _dragDirection = direction;
      _flipDirection = direction;
      _targetPageIndex = nextIndex;
      _dragStartX = details.globalPosition.dx;
      _flipController.value = direction == 1 ? 0.04 : 0.96;
    });
  }

  void _updateCornerDrag(DragUpdateDetails details) {
    if (!_isDraggingCorner) return;
    final deltaX = details.globalPosition.dx - _dragStartX;
    _flipController.value = _dragDirection == 1
        ? (-deltaX / 280.0).clamp(0.02, 0.98)
        : (1.0 - (deltaX / 280.0)).clamp(0.02, 0.98);
  }

  Future<void> _endCornerDrag(DragEndDetails details) async {
    if (!_isDraggingCorner) return;
    _isDraggingCorner = false;
    final p = _flipController.value;
    final commit = _dragDirection == 1 ? (p > 0.35) : (p < 0.65);
    await _flipController.animateTo(
      commit ? (_dragDirection == 1 ? 1.0 : 0.0) : (_dragDirection == 1 ? 0.0 : 1.0),
      duration: Duration(milliseconds: commit ? 320 : 300),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    setState(() {
      if (commit) _currentPageIndex = _targetPageIndex;
      _isFlipping = false;
    });
    if (commit) widget.onPageChanged?.call(_currentPageIndex);
  }

  Widget _buildCorner(bool isNext) => Positioned(
    key: ValueKey(isNext ? 'corner_pos_next' : 'corner_pos_prev'),
    right: isNext ? 0 : null,
    left: isNext ? null : 0,
    bottom: 0,
    child: FolioCornerCurlWidget(
      key: Key(isNext ? 'folio_corner_curl_next' : 'folio_corner_curl_prev'),
      isNext: isNext,
      enabled: !_isFlipping || _isDraggingCorner,
      onTap: () => flipPage(isNext ? 1 : -1),
      onHorizontalDragStart: (details) => _startCornerDrag(details, isNext ? 1 : -1),
      onHorizontalDragUpdate: _updateCornerDrag,
      onHorizontalDragEnd: _endCornerDrag,
    ),
  );

  Widget _buildReverseBleedThroughSheet(BuildContext context, FolioLeaf leaf) {
    return Container(
      key: const Key('folio_reverse_bleed_through'),
      decoration: BoxDecoration(
        color: widget.theme.pageBackBg,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(6), right: Radius.circular(2)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(10, 0))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.17,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 1.1, sigmaY: 1.1),
                  child: widget.leafBuilder(context, leaf, true),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: FolioSubstratePainter(
                showGoldFlecks: false, isDark: widget.theme.isDark,
                enableShimmer: false, drawGutterShadow: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0908),
            gradient: RadialGradient(
              center: Alignment(0.0, -0.25),
              radius: 1.15,
              colors: [Color(0xFF2B231D), Color(0xFF171310), Color(0xFF0A0908)],
              stops: [0.0, 0.58, 1.0],
            ),
          ),
          child: Stack(
            children: [
              if (_motesController != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _motesController!,
                      builder: (context, _) => CustomPaint(
                        painter: _DustMotesPainter(_motesController!.value),
                      ),
                    ),
                  ),
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 416,
                      height: 628,
                      child: _buildChassisAndLeaves(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChassisAndLeaves(BuildContext context) {
    if (widget.leaves.isEmpty) return const SizedBox(width: 416, height: 628);

    FolioLeaf baseLeaf = widget.leaves[_currentPageIndex];
    FolioLeaf flippingFrontLeaf = widget.leaves[_currentPageIndex];
    if (_isFlipping) {
      if (_flipDirection == 1) {
        baseLeaf = widget.leaves[_targetPageIndex];
        flippingFrontLeaf = widget.leaves[_currentPageIndex];
      } else {
        baseLeaf = widget.leaves[_currentPageIndex];
        flippingFrontLeaf = widget.leaves[_targetPageIndex];
      }
    }

    return AnimatedBuilder(
      animation: _flipController,
      builder: (context, _) {
        final progress = _flipController.value;
        final angleRad = -progress * math.pi;
        final sinCurve = math.sin(progress * math.pi);
        final swayAngle = _isFlipping
            ? sinCurve * 0.15 * (_flipDirection == 1 ? 1 : -1)
            : 0.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: FolioChassisPainter())),
            Positioned(
              top: -8, right: 48,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(16, 62),
                  painter: FolioSilkBookmarkPainter(swayAngle: swayAngle),
                ),
              ),
            ),
            Positioned(
              left: 42, top: 12, width: 360, height: 596,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    key: const ValueKey('base_leaf'),
                    child: widget.leafBuilder(context, baseLeaf, false),
                  ),
                  const Positioned(
                    key: ValueKey('gutter_shadow'),
                    left: 0, top: 0, bottom: 0, width: 26,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0x52000000), Color(0x1F000000), Colors.transparent],
                            stops: [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isFlipping)
                    Positioned.fill(
                      key: const ValueKey('ambient_shadow'),
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (sinCurve * 0.85).clamp(0.0, 1.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: const [Color(0x7A000000), Color(0x38000000), Colors.transparent],
                                stops: [0.0, (1.0 - progress * 0.75).clamp(0.15, 0.85), 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_isFlipping)
                    Positioned.fill(
                      key: const ValueKey('turning_leaf'),
                      child: IgnorePointer(
                        child: Transform(
                          alignment: Alignment.centerLeft,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.00065)
                            ..rotateY(angleRad),
                          child: progress <= 0.5
                              ? Stack(
                                  children: [
                                    Positioned.fill(
                                      child: widget.leafBuilder(context, flippingFrontLeaf, true),
                                    ),
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity: (sinCurve * 0.95).clamp(0.0, 1.0),
                                        child: const DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0x47000000), Color(0x2EFFFFFF), Color(0x26000000)],
                                              stops: [0.0, 0.42, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..rotateY(math.pi),
                                  child: _buildReverseBleedThroughSheet(context, flippingFrontLeaf),
                                ),
                        ),
                      ),
                    ),
                  if (_currentPageIndex < widget.leaves.length - 1) _buildCorner(true),
                  if (_currentPageIndex > 0) _buildCorner(false),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DustMotesPainter extends CustomPainter {
  final double animationProgress;
  const _DustMotesPainter(this.animationProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42), paint = Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.15);
    for (int moteIndex = 0; moteIndex < 18; moteIndex++) {
      final speed = 0.5 + random.nextDouble() * 0.8;
      final yOffset = (random.nextDouble() * size.height - animationProgress * speed * 60) % size.height;
      final xOffset = random.nextDouble() * size.width + math.sin(animationProgress * math.pi * 2 + moteIndex) * 8.0;
      canvas.drawCircle(Offset(xOffset, yOffset), 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustMotesPainter oldDelegate) =>
      oldDelegate.animationProgress != animationProgress;
}
