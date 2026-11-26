import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/widgets/cinnabar_signature_seal.dart';
import 'package:memodiary/features/templates/models/template_style.dart';

void main() {
  group('CinnabarSignatureSeal Tests', () {
    testWidgets('renders hidden mode as empty SizedBox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CinnabarSignatureSeal(sealStyle: SealCarvingStyle.hidden),
          ),
        ),
      );

      expect(find.byKey(const Key('cinnabar_signature_seal')), findsNothing);
    });

    testWidgets('renders zhuwen (relief) with border and default text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CinnabarSignatureSeal(
              sealStyle: SealCarvingStyle.zhuwen,
              overrideText: '心迹安放',
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('cinnabar_signature_seal')), findsOneWidget);
      expect(find.text('心'), findsOneWidget);
      expect(find.text('迹'), findsOneWidget);
      expect(find.text('安'), findsOneWidget);
      expect(find.text('放'), findsOneWidget);

      final container = tester.widget<Container>(find.byKey(const Key('cinnabar_signature_seal')));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent);
      expect(decoration.border, isNotNull);
    });

    testWidgets('renders baiwen (intaglio) with solid background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CinnabarSignatureSeal(
              sealStyle: SealCarvingStyle.baiwen,
              overrideText: '澄心',
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('cinnabar_signature_seal')), findsOneWidget);
      expect(find.text('澄'), findsOneWidget);
      expect(find.text('心'), findsOneWidget);

      final container = tester.widget<Container>(find.byKey(const Key('cinnabar_signature_seal')));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNot(Colors.transparent));
    });

    testWidgets('pads 3-character odd seal text with 印 in R-to-L order', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CinnabarSignatureSeal(
              sealStyle: SealCarvingStyle.zhuwen,
              overrideText: '拾光存',
            ),
          ),
        ),
      );

      expect(find.text('拾'), findsOneWidget);
      expect(find.text('光'), findsOneWidget);
      expect(find.text('存'), findsOneWidget);
      expect(find.text('印'), findsOneWidget);
    });

    testWidgets('provides accessible Semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CinnabarSignatureSeal(
              sealStyle: SealCarvingStyle.zhuwen,
              overrideText: '诗书自娱',
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('签名印章：诗书自娱'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('uses tokens.sealCinnabar rather than accent cinnabar in yunhaoDay and yunhaoNight', (tester) async {
      for (final (theme, expectedSealCinnabar, expectedGround) in [
        (InkDiaryTheme.light, const Color(0xFFC24D43), InkDiaryTokens.light.xuanGround),
        (InkDiaryTheme.dark, const Color(0xFFD16B62), InkDiaryTokens.dark.xuanGround),
      ]) {
        // Zhuwen (relief): transparent background, sealCinnabar border and text
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: CinnabarSignatureSeal(
                sealStyle: SealCarvingStyle.zhuwen,
                overrideText: '心迹安放',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final zhuwenContainer = tester.widget<Container>(
          find.byKey(const Key('cinnabar_signature_seal')),
        );
        final zhuwenDecoration = zhuwenContainer.decoration! as BoxDecoration;
        expect(zhuwenDecoration.color, Colors.transparent);
        expect((zhuwenDecoration.border! as Border).top.color, expectedSealCinnabar);
        expect(tester.widget<Text>(find.text('心')).style?.color, expectedSealCinnabar);

        // Baiwen (intaglio): solid sealCinnabar background and border, xuanGround text
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: CinnabarSignatureSeal(
                sealStyle: SealCarvingStyle.baiwen,
                overrideText: '心迹安放',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final baiwenContainer = tester.widget<Container>(
          find.byKey(const Key('cinnabar_signature_seal')),
        );
        final baiwenDecoration = baiwenContainer.decoration! as BoxDecoration;
        expect(baiwenDecoration.color, expectedSealCinnabar);
        expect((baiwenDecoration.border! as Border).top.color, expectedSealCinnabar);
        expect(tester.widget<Text>(find.text('心')).style?.color, expectedGround);
      }
    });
  });
}
