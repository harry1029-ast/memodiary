import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/shapes/classical_chinese_borders.dart';

void main() {
  group('Classical Chinese Borders & Shapes Tests', () {
    test('BegoniaPlaqueBorder builds valid closed 8-point cut-corner path', () {
      const border = BegoniaPlaqueBorder(cutSize: 8.0);
      const rect = Rect.fromLTWH(0, 0, 100, 40);

      final outerPath = border.getOuterPath(rect);
      expect(outerPath, isNotNull);
      expect(outerPath.getBounds().width, closeTo(100, 0.01));
      expect(outerPath.getBounds().height, closeTo(40, 0.01));

      // Path contains center point and does not contain cut corners
      expect(outerPath.contains(const Offset(50, 20)), isTrue);
      expect(outerPath.contains(const Offset(1, 1)), isFalse);
      expect(outerPath.contains(const Offset(99, 1)), isFalse);
      expect(outerPath.contains(const Offset(1, 39)), isFalse);
      expect(outerPath.contains(const Offset(99, 39)), isFalse);
    });

    test('OctagonalMedallionBorder builds equilateral/chamfered 8-point path', () {
      const border = OctagonalMedallionBorder(chamferRatio: 0.28);
      const rect = Rect.fromLTWH(0, 0, 44, 44);

      final outerPath = border.getOuterPath(rect);
      expect(outerPath, isNotNull);
      expect(outerPath.getBounds().width, closeTo(44, 0.01));
      expect(outerPath.getBounds().height, closeTo(44, 0.01));

      // Contains center, excludes extreme corners
      expect(outerPath.contains(const Offset(22, 22)), isTrue);
      expect(outerPath.contains(const Offset(2, 2)), isFalse);
      expect(outerPath.contains(const Offset(42, 2)), isFalse);
      expect(outerPath.contains(const Offset(2, 42)), isFalse);
      expect(outerPath.contains(const Offset(42, 42)), isFalse);
    });

    test('WaistTallyBorder builds waist tally path with top cord hole', () {
      const border = WaistTallyBorder(cutSize: 8.0, cordHoleRadius: 3.0);
      const rect = Rect.fromLTWH(0, 0, 52, 68);

      final outerPath = border.getOuterPath(rect);
      expect(outerPath, isNotNull);
      expect(outerPath.getBounds().width, closeTo(52, 0.01));
      expect(outerPath.getBounds().height, closeTo(68, 0.01));

      // Contains body center
      expect(outerPath.contains(const Offset(26, 34)), isTrue);
      // Excludes corners
      expect(outerPath.contains(const Offset(1, 1)), isFalse);
    });

    testWidgets('BegoniaPlaqueBorder and OctagonalMedallionBorder paint without errors in Material',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    shape: const BegoniaPlaqueBorder(
                      borderColor: Colors.red,
                      borderWidth: 1.5,
                      innerBorderInset: 2.5,
                      innerBorderColor: Colors.amber,
                    ),
                    color: Colors.white,
                    child: const SizedBox(width: 120, height: 40),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    shape: const OctagonalMedallionBorder(
                      borderColor: Colors.brown,
                      borderWidth: 1.0,
                    ),
                    color: Colors.amber.shade100,
                    child: const SizedBox(width: 44, height: 44),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Material), findsNWidgets(3)); // Scaffold + 2 Material items
    });
  });
}

