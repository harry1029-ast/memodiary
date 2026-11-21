import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/widgets.dart';

/// Whether the Home Shell's Tab Rail is shown, driven by the vertical scrolls
/// that bubble up from the active tab's list.
///
/// Scrolling forward through the list hides the rail and scrolling back
/// reveals it. A list that cannot scroll always reveals it, so the rail never
/// gets stuck hidden. Only the tab's own list counts (notification depth 0):
/// horizontal strips and lists nested inside it are ignored.
class TabRailVisibility extends ValueNotifier<bool> {
  TabRailVisibility() : super(true);

  /// Shows the rail, e.g. on a tab switch.
  void reveal() => value = true;

  /// A [NotificationListener.onNotification] handler; never stops a
  /// notification from bubbling further.
  bool handleScrollNotification(Notification notification) {
    switch (notification) {
      case UserScrollNotification(:final metrics, :final direction)
          when _isTabList(notification.depth, metrics):
        if (!_canScroll(metrics)) {
          reveal();
        } else if (direction == ScrollDirection.reverse) {
          value = false;
        } else if (direction == ScrollDirection.forward) {
          reveal();
        }
      case ScrollMetricsNotification(:final metrics)
          when _isTabList(notification.depth, metrics) && !_canScroll(metrics):
        reveal();
    }
    return false;
  }

  static bool _isTabList(int depth, ScrollMetrics metrics) =>
      depth == 0 && metrics.axis == Axis.vertical;

  static bool _canScroll(ScrollMetrics metrics) =>
      metrics.maxScrollExtent > metrics.minScrollExtent;
}

/// Slides its [child] (the whole Tab Rail, centre button included) out below
/// the screen while [visibility] is hidden. A hidden rail takes no taps and
/// is left out of semantics. With reduced motion on, the rail stays shown.
class TabRailScrollHider extends StatelessWidget {
  static const Duration slideDuration = Duration(milliseconds: 220);

  final TabRailVisibility visibility;
  final Widget child;

  const TabRailScrollHider({
    super.key,
    required this.visibility,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ValueListenableBuilder<bool>(
      valueListenable: visibility,
      child: child,
      builder: (context, visible, child) {
        final shown = visible || reduceMotion;
        return AnimatedSlide(
          offset: shown ? Offset.zero : const Offset(0, 1),
          duration: reduceMotion ? Duration.zero : slideDuration,
          curve: Curves.easeOutCubic,
          child: IgnorePointer(
            ignoring: !shown,
            child: ExcludeSemantics(excluding: !shown, child: child),
          ),
        );
      },
    );
  }
}
