import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/atmosphere_theme_models.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/begonia_plaque_button.dart';
import 'package:memodiary/core/theme/widgets/cinnabar_seal_badge.dart';
import 'package:memodiary/core/theme/widgets/octagonal_medallion_button.dart';

void main() {
  group('Classical Buttons Widget Tests', () {
    testWidgets('OctagonalMedallionButton renders with icon, tooltip, and fires onPressed',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Center(
              child: OctagonalMedallionButton(
                key: const Key('medallion_test_button'),
                icon: Icons.calendar_view_week_rounded,
                tooltip: '周志复盘',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('medallion_test_button')), findsOneWidget);
      expect(find.byIcon(Icons.calendar_view_week_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('medallion_test_button')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('BegoniaPlaqueButton renders label, leading/trailing icons and fires onTap',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Center(
              child: BegoniaPlaqueButton(
                key: const Key('begonia_test_button'),
                label: '默认册卷',
                leading: const Icon(Icons.auto_stories_outlined, size: 14),
                trailing: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('begonia_test_button')), findsOneWidget);
      expect(find.text('默认册卷'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('begonia_test_button')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('CinnabarSealBadge preserves precious sealCinnabar in yunhaoNight instead of amber',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.dark,
          home: const Scaffold(
            body: Center(
              child: CinnabarSealBadge(text: '珍藏'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CinnabarSealBadge),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFFD16B62)));
    });

    testWidgets('BegoniaPlaqueButton accent resolves AtmospherePalette tallyFeatured colors and OctagonalMedallionButton supports overrides',
        (tester) async {
      const customGradient = LinearGradient(
        colors: [Color(0xFF123456), Color(0xFF654321)],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.forDarkPalette(DarkAtmospherePaletteId.blossomLantern),
          home: const Scaffold(
            body: Column(
              children: [
                BegoniaPlaqueButton(label: '筛选', isAccent: true),
                OctagonalMedallionButton(
                  icon: Icons.search_rounded,
                  gradient: customGradient,
                  borderColor: Color(0xFFABCDEF),
                  bevelColor: Color(0xFF112233),
                ),
              ],
            ),
          ),
        ),
      );

      final plaqueContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(BegoniaPlaqueButton),
          matching: find.byType(Container),
        ),
      );
      final plaqueDec = plaqueContainer.decoration! as ShapeDecoration;
      expect(
        (plaqueDec.gradient! as LinearGradient).colors,
        equals(const [Color(0xFFC76975), Color(0xFF873E49)]),
      );

      final medallionContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(OctagonalMedallionButton),
          matching: find.byType(Container),
        ),
      );
      final medallionDec = medallionContainer.decoration! as ShapeDecoration;
      expect(medallionDec.gradient, equals(customGradient));
    });
  });
}

