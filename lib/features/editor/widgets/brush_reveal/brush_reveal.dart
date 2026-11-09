import 'package:flutter/material.dart';

import 'brush_reveal_choreography.dart';
import 'brush_reveal_painter.dart';
import 'silk_cover_picture.dart';

/// Where a slot is in its one-time Brush Reveal.
enum BrushRevealStatus {
  /// Revealed long ago, or never collected in this session: shown as is.
  settled,

  /// Collected, waiting under its silk-paper cover for its turn.
  waiting,

  /// Being painted now.
  revealing,
}

/// Blends [child] toward luminance greyscale: 0 = identity, 1 = full ink wash.
ColorFilter inkWashFilter(double amount) {
  final keep = 1.0 - amount;
  const red = 0.2126, green = 0.7152, blue = 0.0722;
  return ColorFilter.matrix(<double>[
    keep + amount * red, amount * green, amount * blue, 0, 0,
    amount * red, keep + amount * green, amount * blue, 0, 0,
    amount * red, amount * green, keep + amount * blue, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

/// Plays the Brush Reveal (泼墨显影) over a keepsake print: the brush paints
/// five splash-ink sweeps through an opaque silk-paper cover, the print shows
/// in monochrome ink wash, then blooms into full colour; a video's [seal] is
/// then stamped. Runs once when [status] becomes [BrushRevealStatus.revealing]
/// and reports [onComplete]; if removed mid-reveal it stops and reports
/// [onComplete] after the frame so the queue moves on.
class BrushReveal extends StatefulWidget {
  /// Distinguishes this reveal's keys (the attachment id).
  final String revealId;
  final BrushRevealStatus status;
  final bool isVideo;
  final VoidCallback? onComplete;
  final Widget child;

  /// Cinnabar seal play stamp for a video, placed at the print's lower right.
  final Widget? seal;

  const BrushReveal({
    super.key,
    required this.revealId,
    required this.status,
    required this.isVideo,
    required this.child,
    this.onComplete,
    this.seal,
  });

  @override
  State<BrushReveal> createState() => _BrushRevealState();
}

class _BrushRevealState extends State<BrushReveal> with SingleTickerProviderStateMixin {
  late final BrushRevealTimeline _timeline = BrushRevealTimeline(isVideo: widget.isVideo);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _timeline.total,
  )..addStatusListener(_onStatus);

  /// Keeps the print's state (its loaded image) when the ink-wash filter is
  /// added or removed around it.
  final GlobalKey _printKey = GlobalKey();

  SilkCoverPicture? _cover;
  List<BrushSweep> _sweeps = const [];

  @override
  void initState() {
    super.initState();
    if (widget.status == BrushRevealStatus.revealing) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant BrushReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == BrushRevealStatus.revealing && oldWidget.status != BrushRevealStatus.revealing) {
      _controller.forward(from: 0.0);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onComplete?.call();
  }

  @override
  void dispose() {
    if (_controller.isAnimating) {
      final onAbandoned = widget.onComplete;
      WidgetsBinding.instance.addPostFrameCallback((_) => onAbandoned?.call());
    }
    _controller.dispose();
    _cover?.dispose();
    super.dispose();
  }

  BrushRevealFrame? get _frame => switch (widget.status) {
        BrushRevealStatus.settled => null,
        BrushRevealStatus.waiting => _timeline.frameAt(Duration.zero),
        BrushRevealStatus.revealing => _timeline.frameAt(_timeline.total * _controller.value),
      };

  SilkCoverPicture _coverFor(Size size) {
    if (_cover?.size != size) {
      _cover?.dispose();
      _cover = SilkCoverPicture.record(size);
      _sweeps = BrushRevealSweeps.forSize(size);
    }
    return _cover!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (animatedContext, print) {
        final frame = _frame;
        final colour = frame?.colour ?? 1.0;
        final sealProgress = frame?.sealProgress ?? 1.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (colour < 1.0)
              ColorFiltered(
                key: Key('brush_reveal_ink_wash_${widget.revealId}'),
                colorFilter: inkWashFilter(1.0 - colour),
                child: print,
              )
            else
              print!,
            if (frame != null && frame.coverOpacity > 0.0)
              LayoutBuilder(
                builder: (layoutContext, constraints) {
                  final cover = _coverFor(constraints.biggest);
                  return CustomPaint(
                    key: Key('brush_reveal_cover_${widget.revealId}'),
                    size: constraints.biggest,
                    painter: BrushRevealPainter(frame: frame, sweeps: _sweeps, cover: cover),
                  );
                },
              ),
            if (widget.seal != null && sealProgress > 0.0)
              Positioned(
                right: 4.0,
                bottom: 4.0,
                child: Opacity(
                  opacity: sealProgress,
                  // The stamp presses down from slightly above the paper.
                  child: Transform.scale(scale: 1.6 - 0.6 * Curves.easeOutBack.transform(sealProgress), child: widget.seal),
                ),
              ),
          ],
        );
      },
      child: KeyedSubtree(key: _printKey, child: widget.child),
    );
  }
}
