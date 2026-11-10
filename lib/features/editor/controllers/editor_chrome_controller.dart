import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../services/editor_settings_service.dart';

/// The entry editor's panel state, shared by the screen, the desk canvas and
/// the writing panels below it: the software keyboard (and the app bar that
/// slides away for it), the desk's resting height, the Desk Workstation's
/// collapsed state, dictation and the Writing Dock's visibility.
class EditorChromeController extends ChangeNotifier {
  /// The app-wide preference store behind the Writing Dock's visibility. Null
  /// keeps the controller memory-only.
  final EditorSettingsService? _settings;

  EditorChromeController({EditorSettingsService? settings}) : _settings = settings;

  bool _hasDockVisibilityChanged = false;
  double _keyboardInset = 0.0;
  double _appBarHiddenExtent = 0.0;
  double? _restingDeskHeight;

  /// Whether the first measured layout has decided the workstation's state.
  bool _isWorkstationResolved = false;
  bool _isWorkstationCollapsed = false;
  bool _isDictating = false;
  bool _isWritingDockVisible = true;
  bool _isDisposed = false;

  /// Height of the software keyboard covering the screen (0 when closed).
  double get keyboardInset => _keyboardInset;
  bool get isKeyboardVisible => _keyboardInset > 0;
  bool get isWorkstationCollapsed => _isWorkstationCollapsed;
  bool get isDictating => _isDictating;
  bool get isWritingDockVisible => _isWritingDockVisible;

  /// Whether the Writing Dock's 展开文房 restore tab floats on the desk: only
  /// while the dock is hidden and the keyboard is closed (while typing, the
  /// keyboard accessory row's toggle stands in for it).
  bool get showsWritingDockRestoreTab => !_isWritingDockVisible && !isKeyboardVisible;

  /// Records the keyboard inset, read on every build of the editor screen
  /// above its [Scaffold] (which strips the inset from its body). Never
  /// notifies: the inset change already rebuilds every consumer. Returns
  /// whether this update closed the keyboard.
  bool syncKeyboardInset(double keyboardInset) {
    final wasVisible = isKeyboardVisible;
    _keyboardInset = keyboardInset;
    return wasVisible && !isKeyboardVisible;
  }

  /// Records how far the app bar has slid away this frame. The bar reports it
  /// as it builds, before the desk lays out. Never notifies.
  void syncAppBarHiddenExtent(double hiddenExtent) => _appBarHiddenExtent = hiddenExtent;

  /// The desk's height at rest: keyboard closed and every bar in place. The
  /// sheet is resolved against it, so neither the keyboard nor the chrome
  /// stepping aside for it (app bar, Writing Dock) moves or resizes the sheet.
  ///
  /// While the keyboard is closed it is the [visibleHeight] less any app bar
  /// still sliding back; while open, the last resting measure stands (before
  /// any, it is estimated from the keyboard's inset and the app bar). Safe to
  /// call during layout.
  double resolveRestingDeskHeight(double visibleHeight) {
    if (!isKeyboardVisible) _restingDeskHeight = visibleHeight - _appBarHiddenExtent;
    return _restingDeskHeight ?? visibleHeight + _keyboardInset - _appBarHiddenExtent;
  }

  /// Until the diarist toggles it, the first measured layout decides: the
  /// workstation starts collapsed when its minimum height does not fit.
  /// Returns the resolved state. Safe to call during layout: listeners are
  /// notified after the frame.
  bool resolveInitialWorkstation({required bool workstationFits}) {
    if (!_isWorkstationResolved) {
      _isWorkstationResolved = true;
      _isWorkstationCollapsed = !workstationFits;
      if (_isWorkstationCollapsed) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) notifyListeners();
        });
      }
    }
    return _isWorkstationCollapsed;
  }

  void collapseWorkstation() {
    if (_isWorkstationCollapsed) return;
    _isWorkstationResolved = true;
    _isWorkstationCollapsed = true;
    notifyListeners();
  }

  void expandWorkstation() {
    if (!_isWorkstationCollapsed) return;
    _isWorkstationResolved = true;
    _isWorkstationCollapsed = false;
    notifyListeners();
  }

  void toggleDictation() {
    _isDictating = !_isDictating;
    notifyListeners();
  }

  void stopDictation() {
    if (!_isDictating) return;
    _isDictating = false;
    notifyListeners();
  }

  /// The diarist hides or shows the Writing Dock; the choice is stored as an
  /// app-wide preference.
  void setWritingDockVisible(bool isVisible) {
    _hasDockVisibilityChanged = true;
    if (_isWritingDockVisible == isVisible) return;
    _isWritingDockVisible = isVisible;
    notifyListeners();
    _settings?.setIsWritingDockHidden(!isVisible);
  }

  /// Applies the stored Writing Dock preference unless the diarist has
  /// already chosen in this session.
  Future<void> restorePreferences() async {
    final settings = _settings;
    if (settings == null) return;
    final isHidden = await settings.getIsWritingDockHidden();
    if (_isDisposed || _hasDockVisibilityChanged || !isHidden) return;
    _isWritingDockVisible = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
