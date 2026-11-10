import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/media_sandbox_service.dart';
import '../../domain/stationery_sheet_descriptor.dart';
import '../desk_media_control.dart';
import 'tucked_print.dart';

/// The resting fan of Tucked Prints (夹页影札): up to three of a Stationery
/// Sheet's mounted items, in mount order, slipped behind its top right edge so
/// only their tops peek out into the desk's header band. Mounting never takes
/// a row of the sheet. A sheet holding more (tolerated legacy overflow) shows
/// a "+N" mark. Renders nothing when the sheet has no mounted items.
///
/// The whole fan is one [kTargetHeight]-tall target reaching from the band's
/// top just onto the sheet's Heaven margin. A newly mounted print slides down
/// into the sheet edge; each tick of [refusalSignal] shakes the fan to say the
/// sheet is full. Key it by sheet so a page turn shows the next sheet's prints
/// at rest rather than sliding in.
class TuckedPrintsFan extends StatefulWidget {
  final List<SheetMediaItem> items;
  final MediaSandboxService mediaSandboxService;
  final bool isPaperDark;

  /// Distance from the fan's top to the sheet's top edge, which hides the
  /// prints' lower parts.
  final double sheetEdgeOffset;
  final VoidCallback? onTap;
  final ValueListenable<int>? refusalSignal;

  static const int kVisibleCount = TextStationerySheet.kMountCapacity;
  static const double kTargetHeight = 44.0;

  /// How much of each print shows above the sheet's edge.
  static const double kPeek = 22.0;

  /// Horizontal step between overlapping prints.
  static const double kStride = 26.0;
  static const double kOverflowMarkWidth = 24.0;

  /// Tilts after the prototype's `-1.8deg / 1.4deg / -1.2deg`.
  static const List<double> kTiltsInDegrees = [-1.8, 1.4, -1.2];

  /// After the prototype's `mountSnapIn`: 0.36s, cubic-bezier(0.22, 1, 0.36, 1).
  static const Duration kSnapInDuration = Duration(milliseconds: 360);
  static const Curve kSnapInCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  /// After the prototype's `rejectShake`: 0.38s, ±6px.
  static const Duration kShakeDuration = Duration(milliseconds: 380);
  static const double kShakeAmplitude = 6.0;

  const TuckedPrintsFan({
    super.key,
    required this.items,
    required this.mediaSandboxService,
    required this.sheetEdgeOffset,
    this.isPaperDark = false,
    this.onTap,
    this.refusalSignal,
  });

  /// Width of the fan's target for [itemCount] mounted items.
  static double widthFor(int itemCount) {
    final visible = math.min(itemCount, kVisibleCount);
    if (visible == 0) return 0.0;
    final overflow = itemCount > kVisibleCount ? kOverflowMarkWidth : 0.0;
    return math.max(kTargetHeight, overflow + TuckedPrint.kWidth + (visible - 1) * kStride + 4.0);
  }

  @override
  State<TuckedPrintsFan> createState() => _TuckedPrintsFanState();
}

class _TuckedPrintsFanState extends State<TuckedPrintsFan> with TickerProviderStateMixin {
  late final AnimationController _snapIn = AnimationController(vsync: this, duration: TuckedPrintsFan.kSnapInDuration);
  late final AnimationController _shake = AnimationController(vsync: this, duration: TuckedPrintsFan.kShakeDuration);
  Set<String> _snappingIds = const {};

  static final Animatable<double> _shakeOffset = TweenSequence<double>([
    for (final (from, to) in const [(0.0, -1.0), (-1.0, 1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 0.0)])
      TweenSequenceItem(
        tween: Tween<double>(begin: from, end: to).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1.0,
      ),
  ]);

  List<SheetMediaItem> get _visibleItems => widget.items.take(TuckedPrintsFan.kVisibleCount).toList();

  @override
  void initState() {
    super.initState();
    widget.refusalSignal?.addListener(_onRefused);
  }

