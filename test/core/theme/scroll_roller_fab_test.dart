import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/atmosphere_theme_models.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/shapes/classical_chinese_borders.dart';
import 'package:memodiary/core/theme/widgets/scroll_roller_fab.dart';

void main() {
  group('ScrollRollerFab Atmosphere Theme Tests', () {
    testWidgets('renders 写日记 label, exposes button semantics, and invokes onPressed', (tester) async {
      var tappedCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Center(
              child: ScrollRollerFab(
                onPressed: () => tappedCount++,
              ),
            ),
          ),
        ),
      );

      expect(find.text('写日记'), findsOneWidget);
      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
      expect(find.bySemanticsLabel('写日记'), findsOneWidget);

      final semantics = tester.getSemantics(find.bySemanticsLabel('写日记'));
      expect(
        semantics,
        matchesSemantics(
          label: '写日记',
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );

      await tester.tap(find.byType(ScrollRollerFab));
      await tester.pumpAndSettle();
      expect(tappedCount, 1);
    });

    testWidgets('collapses to 52dp rolled-up token when isRolledUp is true and preserves semantics and tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Center(
              child: ScrollRollerFab(
                isRolledUp: false,
                subLabel: '随笔',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('写日记'), findsOneWidget);
      expect(find.text('随笔'), findsOneWidget);
      expect(find.bySemanticsLabel('写日记 随笔'), findsOneWidget);
      expect(tester.getSize(find.byType(ScrollRollerFab)).width, 178.0);

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Center(
              child: ScrollRollerFab(
                isRolledUp: true,
                subLabel: '随笔',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(ScrollRollerFab)).width, 52.0);
      expect(find.text('写日记'), findsNothing);
      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
      expect(find.bySemanticsLabel('写日记 随笔'), findsOneWidget);

      await tester.tap(find.byType(ScrollRollerFab));
      expect(tapped, isTrue);
    });

    testWidgets('uses distinct AtmospherePalette gradient, border, rail, knob, and text tokens across yunhaoDay, yunhaoNight, classicWalnut, and classicEbony', (tester) async {
      Future<({
        List<Color> gradientColors,
        Color borderColor,
        Color innerBorderColor,
        Color shadowColor,
        Color textColor,
        Color iconColor,
        Color knobFillColor,
        Color knobBorderColor,
        Color topRailColor,
        Color bottomRailColor,
      })> pumpAndInspect(ThemeData theme) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: ScrollRollerFab(onPressed: () {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fabContainer = tester.widget<AnimatedContainer>(
          find.descendant(
            of: find.byType(ScrollRollerFab),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final shapeDec = fabContainer.decoration! as ShapeDecoration;
        final plaqueBorder = shapeDec.shape as BegoniaPlaqueBorder;
        final gradient = shapeDec.gradient! as LinearGradient;

        final labelText = tester.widget<Text>(find.text('写日记'));
        final icon = tester.widget<Icon>(find.byIcon(Icons.brush_rounded));

        final knobContainers = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(ScrollRollerFab),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Container &&
                      widget.decoration is BoxDecoration &&
                      widget.constraints?.maxWidth == 3.5,
                ),
              ),
            )
            .toList();
        expect(knobContainers.length, 2);
        final knobDec = knobContainers.first.decoration! as BoxDecoration;

        final railContainers = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(ScrollRollerFab),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Container &&
                      widget.decoration == null &&
                      widget.constraints?.maxHeight == 1.0,
                ),
              ),
            )
            .toList();
        expect(railContainers.length, 2);

        return (
          gradientColors: gradient.colors,
          borderColor: plaqueBorder.borderColor,
          innerBorderColor: plaqueBorder.innerBorderColor!,
          shadowColor: shapeDec.shadows!.single.color,
          textColor: labelText.style!.color!,
          iconColor: icon.color!,
          knobFillColor: knobDec.color!,
          knobBorderColor: (knobDec.border! as Border).top.color,
          topRailColor: railContainers.first.color!,
          bottomRailColor: railContainers.last.color!,
        );
      }

      final yunhaoDayTokens = await pumpAndInspect(InkDiaryTheme.light);
      expect(
        yunhaoDayTokens.gradientColors,
        equals(const [Color(0xFF4E8782), Color(0xFF427772), Color(0xFF376662)]),
      );
      expect(yunhaoDayTokens.borderColor, const Color(0xFF8BC2BC));
      expect(yunhaoDayTokens.innerBorderColor, const Color(0x59E6F4F2).withValues(alpha: 0.35));
      expect(yunhaoDayTokens.shadowColor, const Color(0x66376662));
      expect(yunhaoDayTokens.textColor, const Color(0xFFF7FBFA));
      expect(yunhaoDayTokens.iconColor, const Color(0xFFF7FBFA));
      expect(yunhaoDayTokens.knobFillColor, const Color(0xFF48647A));
      expect(yunhaoDayTokens.knobBorderColor, const Color(0xFF8BC2BC));
      expect(yunhaoDayTokens.topRailColor, const Color(0xFFCBE6E3).withValues(alpha: 0.72));
      expect(yunhaoDayTokens.bottomRailColor, const Color(0xFF264845).withValues(alpha: 0.72));

      final yunhaoNightTokens = await pumpAndInspect(InkDiaryTheme.dark);
      expect(
        yunhaoNightTokens.gradientColors,
        equals(const [Color(0xFF223752), Color(0xFF1A2B42), Color(0xFF132133)]),
      );
      expect(yunhaoNightTokens.borderColor, const Color(0xFFF2B866));
      expect(yunhaoNightTokens.innerBorderColor, const Color(0x52F2B866).withValues(alpha: 0.35));
      expect(yunhaoNightTokens.shadowColor, const Color(0x8C060B12));
      expect(yunhaoNightTokens.textColor, const Color(0xFFFFF6E5));
      expect(yunhaoNightTokens.iconColor, const Color(0xFFFFF6E5));
      expect(yunhaoNightTokens.knobFillColor, const Color(0xFF0D1624));
      expect(yunhaoNightTokens.knobBorderColor, const Color(0xFFF2B866));
      expect(yunhaoNightTokens.topRailColor, const Color(0xFFF7D194).withValues(alpha: 0.72));
      expect(yunhaoNightTokens.bottomRailColor, const Color(0xFF121C2A).withValues(alpha: 0.72));

      final classicWalnutTokens = await pumpAndInspect(
        InkDiaryTheme.forLightPalette(LightAtmospherePaletteId.classicWalnut),
      );
      expect(
        classicWalnutTokens.gradientColors,
        equals(const [Color(0xFFC43E30), Color(0xFFA82F22), Color(0xFF8C2014)]),
      );
      expect(classicWalnutTokens.borderColor, const Color(0xFFD9A962));
      expect(classicWalnutTokens.innerBorderColor, const Color(0x59FFE8D6).withValues(alpha: 0.35));
      expect(classicWalnutTokens.shadowColor, const Color(0x738C2014));
      expect(classicWalnutTokens.textColor, const Color(0xFFFFF9F2));
      expect(classicWalnutTokens.iconColor, const Color(0xFFFFF9F2));
      expect(classicWalnutTokens.knobFillColor, const Color(0xFF3D2719));
      expect(classicWalnutTokens.knobBorderColor, const Color(0xFF5A432F));

      final classicEbonyTokens = await pumpAndInspect(
        InkDiaryTheme.forDarkPalette(DarkAtmospherePaletteId.classicEbony),
      );
      expect(
        classicEbonyTokens.gradientColors,
        equals(const [Color(0xFF9E2E22), Color(0xFF7A1F16), Color(0xFF5E150E)]),
      );
      expect(classicEbonyTokens.borderColor, const Color(0xFF8B6B3E));
      expect(classicEbonyTokens.innerBorderColor, const Color(0x4DD25447).withValues(alpha: 0.35));
      expect(classicEbonyTokens.shadowColor, const Color(0x8C000000));
      expect(classicEbonyTokens.textColor, const Color(0xFFFFF9F2));
      expect(classicEbonyTokens.iconColor, const Color(0xFFFFF9F2));
      expect(classicEbonyTokens.knobFillColor, const Color(0xFF1C140F));
      expect(classicEbonyTokens.knobBorderColor, const Color(0xFF8B6B3E));

      expect(yunhaoDayTokens.gradientColors, isNot(equals(classicWalnutTokens.gradientColors)));
      expect(yunhaoNightTokens.gradientColors, isNot(equals(classicEbonyTokens.gradientColors)));
      expect(yunhaoDayTokens.borderColor, isNot(equals(yunhaoNightTokens.borderColor)));
      expect(classicWalnutTokens.borderColor, isNot(equals(classicEbonyTokens.borderColor)));
    });
  });
}
