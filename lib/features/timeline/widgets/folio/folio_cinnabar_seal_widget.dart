import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../templates/models/template_style.dart';
import 'folio_reading_perspective.dart';

/// Interactive Cinnabar Signature Seal widget that stamps onto the concluding leaf.
///
/// Features:
/// - 2x2 carved Seal block with Zhuwen (朱文 relief) or Baiwen (白文 intaglio) carving.
/// - Dynamic landing pop animation (1.42 scale -> 0.94 overshoot -> 1.0 settling at -4° tilt).
/// - Expanding cinnabar shockwave ripple ring on impact.
/// - Medium haptic feedback ([HapticFeedback.mediumImpact]).
/// - Tap-to-restamp animation replay.
/// - Accessible semantics labeled '钤印' and identified by [Key('folio_seal_stamp')].
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

    if (widget.animateOnMount) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
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
    final chars = widget.sealText.runes.map(String.fromCharCode).toList();
    while (chars.length < 4) {
      chars.add('印');
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

              // Carved 2x2 Cinnabar Seal Block
              Transform.rotate(
                angle: rotDeg * math.pi / 180,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: isZhuwen
                          ? sealColor.withValues(alpha: 0.08)
                          : sealColor,
                      border: Border.all(
                        color: sealColor,
                        width: isZhuwen ? 2.2 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: GridView.count(
                      crossAxisCount: 2,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: chars.take(4).map((character) {
                        return Center(
                          child: Text(
                            character,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: widget.theme.fontFamily,
                              color: isZhuwen ? sealColor : widget.theme.pageBg,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
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
