import 'package:flutter_test/flutter_test.dart';

/// Ergonomic test helper extension for reliable interaction with scrollable widgets.
extension WidgetTesterScrollHelpers on WidgetTester {
  /// Ensures [finder] is visible in its enclosing scrollable before performing a tap.
  Future<void> tapVisible(Finder finder, {bool warnIfMissed = true}) async {
    await ensureVisible(finder);
    await pumpAndSettle();
    await tap(finder, warnIfMissed: warnIfMissed);
    await pumpAndSettle();
  }
}
