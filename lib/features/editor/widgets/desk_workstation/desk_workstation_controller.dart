import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Whether the Desk Workstation is collapsed, shared by the editor canvas and
/// the Writing Dock's footer handle.
///
/// Until the diarist toggles it, the first measured layout decides: the
/// workstation starts collapsed when its minimum height does not fit.
class DeskWorkstationController extends ChangeNotifier {
  /// Whether the first measured layout has decided the initial state.
  bool _isResolved = false;
  bool _isCollapsed = false;
  bool _isDisposed = false;

  bool get isCollapsed => _isCollapsed;

  /// Resolves the initial state from the first layout and returns it. Safe to
  /// call during layout: listeners are notified after the frame.
  bool resolveInitial({required bool workstationFits}) {
    if (!_isResolved) {
      _isResolved = true;
      _isCollapsed = !workstationFits;
      if (_isCollapsed) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) notifyListeners();
        });
      }
    }
    return _isCollapsed;
  }

  void toggle() {
    _isResolved = true;
    _isCollapsed = !_isCollapsed;
    notifyListeners();
  }

  void expand() {
    if (!_isCollapsed) return;
    _isResolved = true;
    _isCollapsed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
