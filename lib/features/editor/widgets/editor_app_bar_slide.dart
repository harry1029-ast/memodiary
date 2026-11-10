import 'package:flutter/material.dart';

/// Slides the editor's [appBar] up and away while the software keyboard is
/// open and back when it closes, leaving only a strip of [stripColor] under the
/// status bar.
///
/// It keeps the bar's full height as its [preferredSize] (the [Scaffold]'s
/// maximum), and the Scaffold places its body under whatever height the bar
/// shows this frame, so the desk takes the freed room. While away the bar takes
/// no hits and is hidden from screen readers; the system back gesture is not
/// the bar's, so it keeps working.
class EditorAppBarSlide extends StatelessWidget implements PreferredSizeWidget {
  final bool isAway;
  final Color stripColor;
  final PreferredSizeWidget appBar;

  /// Told, as the bar builds each frame (before the body lays out), how much of
  /// its height is slid away, so the desk can tell its resting height.
  final ValueChanged<double>? onHiddenExtent;

  static const Duration kSlideDuration = Duration(milliseconds: 200);

  const EditorAppBarSlide({
    super.key,
    required this.isAway,
    required this.stripColor,
    required this.appBar,
    this.onHiddenExtent,
  });

  @override
  Size get preferredSize => appBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: stripColor,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: isAway ? 0.0 : 1.0),
          duration: kSlideDuration,
          curve: Curves.easeOutCubic,
          builder: (slideContext, shownFraction, bar) {
            onHiddenExtent?.call(preferredSize.height * (1.0 - shownFraction));
            return ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: shownFraction,
                child: shownFraction > 0.0
                    ? IgnorePointer(ignoring: isAway, child: ExcludeSemantics(excluding: isAway, child: bar))
                    : null,
              ),
            );
          },
          // The status bar's room is kept by the strip above, not by the bar.
          child: MediaQuery.removePadding(context: context, removeTop: true, child: appBar),
        ),
      ),
    );
  }
}
