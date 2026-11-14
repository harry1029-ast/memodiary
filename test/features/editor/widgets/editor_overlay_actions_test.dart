import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/services/thought_spark_service.dart';
import 'package:memodiary/features/editor/widgets/editor_overlay_actions.dart';

void main() {
  group('EditorOverlayActions Thought Spark', () {
    testWidgets('handleShuffleSpark shows SnackBar and triggers onAdoptPrompt on action tap', (tester) async {
      final sparkService = ThoughtSparkService();
      String? adoptedPrompt;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  EditorOverlayActions.handleShuffleSpark(
                    context: context,
                    thoughtSparkService: sparkService,
                    onAdoptPrompt: (prompt) => adoptedPrompt = prompt,
                  );
                },
                child: const Text('shuffle'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('shuffle'));
      await tester.pumpAndSettle();

      final expectedSpark = ThoughtSparkService.sparks[1];
      expect(find.textContaining(expectedSpark.localizedPrompt), findsOneWidget);
      await tester.tap(find.text('由此题落墨'));
      await tester.pumpAndSettle();

      expect(adoptedPrompt, equals(expectedSpark.localizedPrompt));
    });

    test('handleInsertPrompt inserts blockQuote prompt and invokes onStateChanged', () {
      final controller = QuillController.basic();
      addTearDown(controller.dispose);
      var stateChangedCount = 0;

      EditorOverlayActions.handleInsertPrompt(
        controller: controller,
        prompt: '今天哪顿饭让你感到治愈？',
        onStateChanged: () => stateChangedCount++,
      );

      expect(stateChangedCount, 1);
      expect(
        controller.document.toPlainText(),
        equals('【灵感拾遗】今天哪顿饭让你感到治愈？\n\n'),
      );
      final ops = controller.document.toDelta().toList();
      expect(
        ops.any((op) => op.attributes?[Attribute.blockQuote.key] == Attribute.blockQuote.value),
        isTrue,
      );
    });
  });
}
