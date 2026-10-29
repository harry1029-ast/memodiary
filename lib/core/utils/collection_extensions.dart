/// Safety and boundary utility extensions on collections.
extension SafeIndexListExtension<T> on List<T> {
  /// Safely clamps [index] to valid bounds `[0, length - 1]`.
  /// Returns `null` if the list is empty.
  int? safeClampIndex(int index) {
    if (isEmpty) return null;
    return index.clamp(0, length - 1);
  }
}

