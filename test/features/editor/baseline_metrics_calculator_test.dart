import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/services/baseline_metrics_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BaselineMetricsCalculator Tests', () {
    test('computes positive alphabetic baseline offset for standard fonts', () {
      const style = TextStyle(
        fontSize: 16.0,
        height: 1.5,
      );

      final baseline = BaselineMetricsCalculator.calculateBaselineOffset(style);
      expect(baseline, greaterThan(0.0));
      // Line height is 16.0 * 1.5 = 24.0. Baseline should be inside the line height.
      expect(baseline, lessThanOrEqualTo(24.0));
    });

    test('computes accurate line height from font size and multiplier', () {
      const style = TextStyle(
        fontSize: 18.0,
        height: 1.75,
      );

      final lineHeight = BaselineMetricsCalculator.calculateLineHeight(style);
      expect(lineHeight, closeTo(31.5, 0.01));
    });

    test('caches baseline calculation for identical text styles', () {
      const style1 = TextStyle(
        fontFamily: 'Noto Serif',
        fontSize: 16.0,
        height: 1.5,
      );
      const style2 = TextStyle(
        fontFamily: 'Noto Serif',
        fontSize: 16.0,
        height: 1.5,
      );

      final b1 = BaselineMetricsCalculator.calculateBaselineOffset(style1);
      final b2 = BaselineMetricsCalculator.calculateBaselineOffset(style2);
      expect(b1, equals(b2));
    });

    test('clears cache without error', () {
      expect(() => BaselineMetricsCalculator.clearCache(), returnsNormally);
    });
  });
}

