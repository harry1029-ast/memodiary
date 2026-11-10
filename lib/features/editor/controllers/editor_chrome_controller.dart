import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// The entry editor's panel state, shared by the screen, the desk canvas and
/// the writing panels below it: the software keyboard, the Desk
/// Workstation's collapsed state, dictation and the Writing Dock's visibility.
class EditorChromeController extends ChangeNotifier {
  double _keyboardInset = 0.0;

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

  /// Records the keyboard inset, read on every build of the editor screen
  /// above its [Scaffold] (which strips the inset from its body). Never
  /// notifies: the inset change already rebuilds every consumer. Returns
  /// whether this update closed the keyboard.
  bool syncKeyboardInset(double keyboardInset) {
    final wasVisible = isKeyboardVisible;
    _keyboardInset = keyboardInset;
    return wasVisible && !isKeyboardVisible;
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

  void toggleWorkstation() {
    _isWorkstationResolved = true;
    _isWorkstationCollapsed = !_isWorkstationCollapsed;
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

  void setWritingDockVisible(bool isVisible) {
    if (_isWritingDockVisible == isVisible) return;
    _isWritingDockVisible = isVisible;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
