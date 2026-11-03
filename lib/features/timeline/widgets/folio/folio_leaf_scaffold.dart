import 'package:flutter/material.dart';
import 'folio_reading_perspective.dart';
import 'folio_substrate_painter.dart';

/// Wraps each individual folio leaf sheet in a solid tactile substrate paper backdrop,
/// painting [theme.pageBg] and [FolioSubstratePainter] fibers/gold flecks with
/// thread-bound folio page-edge curvature.
class FolioLeafScaffold extends StatelessWidget {
  final FolioSubstrateTheme theme;
  final Widget child;

  const FolioLeafScaffold({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.pageBg,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: FolioSubstratePainter(
                showGoldFlecks: theme.showGoldFlecks,
                isDark: theme.isDark,
                drawGutterShadow: false,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
