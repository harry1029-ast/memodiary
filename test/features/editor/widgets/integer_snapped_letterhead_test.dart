import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/models/letterhead_data.dart';
import 'package:memodiary/features/editor/widgets/integer_snapped_letterhead.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';

void main() {
  group('IntegerSnappedLetterhead Calculation Tests', () {
    test('snaps fractional height 109.8px with 24px stride to 120.0px with 5.1px symmetric padding', () {
      const rawHeight = 109.8;
      const stride = 24.0;

      final snappedHeight = IntegerSnappedLetterhead.calculateSnappedHeight(rawHeight, stride);
      final paddingTop = IntegerSnappedLetterhead.calculatePaddingTop(rawHeight, stride);
      final paddingBottom = snappedHeight - rawHeight - paddingTop;

      expect(snappedHeight, equals(120.0));
      expect(paddingTop, closeTo(5.1, 0.001));
      expect(paddingBottom, closeTo(5.1, 0.001));
    });

    test('exact multiple requires zero surplus padding', () {
      const rawHeight = 96.0;
      const stride = 24.0;

      final snappedHeight = IntegerSnappedLetterhead.calculateSnappedHeight(rawHeight, stride);
      final paddingTop = IntegerSnappedLetterhead.calculatePaddingTop(rawHeight, stride);

      expect(snappedHeight, equals(96.0));
      expect(paddingTop, equals(0.0));
    });

    test('snaps 0.0px raw height to 1 stride row', () {
      const rawHeight = 0.0;
      const stride = 24.0;

      final snappedHeight = IntegerSnappedLetterhead.calculateSnappedHeight(rawHeight, stride);
      final paddingTop = IntegerSnappedLetterhead.calculatePaddingTop(rawHeight, stride);

      expect(snappedHeight, equals(24.0));
      expect(paddingTop, equals(12.0));
    });

    test('handles fractional 24.1px height snapping to 48.0px', () {
      const rawHeight = 24.1;
      const stride = 24.0;

      final snappedHeight = IntegerSnappedLetterhead.calculateSnappedHeight(rawHeight, stride);
      final paddingTop = IntegerSnappedLetterhead.calculatePaddingTop(rawHeight, stride);

      expect(snappedHeight, equals(48.0));
      expect(paddingTop, closeTo(11.95, 0.001));
    });

    test('falls back gracefully when lineStridePx <= 0.0', () {
      const rawHeight = 85.5;
      expect(IntegerSnappedLetterhead.calculateSnappedHeight(rawHeight, 0.0), equals(85.5));
      expect(IntegerSnappedLetterhead.calculateSnappedHeight(rawHeight, -5.0), equals(85.5));
    });
  });

  group('IntegerSnappedLetterhead Widget Tests', () {
    testWidgets('clamps outer height to integer stride and centers child vertically', (widgetTester) async {
      await widgetTester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: IntegerSnappedLetterhead(
                lineStridePx: 24.0,
                child: SizedBox(
                  width: 320.0,
                  height: 109.8,
                ),
              ),
            ),
          ),
        ),
      );

      final letterheadFinder = find.byType(IntegerSnappedLetterhead);
      final boxFinder = find.byType(SizedBox);

      expect(letterheadFinder, findsOneWidget);
      expect(boxFinder, findsOneWidget);

      final letterheadSize = widgetTester.getSize(letterheadFinder);
      expect(letterheadSize.width, equals(320.0));
      expect(letterheadSize.height, equals(120.0));

      final letterheadTopLeft = widgetTester.getTopLeft(letterheadFinder);
      final childTopLeft = widgetTester.getTopLeft(boxFinder);
      final childBottomRight = widgetTester.getBottomRight(boxFinder);
      final letterheadBottomRight = widgetTester.getBottomRight(letterheadFinder);

      final actualPaddingTop = childTopLeft.dy - letterheadTopLeft.dy;
      final actualPaddingBottom = letterheadBottomRight.dy - childBottomRight.dy;

      expect(actualPaddingTop, closeTo(5.1, 0.001));
      expect(actualPaddingBottom, closeTo(5.1, 0.001));
    });

    testWidgets('handles title expansion and multi-line wrapping with integer row growth', (widgetTester) async {
      final titleController = TextEditingController(text: 'Short Title');

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 480.0,
                child: IntegerSnappedLetterhead(
                  lineStridePx: 24.0,
                  child: JournalLetterhead(
                    data: LetterheadData.resolve(
                      entryDate: DateTime(2026, 11, 2),
                      mood: 3,
                      weather: 'sunny',
                    ),
                    titleController: titleController,
                    onDateChanged: (selectedDate) {},
                    onMoodChanged: (selectedMood) {},
                    onWeatherChanged: (selectedWeather) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();

      final initialSize = widgetTester.getSize(find.byType(IntegerSnappedLetterhead));
      // Outer layout height must be an exact integer multiple of 24.0
      expect(initialSize.height % 24.0, equals(0.0));

      // Enter a very long multi-line title causing wrapping
      await widgetTester.enterText(
        find.byType(TextField),
        '九秋风露越窑开，夺得千峰翠色来。好向书窗闲展玩，试将心事付素笺。极目平芜远树齐，暮云收尽暮天低。',
      );
      await widgetTester.pumpAndSettle();

      final expandedSize = widgetTester.getSize(find.byType(IntegerSnappedLetterhead));
      // Outer layout height must expand while strictly maintaining integer stride
      expect(expandedSize.height, greaterThanOrEqualTo(initialSize.height));
      expect(expandedSize.height % 24.0, equals(0.0));
    });

    testWidgets('updates snapped layout height dynamically when lineStridePx changes', (widgetTester) async {
      double activeStride = 24.0;

      await widgetTester.pumpWidget(
        StatefulBuilder(
          builder: (buildContext, setInnerState) {
            return MaterialApp(
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    children: [
                      IntegerSnappedLetterhead(
                        lineStridePx: activeStride,
                        child: const SizedBox(
                          width: 300.0,
                          height: 100.0,
                        ),
                      ),
                      TextButton(
                        key: const Key('change_stride_btn'),
                        onPressed: () {
                          setInnerState(() {
                            activeStride = 28.0;
                          });
                        },
                        child: const Text('Change Stride'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      // Stride 24: ceil(100 / 24) * 24 = 5 * 24 = 120.0
      expect(widgetTester.getSize(find.byType(IntegerSnappedLetterhead)).height, equals(120.0));

      // Tap to change stride to 28: ceil(100 / 28) * 28 = 4 * 28 = 112.0
      await widgetTester.tap(find.byKey(const Key('change_stride_btn')));
      await widgetTester.pumpAndSettle();

      expect(widgetTester.getSize(find.byType(IntegerSnappedLetterhead)).height, equals(112.0));
    });
  });
}
