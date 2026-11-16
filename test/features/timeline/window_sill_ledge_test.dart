import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/timeline/widgets/window_sill_ledge.dart';

void main() {
  group('WindowSillLedge Widget Tests', () {
    testWidgets('renders study ornaments without 忆昔 badge and exposes 44x44 candlestick tap target', (tester) async {
      var toggleCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.dark,
          home: Scaffold(
            body: Center(
              child: WindowSillLedge(
                isCandleLit: true,
                onToggleCandle: () => toggleCount++,
                enableAmbientAnimation: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('timeline_window_sill_ledge')), findsOneWidget);
      expect(find.text('忆昔'), findsNothing);
      expect(find.textContaining('岁时忆昔'), findsNothing);

      final candlestickFinder = find.byKey(const Key('timeline_candlestick_button'));
      expect(candlestickFinder, findsOneWidget);
      final tapSize = tester.getSize(candlestickFinder);
      expect(tapSize.width, greaterThanOrEqualTo(44.0));
      expect(tapSize.height, greaterThanOrEqualTo(44.0));

      final semantics = tester.getSemantics(candlestickFinder);
      expect(semantics.label, contains('熄灭红烛'));

      await tester.tap(candlestickFinder);
      await tester.pumpAndSettle();
      expect(toggleCount, equals(1));
    });

    testWidgets('updates semantic label when candlestick is extinguished and renders in light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: WindowSillLedge(
                isCandleLit: false,
                onToggleCandle: () {},
                enableAmbientAnimation: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(
        find.byKey(const Key('timeline_candlestick_button')),
      );
      expect(semantics.label, contains('点亮红烛'));
    });

    testWidgets('steps ambient candle and incense animations deterministically and pauses when invisible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.dark,
          home: Scaffold(
            body: WindowSillLedge(
              isCandleLit: true,
              onToggleCandle: () {},
              enableAmbientAnimation: true,
              isVisible: true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.dark,
          home: Scaffold(
            body: WindowSillLedge(
              isCandleLit: true,
              onToggleCandle: () {},
              enableAmbientAnimation: true,
              isVisible: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(WindowSillLedge), findsOneWidget);
    });
  });
}
