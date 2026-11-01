import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
        find.bySemanticsLabel('落款朱砂印: 诗书自娱'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
