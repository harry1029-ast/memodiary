import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/begonia_plaque_button.dart';
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
  });
}

