import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/atmosphere_palettes.dart';
import 'package:memodiary/core/theme/atmosphere_theme_models.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/timeline/widgets/window_sill_ledge.dart';
import 'package:memodiary/features/timeline/widgets/window_sill_ornaments_painter.dart';

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

    testWidgets('renders enlarged (~1.45x) study ornaments on slim 44dp shelf without overflow at 320px', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: WindowSillLedge(
                  isCandleLit: true,
                  onToggleCandle: () {},
                  enableAmbientAnimation: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const Key('timeline_window_sill_ledge'))).height,
        44.0,
      );

      final customPaints = tester.widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(const Key('timeline_window_sill_ledge')),
          matching: find.byType(CustomPaint),
        ),
      );

      final bonsai = customPaints.firstWhere((paint) => paint.painter.runtimeType.toString() == 'PineBonsaiPainter');
      final brush = customPaints.firstWhere((paint) => paint.painter.runtimeType.toString() == 'BrushStandPainter');
      final candle = customPaints.firstWhere((paint) => paint.painter.runtimeType.toString() == 'BrassCandlestickPainter');
      final incense = customPaints.firstWhere((paint) => paint.painter.runtimeType.toString() == 'CeladonIncensePainter');

      final bonsaiSize = tester.getSize(find.byWidget(bonsai));
      final brushSize = tester.getSize(find.byWidget(brush));
      final candleSize = candle.size;
      final incenseSize = incense.size;

      expect(bonsaiSize.height, greaterThanOrEqualTo(44.0));
      expect(brushSize.height, greaterThanOrEqualTo(42.0));
      expect(candleSize.height, greaterThanOrEqualTo(48.0));
      expect(incenseSize.height, greaterThanOrEqualTo(38.0));
    });

    testWidgets(
      'adapts sill gradient, lip highlight, and brass corner brackets across yunhaoDay, yunhaoNight, and classicWalnut with zero retired fluff text',
      (tester) async {
        final themesToVerify = [
          (
            theme: InkDiaryTheme.forLightPalette(LightAtmospherePaletteId.yunhaoDay),
            expectedPalette: AtmospherePalettes.yunhaoDay,
          ),
          (
            theme: InkDiaryTheme.forDarkPalette(DarkAtmospherePaletteId.yunhaoNight),
            expectedPalette: AtmospherePalettes.yunhaoNight,
          ),
          (
            theme: InkDiaryTheme.forLightPalette(LightAtmospherePaletteId.classicWalnut),
            expectedPalette: AtmospherePalettes.classicWalnut,
          ),
        ];

        for (final entry in themesToVerify) {
          await tester.pumpWidget(
            MaterialApp(
              theme: entry.theme,
              home: Scaffold(
                body: Center(
                  child: WindowSillLedge(
                    isCandleLit: true,
                    onToggleCandle: () {},
                    enableAmbientAnimation: false,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('姿态'), findsNothing);
          expect(find.textContaining('忆昔'), findsNothing);

          final containers = tester
              .widgetList<Container>(
                find.descendant(
                  of: find.byKey(const Key('timeline_window_sill_ledge')),
                  matching: find.byType(Container),
                ),
              )
              .where((container) => container.decoration is BoxDecoration)
              .toList();

          // First BoxDecoration container is the upper sill shelf gradient
          final sillDecoration = containers[0].decoration! as BoxDecoration;
          final sillGradient = sillDecoration.gradient! as LinearGradient;
          expect(
            sillGradient.colors,
            equals([
              entry.expectedPalette.sillTop,
              entry.expectedPalette.sillBottom,
            ]),
          );
          expect(
            (sillDecoration.border! as Border).top.color,
            equals(entry.expectedPalette.woodFrameHighlight),
          );

          // Second BoxDecoration container is the carved front lip
          final lipDecoration = containers[1].decoration! as BoxDecoration;
          final lipGradient = lipDecoration.gradient! as LinearGradient;
          expect(
            lipGradient.colors,
            equals([
              entry.expectedPalette.lipTop,
              entry.expectedPalette.lipBottom,
            ]),
          );
          expect(
            (lipDecoration.border! as Border).top.color,
            equals(entry.expectedPalette.accentSecondary.withValues(alpha: 0.42)),
          );

          final bracketsPaint = tester.widget<CustomPaint>(
            find.descendant(
              of: find.byWidget(containers[1]),
              matching: find.byType(CustomPaint),
            ),
          );
          final bracketsPainter =
              bracketsPaint.painter! as BrassCornerBracketsPainter;
          expect(
            bracketsPainter.brassColor,
            equals(entry.expectedPalette.accentSecondary),
          );
        }
      },
    );
  });
}
