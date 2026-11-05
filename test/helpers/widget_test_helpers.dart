import 'package:flutter/rendering.dart';
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

/// Asserts every tappable semantics node is at least 44×44 and labelled, and every
/// button exposes a tap action.
///
/// With [within], only nodes centred inside the matched widgets' rects are checked, so a test can hold
/// the surface it owns to the bar while unrelated screen chrome is fixed separately.
/// Wrap the call in `tester.ensureSemantics()` / `dispose()`.
Future<void> expectAccessibleTapTargets(WidgetTester tester, {Finder? within}) async {
  if (within == null) {
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    return;
  }
  const minExtent = 44.0;
  final violations = <String>[];
  final regions = [for (final element in within.evaluate()) tester.getRect(find.byElementPredicate((candidate) => candidate == element))];
  void check(SemanticsNode node) {
    final data = node.getSemanticsData();
    final isTappable = data.hasAction(SemanticsAction.tap) || data.hasAction(SemanticsAction.longPress);
    final nodeRect = _logicalRect(node);
    final isInside = regions.any((region) => region.contains(nodeRect.center));
    final isVisibleNode = isInside && !node.isMergedIntoParent && !data.flagsCollection.isHidden;
    if (isVisibleNode && data.flagsCollection.isButton && !isTappable) {
      violations.add('"${data.label}" is a button with no tap action (screen readers cannot activate it)');
    }
    if (isVisibleNode && isTappable) {
      final size = nodeRect.size;
      if (size.width < minExtent - 0.01 || size.height < minExtent - 0.01) {
        violations.add('"${data.label}" is ${size.width.toStringAsFixed(1)}×${size.height.toStringAsFixed(1)}');
      }
      if (data.label.trim().isEmpty && data.tooltip.trim().isEmpty) {
        violations.add('unlabelled tap target at $nodeRect');
      }
    }
    node.visitChildren((child) {
      check(child);
      return true;
    });
  }

  for (final element in within.evaluate()) {
    var root = tester.getSemantics(find.byElementPredicate((candidate) => candidate == element));
    while (root.parent != null) {
      root = root.parent!;
    }
    check(root);
    break;
  }
  expect(violations, isEmpty, reason: 'Tap targets must be ≥44×44 with a label:\n${violations.join('\n')}');
}

/// The node's rect in logical pixels: ancestor transforms applied, the root's
/// device-pixel-ratio scale left out.
Rect _logicalRect(SemanticsNode node) {
  var rect = node.rect;
  for (SemanticsNode? current = node; current != null && current.parent != null; current = current.parent) {
    final transform = current.transform;
    if (transform != null) rect = MatrixUtils.transformRect(transform, rect);
  }
  return rect;
}