  @override
  void didUpdateWidget(TuckedPrintsFan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refusalSignal != widget.refusalSignal) {
      oldWidget.refusalSignal?.removeListener(_onRefused);
      widget.refusalSignal?.addListener(_onRefused);
    }
    final previousIds = oldWidget.items.map((item) => item.id).toSet();
    final arrivals = {
      for (final item in _visibleItems)
        if (!previousIds.contains(item.id)) item.id,
    };
    if (arrivals.isNotEmpty && !MediaQuery.disableAnimationsOf(context)) {
      _snappingIds = arrivals;
      _snapIn.forward(from: 0.0);
    }
  }

  void _onRefused() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _shake.forward(from: 0.0);
  }

  @override
  void dispose() {
    widget.refusalSignal?.removeListener(_onRefused);
    _snapIn.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final visibleItems = _visibleItems;
    final overflowCount = items.length - visibleItems.length;
    final printsLeft = overflowCount > 0 ? TuckedPrintsFan.kOverflowMarkWidth + 2.0 : 2.0;
    final printTop = widget.sheetEdgeOffset - TuckedPrintsFan.kPeek;

    final prints = Stack(
      clipBehavior: Clip.none,
      children: [
        if (overflowCount > 0)
          Positioned(
            left: 0.0,
            width: TuckedPrintsFan.kOverflowMarkWidth,
            top: printTop,
            height: TuckedPrintsFan.kPeek,
            child: Center(
              child: Text(
                '+$overflowCount',
                // The mark sits on the walnut desk, so it takes the light cinnabar.
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  color: const DeskMediaPalette(isPaperDark: true).cinnabar,
                ),
              ),
            ),
          ),
        for (final (printIndex, item) in visibleItems.indexed)
          Positioned(
            left: printsLeft + printIndex * TuckedPrintsFan.kStride,
            top: printTop,
            child: _SnapIn(
              animation: _snapIn,
              isSnapping: _snappingIds.contains(item.id),
              child: TuckedPrint(
                key: Key('tucked_print_${item.id}'),
                item: item,
                mediaSandboxService: widget.mediaSandboxService,
                tiltInDegrees: TuckedPrintsFan.kTiltsInDegrees[printIndex % TuckedPrintsFan.kTiltsInDegrees.length],
                isPaperDark: widget.isPaperDark,
              ),
            ),
          ),
      ],
    );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Semantics(
        button: true,
        label: '本页夹页影札 ${items.length} 枚，轻触展开',
        onTap: widget.onTap,
        excludeSemantics: true,
        child: GestureDetector(
          key: const Key('tucked_prints'),
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: SizedBox(
            width: TuckedPrintsFan.widthFor(items.length),
            height: TuckedPrintsFan.kTargetHeight,
            // The sheet covers the prints below its edge.
            child: ClipRect(
              clipper: _AboveSheetEdge(widget.sheetEdgeOffset),
              child: AnimatedBuilder(
                animation: _shake,
                builder: (shakeContext, child) => Transform.translate(
                  offset: Offset(_shakeOffset.evaluate(_shake) * TuckedPrintsFan.kShakeAmplitude, 0.0),
                  child: child,
                ),
                child: prints,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slides a newly mounted print down into the sheet edge, after the
/// prototype's `mountSnapIn` keyframes (scale 1.22 → 0.95 → 1, rotation
/// -6° → +1° → rest, fading in by 70%), lifted above the edge rather than below.
class _SnapIn extends StatelessWidget {
  final Animation<double> animation;
  final bool isSnapping;
  final Widget child;

  const _SnapIn({required this.animation, required this.isSnapping, required this.child});

  static double _keyframes(double progress, double from, double middle, double to) => progress < 0.7
      ? lerpDouble(from, middle, progress / 0.7)!
      : lerpDouble(middle, to, (progress - 0.7) / 0.3)!;

  @override
  Widget build(BuildContext context) {
    if (!isSnapping) return child;
    return AnimatedBuilder(
      animation: animation,
      builder: (snapContext, snapChild) {
        if (animation.isCompleted) return snapChild!;
        final progress = TuckedPrintsFan.kSnapInCurve.transform(animation.value);
        final scale = _keyframes(progress, 1.22, 0.95, 1.0);
        final lift = _keyframes(progress, -14.0, 2.0, 0.0);
        final turn = _keyframes(progress, -6.0, 1.0, 0.0);
        final opacity = progress < 0.7 ? progress / 0.7 : 1.0;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0.0, lift),
            child: Transform.rotate(
              angle: turn * math.pi / 180.0,
              child: Transform.scale(scale: scale, child: snapChild),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Clips everything below the sheet's top edge, leaving the band above (and
/// the sides) open for the prints' tilt, tape and shake.
class _AboveSheetEdge extends CustomClipper<Rect> {
  final double sheetEdgeOffset;

  const _AboveSheetEdge(this.sheetEdgeOffset);

  @override
  Rect getClip(Size size) => Rect.fromLTRB(-24.0, -24.0, size.width + 24.0, sheetEdgeOffset);

  @override
  bool shouldReclip(_AboveSheetEdge oldClipper) => oldClipper.sheetEdgeOffset != sheetEdgeOffset;
}
