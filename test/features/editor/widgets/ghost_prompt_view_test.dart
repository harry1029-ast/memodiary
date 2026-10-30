import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/models/thought_spark.dart';
import 'package:memodiary/features/editor/widgets/ghost_prompt_view.dart';

void main() {
  group('GhostPromptView Widget Tests', () {
    late QuillController emptyController;
    late QuillController filledController;
    const testSpark = ThoughtSpark(
      id: 'test_1',
      promptZh: '今天最让你心动的瞬间是什么？',
      promptEn: 'What was your favorite moment today?',
      category: 'reflection',
    );

    setUp(() {
      emptyController = QuillController.basic();
      filledController = QuillController.basic()..document.insert(0, 'Some thoughts written here\n');
    });

    tearDown(() {
      emptyController.dispose();
      filledController.dispose();
    });

    Widget buildTestWidget({
      required QuillController controller,
      ThoughtSpark? spark,
      VoidCallback? onAdoptPrompt,
      VoidCallback? onShuffle,
    }) {
      return MaterialApp(
        theme: InkDiaryTheme.light,
        home: Scaffold(
          body: GhostPromptView(
            controller: controller,
            spark: spark ?? testSpark,
            onAdoptPrompt: onAdoptPrompt ?? () {},
            onShuffle: onShuffle,
          ),
        ),
      );
    }

    testWidgets('renders prompt quote and adopt button when document is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(controller: emptyController));
      await tester.pumpAndSettle();

      expect(find.textContaining('今天最让你心动的瞬间是什么？'), findsOneWidget);
      expect(find.textContaining('由此题落墨'), findsOneWidget);
    });

    testWidgets('renders nothing when document contains text', (tester) async {
      await tester.pumpWidget(buildTestWidget(controller: filledController));
      await tester.pumpAndSettle();

      expect(find.textContaining('今天最让你心动的瞬间是什么？'), findsNothing);
      expect(find.textContaining('由此题落墨'), findsNothing);
    });

    testWidgets('tapping adopt button invokes onAdoptPrompt callback', (tester) async {
      bool adopted = false;
      await tester.pumpWidget(buildTestWidget(
        controller: emptyController,
        onAdoptPrompt: () => adopted = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('由此题落墨'));
      await tester.pump();

      expect(adopted, isTrue);
    });

    testWidgets('tapping shuffle button invokes onShuffle callback', (tester) async {
      bool shuffled = false;
      await tester.pumpWidget(buildTestWidget(
        controller: emptyController,
        onShuffle: () => shuffled = true,
      ));
      await tester.pumpAndSettle();

      final shuffleBtn = find.byIcon(Icons.refresh);
      expect(shuffleBtn, findsOneWidget);

      await tester.tap(shuffleBtn);
      await tester.pump();

      expect(shuffled, isTrue);
    });
  });
}
