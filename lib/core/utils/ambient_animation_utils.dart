import 'dart:io';

/// Returns whether ambient 60 FPS background animations should run.
///
/// Honors an explicit [enableAmbientAnimation] override first, and otherwise
/// disables ambient loops automatically in `flutter test` environments so
/// widget test harnesses settle deterministically.
bool shouldRunAmbientAnimation([bool? enableAmbientAnimation]) {
  if (enableAmbientAnimation != null) {
    return enableAmbientAnimation;
  }
  try {
    return Platform.environment['FLUTTER_TEST'] != 'true';
  } catch (_) {
    return true;
  }
}
