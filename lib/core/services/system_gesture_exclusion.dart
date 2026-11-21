import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reserves a screen rectangle from Android's system Back gesture through the
/// native `memodiary/gesture_exclusion` channel, which the Activity applies as
/// a system gesture exclusion rect on the Flutter view (ADR 0014).
///
/// Flutter has no public API for this. Only Android has edge Back gestures to
/// exclude, so on every other platform both calls are no-ops and nothing is
/// sent. A missing or failing native side is ignored: the band then simply
/// competes with system Back, as it would without exclusion.
class SystemGestureExclusion {
  static const String channelName = 'memodiary/gesture_exclusion';
  static const MethodChannel _channel = MethodChannel(channelName);

  const SystemGestureExclusion();

  bool get _isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Excludes [rect] (logical pixels, Flutter view coordinates), replacing any
  /// rect set before.
  Future<void> setRect(Rect rect) => _invoke('setRect', <String, Object?>{
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height,
      });

  /// Removes the exclusion, giving the whole edge back to system Back.
  Future<void> clear() => _invoke('clear');

  Future<void> _invoke(String method, [Object? arguments]) async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // No native side (e.g. a host without the bridge): nothing to exclude.
    } on PlatformException {
      // The Activity could not apply the rect; system Back keeps the edge.
    }
  }
}
