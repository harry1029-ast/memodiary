import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/widgets/scroll_roller_fab.dart';
import 'package:memodiary/features/home/models/home_tab.dart';

/// The Home Shell's woodwork bottom bar: `日记 · [Scroll Roller Button] · 相册`.
///
/// Colours come from the active [AtmospherePalette] woodwork tokens; the
/// Scroll Roller Button sits raised in a centre notch and follows [selectedTab].
class TabRail extends StatelessWidget {
  /// Height of the woodwork bar itself, above the system bottom inset.
  static const double barHeight = 56.0;

  /// How far the Scroll Roller Button rises above the bar's top edge.
  static const double buttonRise = 18.0;

  static const double _notchDepth = 8.0;
  static const double _notchWidth = ScrollRollerFab.width + 12.0;

  final HomeTab selectedTab;
  final ValueChanged<HomeTab> onTabSelected;
  final VoidCallback onCentrePressed;

  const TabRail({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onCentrePressed,
  });

  /// Total rail height for a given system bottom inset.
  static double heightFor(double bottomInset) =>
      buttonRise + barHeight + bottomInset;

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: heightFor(bottomInset),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: buttonRise,
              child: DecoratedBox(
                key: const Key('tab_rail_surface'),
                decoration: ShapeDecoration(
                  shape: TabRailNotchBorder(
                    notchWidth: _notchWidth,
                    notchDepth: _notchDepth,
                    hairlineColor: palette.woodFrameHighlight,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [palette.woodFrameMid, palette.woodFrameDark],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  // The tab bar holds only the two tabs; the centre button
                  // is a sibling, since a tab bar's children must be tabs.
                  child: Semantics(
                    container: true,
                    role: SemanticsRole.tabBar,
                    explicitChildNodes: true,
                    child: Row(
                      children: [
                        Expanded(child: _buildTab(HomeTab.diary, palette)),
                        const SizedBox(width: _notchWidth),
                        Expanded(child: _buildTab(HomeTab.albums, palette)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: ScrollRollerFab(
                  key: const Key('tab_rail_centre_button'),
                  label: selectedTab.primaryActionLabel,
                  icon: selectedTab.primaryActionIcon,
                  onPressed: onCentrePressed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(HomeTab tab, AtmospherePalette palette) {
    return _TabRailItem(
      key: Key('tab_rail_tab_${tab.name}'),
      label: tab.label,
      isSelected: tab == selectedTab,
      palette: palette,
      onTap: () => onTabSelected(tab),
    );
  }
}

class _TabRailItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final AtmospherePalette palette;
  final VoidCallback onTap;

  const _TabRailItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      role: SemanticsRole.tab,
      selected: isSelected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 1.2,
                  color: isSelected
                      ? palette.headerTitleText
                      : palette.headerSubText,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                key: isSelected ? const Key('tab_rail_selected_mark') : null,
                width: 18,
                height: 2.5,
                decoration: BoxDecoration(
                  color: isSelected
                      ? palette.accentPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rail's outline: a flat top edge with a shallow cradle notch in the
/// centre for the Scroll Roller Button, traced with a woodwork hairline.
class TabRailNotchBorder extends ShapeBorder {
  final double notchWidth;
  final double notchDepth;
  final Color hairlineColor;

  const TabRailNotchBorder({
    required this.notchWidth,
    required this.notchDepth,
    required this.hairlineColor,
  });

  static const double _shoulder = 12.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => TabRailNotchBorder(
        notchWidth: notchWidth * t,
        notchDepth: notchDepth * t,
        hairlineColor: hairlineColor,
      );

  Path _topEdge(Rect rect) {
    final centreX = rect.center.dx;
    final halfNotch = notchWidth / 2;
    final top = rect.top;
    return Path()
      ..moveTo(rect.left, top)
      ..lineTo(centreX - halfNotch - _shoulder, top)
      ..cubicTo(
        centreX - halfNotch, top,
        centreX - halfNotch, top + notchDepth,
        centreX - halfNotch + _shoulder, top + notchDepth,
      )
      ..lineTo(centreX + halfNotch - _shoulder, top + notchDepth)
      ..cubicTo(
        centreX + halfNotch, top + notchDepth,
        centreX + halfNotch, top,
        centreX + halfNotch + _shoulder, top,
      )
      ..lineTo(rect.right, top);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _topEdge(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
      _topEdge(rect),
      Paint()
        ..color = hairlineColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TabRailNotchBorder &&
      other.notchWidth == notchWidth &&
      other.notchDepth == notchDepth &&
      other.hairlineColor == hairlineColor;

  @override
  int get hashCode => Object.hash(notchWidth, notchDepth, hairlineColor);
}
