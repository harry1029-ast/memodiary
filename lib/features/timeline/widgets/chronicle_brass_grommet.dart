import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';

/// Sculpted brass knot grommet (`黄铜绳扣`) anchored at the bottom-left spine axis
/// of the `Date Index Tray`, feeding the vertical `TimelineDateSpineItem` cord.
class ChronicleBrassGrommet extends StatelessWidget {
  final bool hasEntriesBelow;

  const ChronicleBrassGrommet({
    super.key,
    required this.hasEntriesBelow,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;

    // Inside the desk mat container, TimelineDateSpineItem renders its vertical
    // spine line at left: 36.0 (width 2.0 -> center X = 37.0).
    // Placing an 18dp grommet at left: 28.0 centers it identically at X = 37.0.
    return SizedBox(
      key: const Key('timeline_brass_grommet'),
      height: 14.0,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (hasEntriesBelow)
            Positioned(
              left: 36.0,
              top: 7.0,
              bottom: 0.0,
              child: Container(
                width: 2.0,
                color: palette.accentPrimary.withValues(alpha: 0.78),
              ),
            ),
          Positioned(
            left: 28.0,
            top: 2.0,
            child: Container(
              key: const Key('timeline_brass_grommet_knot'),
              width: 18.0,
              height: 10.0,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFDFC184), Color(0xFF9A7638)],
                ),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: const Color(0xFFF5E0B2).withValues(alpha: 0.85),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Container(
                width: 5.0,
                height: 5.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.deskMat,
                  border: Border.all(
                    color: palette.accentSecondaryDim,
                    width: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
