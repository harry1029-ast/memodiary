import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/wusilan_scroll_card.dart';

void main() {
  group('WusilanScrollCard Widget Tests', () {
    testWidgets('WusilanScrollCard renders child content with Wusilan styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Center(
              child: WusilanScrollCard(
                child: const Text('静坐研墨，心绪澄明'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('静坐研墨，心绪澄明'), findsOneWidget);
      expect(find.byType(WusilanScrollCard), findsOneWidget);
    });

    testWidgets('WusilanScrollCard supports collapsible toggle handle', (tester) async {
      bool isCollapsed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return WusilanScrollCard(
                    canCollapse: true,
                    isCollapsed: isCollapsed,
                    onToggleCollapse: () {
                      setState(() {
                        isCollapsed = !isCollapsed;
                      });
                    },
                    collapsedLabel: '✦ 灵感火花 · 展开',
                    child: const Text('微小的真切幸福'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Initially expanded
      expect(find.text('微小的真切幸福'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);

      // Tap collapse handle
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pumpAndSettle();

      // Now collapsed
      expect(isCollapsed, isTrue);
      expect(find.text('✦ 灵感火花 · 展开'), findsOneWidget);
      expect(find.text('微小的真切幸福'), findsNothing);

      // Tap to expand again
      await tester.tap(find.text('✦ 灵感火花 · 展开'));
      await tester.pumpAndSettle();

      expect(isCollapsed, isFalse);
      expect(find.text('微小的真切幸福'), findsOneWidget);
    });
  });
}

