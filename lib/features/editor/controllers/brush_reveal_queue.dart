import 'package:flutter/foundation.dart';

/// Items collected in this editing session that still await their one-time
/// Brush Reveal, in collect order. Only a Collect enqueues an item, so items
/// already in the Staging Handscroll (reopen, page turn, unmount) never replay
/// it. The handscroll paints [current] and reports it done; the rest wait.
class BrushRevealQueue extends ChangeNotifier {
  final List<String> _pending = <String>[];
  bool _isDisposed = false;

  bool get hasPending => _pending.isNotEmpty;

  /// The item being painted now, if any.
  String? get current => _pending.isEmpty ? null : _pending.first;

  bool isPending(String mediaId) => _pending.contains(mediaId);

  void enqueue(String mediaId) {
    if (_isDisposed || _pending.contains(mediaId)) return;
    _pending.add(mediaId);
    notifyListeners();
  }

  /// Marks [mediaId] revealed (or no longer revealable: mounted, erased).
  void complete(String mediaId) {
    if (_isDisposed || !_pending.remove(mediaId)) return;
    notifyListeners();
  }

  /// Settles every pending item at once (reduce-motion).
  void clear() {
    if (_isDisposed || _pending.isEmpty) return;
    _pending.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
