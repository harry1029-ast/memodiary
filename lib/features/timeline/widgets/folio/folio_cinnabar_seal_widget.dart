import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../editor/widgets/cinnabar_signature_seal.dart';
import '../../../templates/models/template_style.dart';
import 'folio_reading_perspective.dart';

/// Interactive Cinnabar Signature Seal animation adapter that stamps onto the concluding leaf.
///
/// Delegates 2×2 R-to-L seal carving to [CinnabarSignatureSeal] (backed by
/// `StationeryGeometry.buildSealLayout`), while owning the 620ms landing pop,
/// shockwave ripple ring, haptic impact, and tap-to-restamp replay.
class FolioCinnabarSealWidget extends StatefulWidget {
  final String sealText;
  final FolioSubstrateTheme theme;
  final SealCarvingStyle sealStyle;
  final bool animateOnMount;
  final VoidCallback? onStamped;

  const FolioCinnabarSealWidget({
    super.key = const Key('folio_seal_stamp'),
    required this.sealText,
    required this.theme,
    this.sealStyle = SealCarvingStyle.zhuwen,
    this.animateOnMount = true,
    this.onStamped,
  });

  @override
  State<FolioCinnabarSealWidget> createState() => _FolioCinnabarSealWidgetState();
}

class _FolioCinnabarSealWidgetState extends State<FolioCinnabarSealWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _controller.addListener(_handleAnimationProgress);

    if (widget.sealStyle != SealCarvingStyle.hidden) {
      if (widget.animateOnMount) {
        _controller.forward();
      } else {
        _controller.value = 1.0;
      }
    }
  }

  void _handleAnimationProgress() {
    if (_controller.value >= 0.65 && !_hapticFired) {
      _hapticFired = true;
      HapticFeedback.mediumImpact();
      widget.onStamped?.call();
    }
    setState(() {});
  }

  void _restamp() {
    _hapticFired = false;
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleAnimationProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sealStyle == SealCarvingStyle.hidden) {
      return const SizedBox.shrink();
    }

    final isZhuwen = widget.sealStyle == SealCarvingStyle.zhuwen;
    final sealColor = widget.theme.isDark
        ? const Color(0xFFD95B4B)
        : const Color(0xFFB83B2E);

    final animValue = _controller.value;
    double scale = 1.0;
    double rotDeg = -4.0;

    if (_controller.isAnimating) {
      if (animValue < 0.65) {
        final progress = animValue / 0.65;
        scale = ui.lerpDouble(1.42, 0.94, progress)!;
        rotDeg = ui.lerpDouble(-10.0, -2.5, progress)!;
      } else {
        final progress = (animValue - 0.65) / 0.35;
        scale = ui.lerpDouble(0.94, 1.0, progress)!;
        rotDeg = ui.lerpDouble(-2.5, -4.0, progress)!;
      }
    }

    return Semantics(
      button: true,
      label: '钤印',
      child: GestureDetector(
        onTap: _restamp,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Expanding Cinnabar Shockwave Ripple Ring
              if (_controller.isAnimating)
                Transform.scale(
                  scale: ui.lerpDouble(0.85, 1.65, animValue)!,
                  child: Opacity(
                    opacity: ((1.0 - animValue).clamp(0.0, 1.0) * 0.75),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        border: Border.all(color: sealColor, width: 1.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

              // Carved 2×2 Cinnabar Seal Block
              Transform.rotate(
                angle: rotDeg * math.pi / 180,
                child: Transform.scale(
                  scale: scale,
                  child: CinnabarSignatureSeal(
                    sealStyle: widget.sealStyle,
                    overrideText: widget.sealText,
                    size: 46.0,
                    sealColor: sealColor,
                    intaglioTextColor: widget.theme.pageBg,
                    zhuwenBackgroundColor: sealColor.withValues(alpha: 0.08),
                    fontFamily: widget.theme.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    borderWidth: isZhuwen ? 2.2 : 1.5,
                    borderRadius: 3.0,
                    padding: const EdgeInsets.all(2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                    includeSemantics: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
