import 'package:flutter/widgets.dart';

/// Drives the Diarist Panel's open fraction (0 = closed, 1 = open).
///
/// Buttons and Back call [open] / [close]; drags call [dragTo] per frame and
/// [settle] on release, so a gesture can carry the panel any part of the way.
/// Animations use [AnimationBehavior.normal], so they run near-instantly when
/// the platform asks for reduced motion.
class DiaristPanelController {
  static const Duration slideDuration = Duration(milliseconds: 260);

  /// Fling speed (in panel widths per second) past which a release follows
  /// the fling direction rather than the nearest end.
  static const double flingVelocity = 1.2;

  final AnimationController _animation;

  DiaristPanelController({required TickerProvider vsync})
      : _animation = AnimationController(vsync: vsync, duration: slideDuration);

  /// The open fraction, for widgets that follow the panel.
  Animation<double> get animation => _animation;

  /// The current open fraction.
  double get fraction => _animation.value;

  /// Whether any part of the panel is showing or it is opening.
  bool get isOpen => _animation.value > 0 || _animation.status == AnimationStatus.forward;

  void open() => _animation.animateTo(1.0, curve: Curves.easeOutCubic).ignore();

  void close() => _animation.animateBack(0.0, curve: Curves.easeOutCubic).ignore();

  /// Places the panel at [fraction] (clamped to 0..1) during a drag.
  void dragTo(double fraction) {
    _animation.stop();
    _animation.value = fraction.clamp(0.0, 1.0);
  }

  /// Finishes a drag: a fast fling follows its direction, otherwise the panel
  /// settles on the nearer end. [velocity] is in panel widths per second,
  /// positive towards open.
  void settle({double velocity = 0.0}) {
    final shouldOpen = velocity.abs() >= flingVelocity ? velocity > 0 : _animation.value >= 0.5;
    shouldOpen ? open() : close();
  }

  void dispose() => _animation.dispose();
}

/// Hands the Home Shell's [DiaristPanelController] to widgets inside the shell,
/// such as each tab header's avatar button.
class DiaristPanelScope extends InheritedWidget {
  final DiaristPanelController controller;

  const DiaristPanelScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static DiaristPanelController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DiaristPanelScope>();
    assert(scope != null, 'No DiaristPanelScope above this widget');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(DiaristPanelScope oldWidget) => controller != oldWidget.controller;
}
