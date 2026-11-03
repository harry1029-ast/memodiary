import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/widgets/stationery_sheet_border_chrome.dart';
import 'package:memodiary/features/templates/models/template_style.dart';

void main() {
  group('StationerySheetBorderChrome Navigation Chevrons Tests', () {
    testWidgets('hides left chevron and shows right chevron on first sheet of multi-sheet entry', (tester) async {
      var prevTapped = false;
      var nextTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                StationerySheetBorderChrome(
                  currentSheetIndex: 0,
                  totalSheets: 3,
                  onPreviousSheet: () => prevTapped = true,
                  onNextSheet: () => nextTapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('editor_prev_sheet_btn')), findsNothing);
      expect(find.byKey(const Key('editor_next_sheet_btn')), findsOneWidget);
      expect(find.text('›'), findsOneWidget);
      expect(find.text('‹'), findsNothing);

      await tester.tap(find.byKey(const Key('editor_next_sheet_btn')));
      await tester.pump();

      expect(nextTapped, isTrue);
      expect(prevTapped, isFalse);
    });

    testWidgets('shows both left and right chevrons on continuation sheet', (tester) async {
      var prevTapped = false;
      var nextTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                StationerySheetBorderChrome(
                  currentSheetIndex: 1,
                  totalSheets: 3,
                  onPreviousSheet: () => prevTapped = true,
                  onNextSheet: () => nextTapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('editor_prev_sheet_btn')), findsOneWidget);
      expect(find.byKey(const Key('editor_next_sheet_btn')), findsOneWidget);
      expect(find.text('‹'), findsOneWidget);
      expect(find.text('›'), findsOneWidget);

      await tester.tap(find.byKey(const Key('editor_prev_sheet_btn')));
      await tester.pump();
      expect(prevTapped, isTrue);

      await tester.tap(find.byKey(const Key('editor_next_sheet_btn')));
      await tester.pump();
      expect(nextTapped, isTrue);
    });

    testWidgets('shows left chevron and hides right chevron on final sheet', (tester) async {
      var prevTapped = false;
      var nextTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                StationerySheetBorderChrome(
                  currentSheetIndex: 2,
                  totalSheets: 3,
                  onPreviousSheet: () => prevTapped = true,
                  onNextSheet: () => nextTapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('editor_prev_sheet_btn')), findsOneWidget);
      expect(find.byKey(const Key('editor_next_sheet_btn')), findsNothing);

      await tester.tap(find.byKey(const Key('editor_prev_sheet_btn')));
      await tester.pump();
      expect(prevTapped, isTrue);
      expect(nextTapped, isFalse);
    });

    testWidgets('hides both chevrons on single-sheet entry', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                StationerySheetBorderChrome(
                  currentSheetIndex: 0,
                  totalSheets: 1,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('editor_prev_sheet_btn')), findsNothing);
      expect(find.byKey(const Key('editor_next_sheet_btn')), findsNothing);
    });

    testWidgets('provides accessible button semantics for chevrons', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                StationerySheetBorderChrome(
                  currentSheetIndex: 1,
                  totalSheets: 3,
                  onPreviousSheet: () {},
                  onNextSheet: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('上一页 · Previous Sheet'), findsOneWidget);
      expect(find.bySemanticsLabel('下一页 · Next Sheet'), findsOneWidget);
      semanticsHandle.dispose();
    });
  });

  group('StationeryPageIndicator Tests', () {
    testWidgets('renders accurate page counter text format', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StationeryPageIndicator(
              currentSheetIndex: 2,
              totalSheets: 5,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('editor_sheet_indicator')), findsOneWidget);
      expect(find.text('第 3 / 5 页'), findsOneWidget);
    });

    testWidgets('clamps text scaling to <= 1.2 under large accessibility scale factors', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2.5),
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: StationeryPageIndicator(
                currentSheetIndex: 0,
                totalSheets: 2,
              ),
            ),
          ),
        ),
      );

      final mediaQueryFinder = find.descendant(
        of: find.byType(StationeryPageIndicator),
        matching: find.byType(MediaQuery),
      );
      expect(mediaQueryFinder, findsOneWidget);

      final mediaQueryWidget = tester.widget<MediaQuery>(mediaQueryFinder);
      expect(mediaQueryWidget.data.textScaler.scale(10.0), closeTo(12.0, 0.01));
      expect(mediaQueryWidget.data.textScaler.scale(1.0), lessThanOrEqualTo(1.2));
    });

    testWidgets('provides accessible page indicator semantics', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StationeryPageIndicator(
              currentSheetIndex: 1,
              totalSheets: 4,
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('第 2 页，共 4 页'), findsOneWidget);
      semanticsHandle.dispose();
    });

    testWidgets('maintains high contrast ink legibility across substrates', (tester) async {
      // 1. Obsidian (Dark)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StationeryPageIndicator(
              currentSheetIndex: 0,
              totalSheets: 1,
              substrate: PaperSubstrate.obsidian,
              isPaperDark: true,
            ),
          ),
        ),
      );
      var textWidget = tester.widget<Text>(find.text('第 1 / 1 页'));
      expect(textWidget.style?.color, const Color(0xFFF0ECE3));

      // 2. Cold Gold
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StationeryPageIndicator(
              currentSheetIndex: 0,
              totalSheets: 1,
              substrate: PaperSubstrate.coldGold,
            ),
          ),
        ),
      );
      textWidget = tester.widget<Text>(find.text('第 1 / 1 页'));
      expect(textWidget.style?.color, const Color(0xFF2A2216));

      // 3. Kraft
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StationeryPageIndicator(
              currentSheetIndex: 0,
              totalSheets: 1,
              substrate: PaperSubstrate.kraft,
            ),
          ),
        ),
      );
      textWidget = tester.widget<Text>(find.text('第 1 / 1 页'));
      expect(textWidget.style?.color, const Color(0xFF2C241B));

      // 4. Xuan (Light)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StationeryPageIndicator(
              currentSheetIndex: 0,
              totalSheets: 1,
              substrate: PaperSubstrate.xuan,
            ),
          ),
        ),
      );
      textWidget = tester.widget<Text>(find.text('第 1 / 1 页'));
      expect(textWidget.style?.color, const Color(0xFF2D2D2D));
    });
  });
}
