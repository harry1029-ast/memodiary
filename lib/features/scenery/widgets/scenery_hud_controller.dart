import 'dart:async';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Coordinates the 3-second auto-hide timer and reveal triggers for the
/// expanded `Shanshui Scenery Card` overlays (`SceneryWindowOverlayStrip` and
/// the resting `BambooBlindPullCord` micro-tag).
class SceneryHudController extends ChangeNotifier {
  static const Duration autoHideDuration = Duration(seconds: 3);
  static const Duration fadeDuration = Duration(milliseconds: 380);
  static const Curve fadeCurve = Curves.easeOutCubic;

  Timer? _hideTimer;
  bool _isVisible = true;
  bool _disposed = false;

  bool get isVisible => _isVisible;

  /// Suspends any pending fade-out timer without changing current visibility.
  void suspend() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  /// Restarts the auto-hide countdown when [canAutoHide] permits fading out.
  void scheduleAutoHide({required bool canAutoHide}) {
    suspend();
    if (!canAutoHide || _disposed) return;
    _hideTimer = Timer(autoHideDuration, () {
      if (_disposed) return;
      if (_isVisible) {
        _isVisible = false;
        notifyListeners();
      }
    });
  }

  /// Reveals overlays immediately and restarts the auto-hide countdown if
  /// [canAutoHide] is true.
  void reveal({required bool canAutoHide}) {
    suspend();
    if (!_isVisible && !_disposed) {
      _isVisible = true;
      notifyListeners();
    }
    scheduleAutoHide(canAutoHide: canAutoHide);
  }

  @override
  void dispose() {
    _disposed = true;
    suspend();
    super.dispose();
  }
}
