import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/scroll_roller_fab.dart';

void main() {
  group('ScrollRollerFab Widget Tests', () {
    testWidgets('ScrollRollerFab renders its label and icon', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Center(
              child: ScrollRollerFab(
                key: const Key('test_scroll_fab'),
                label: '写日记',
                icon: Icons.brush_rounded,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('test_scroll_fab')), findsOneWidget);
      expect(find.text('写日记'), findsOneWidget);
      expect(find.text('Write Diary'), findsNothing);
      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('test_scroll_fab')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}

