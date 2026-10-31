import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/services/ocr/ocr_models.dart';
import '../../../core/theme/ink_diary_theme.dart';

/// Interactive visual overlay that projects OCR text bounding boxes onto
/// a letterboxed image rect and renders pulsing cinnabar highlight frames.
class OcrHighlightOverlay extends StatefulWidget {
  final List<OcrLineBlock> lines;
  final String query;
  final Size originalImageSize;
  final bool isVisible;
  final bool enableAnimation;

  OcrHighlightOverlay({
    super.key,
    required this.lines,
    required this.query,
    required this.originalImageSize,
    required this.isVisible,
    bool? enableAnimation,
  }) : enableAnimation = enableAnimation ??
            (const bool.fromEnvironment('dart.vm.product') ||
                Platform.environment['FLUTTER_TEST'] != 'true');

  /// Computes the centered letterbox/pillarbox destination rect within [containerSize]
  /// using [BoxFit.contain] for an image of [originalImageSize].
  static Rect calculateDestinationRect({
    required Size originalImageSize,
    required Size containerSize,
  }) {
    if (originalImageSize.width <= 0 ||
        originalImageSize.height <= 0 ||
        containerSize.width <= 0 ||
        containerSize.height <= 0) {
      return Rect.zero;
    }
    final fittedSizes = applyBoxFit(BoxFit.contain, originalImageSize, containerSize);
    return Alignment.center.inscribe(fittedSizes.destination, Offset.zero & containerSize);
  }

  /// Projects a normalized 0.0..1.0 bounding box `[left, top, width, height]`
  /// onto the fitted [destinationRect]. Returns [Rect.zero] for degenerate boxes.
  static Rect projectNormalizedBox(List<double> box, Rect destinationRect) {
    if (box.length != 4 || destinationRect.isEmpty) {
      return Rect.zero;
    }
    final bLeft = box[0];
    final bTop = box[1];
    final bWidth = box[2];
    final bHeight = box[3];

    if (!bLeft.isFinite ||
        !bTop.isFinite ||
        !bWidth.isFinite ||
        !bHeight.isFinite ||
        bWidth <= 0 ||
        bHeight <= 0) {
      return Rect.zero;
    }

    return Rect.fromLTWH(
      destinationRect.left + bLeft * destinationRect.width,
      destinationRect.top + bTop * destinationRect.height,
      bWidth * destinationRect.width,
      bHeight * destinationRect.height,
    );
  }

  /// Filters recognized [lines] to those matching [query].
  ///
  /// First checks if line text case-insensitively contains `query.trim()`.
  /// If no lines match, checks if line text contains any whitespace-split token of `query`.
  static List<OcrLineBlock> filterMatchingLines(List<OcrLineBlock> lines, String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty || lines.isEmpty) {
      return const <OcrLineBlock>[];
    }

    // 1. Direct case-insensitive substring match
    final exactMatches = lines
        .where((line) => line.text.toLowerCase().contains(cleanQuery))
        .toList(growable: false);
    if (exactMatches.isNotEmpty) {
      return exactMatches;
    }

    // 2. Fallback to whitespace tokens
    final tokens = cleanQuery
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) {
      return const <OcrLineBlock>[];
    }

    return lines.where((line) {
      final lowerText = line.text.toLowerCase();
      return tokens.any((token) => lowerText.contains(token));
    }).toList(growable: false);
  }

  @override
  State<OcrHighlightOverlay> createState() => _OcrHighlightOverlayState();
}

class _OcrHighlightOverlayState extends State<OcrHighlightOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _updateAnimationState();
  }

  @override
  void didUpdateWidget(OcrHighlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableAnimation != widget.enableAnimation ||
        oldWidget.isVisible != widget.isVisible) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    final isFlutterTest = Platform.environment['FLUTTER_TEST'] == 'true';
    if (widget.enableAnimation && widget.isVisible && !isFlutterTest) {
      if (!_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
    } else {
      if (_animationController.isAnimating) {
        _animationController.stop();
      }
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final matchedLines = OcrHighlightOverlay.filterMatchingLines(
      widget.lines,
      widget.query,
    );

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
          return AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: containerSize,
                painter: _OcrHighlightPainter(
                  lines: matchedLines,
                  originalImageSize: widget.originalImageSize,
                  containerSize: containerSize,
                  tokens: tokens,
                  isVisible: widget.isVisible,
                  pulseFactor: _pulseAnimation.value,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OcrHighlightPainter extends CustomPainter {
  final List<OcrLineBlock> lines;
  final Size originalImageSize;
  final Size containerSize;
  final InkDiaryTokens tokens;
  final bool isVisible;
  final double pulseFactor;

  _OcrHighlightPainter({
    required this.lines,
    required this.originalImageSize,
    required this.containerSize,
    required this.tokens,
    required this.isVisible,
    required this.pulseFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isVisible || lines.isEmpty) {
      return;
    }

    final destRect = OcrHighlightOverlay.calculateDestinationRect(
      originalImageSize: originalImageSize,
      containerSize: size,
    );
    if (destRect.isEmpty) {
      return;
    }

    final fillPaint = Paint()
      ..color = tokens.cinnabar.withValues(alpha: 0.18 * pulseFactor)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = tokens.cinnabar
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      final rect = OcrHighlightOverlay.projectNormalizedBox(line.box, destRect);
      if (rect.isEmpty) {
        continue;
      }

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(_OcrHighlightPainter oldDelegate) {
    return oldDelegate.isVisible != isVisible ||
        oldDelegate.pulseFactor != pulseFactor ||
        oldDelegate.lines != lines ||
        oldDelegate.originalImageSize != originalImageSize ||
        oldDelegate.containerSize != containerSize ||
        oldDelegate.tokens != tokens;
  }
}
