import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/scroll_roller_fab.dart';

void main() {
  group('ScrollRollerFab Widget Tests', () {
    testWidgets('ScrollRollerFab renders unfurled state with label and icon', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Center(
              child: ScrollRollerFab(
                key: const Key('test_scroll_fab'),
                isRolledUp: false,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('test_scroll_fab')), findsOneWidget);
      expect(find.text('挥毫落墨'), findsOneWidget);
      expect(find.text('Write Diary'), findsOneWidget);
      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('test_scroll_fab')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('ScrollRollerFab renders compact rolled-up token when isRolledUp is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Center(
              child: ScrollRollerFab(
                key: const Key('test_scroll_fab_compact'),
                isRolledUp: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('test_scroll_fab_compact')), findsOneWidget);
      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
      // In rolled-up state, text is collapsed
      expect(find.text('挥毫落墨'), findsNothing);
    });
  });
}

