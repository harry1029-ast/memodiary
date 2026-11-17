import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/widgets/typography_sheet.dart';

void main() {
  group('TypographyCatalog & TypographySheet plain Chinese font names', () {
    test('every FontOption exposes a plain Chinese displayName', () {
      expect(TypographyCatalog.findById('system').displayName, '系统默认');
      expect(TypographyCatalog.findById('serif').displayName, '系统衬线');
      expect(TypographyCatalog.findById('sans-serif').displayName, '系统无衬线');
      expect(TypographyCatalog.findById('monospace').displayName, '等宽字体');
      expect(TypographyCatalog.findById('noto_serif').displayName, '思源宋体');
      expect(TypographyCatalog.findById('ma_shan_zheng').displayName, '楷体');

      for (final option in TypographyCatalog.options) {
        expect(option.displayName, isNotEmpty);
        expect(option.displayName, isNot('System Default'));
        expect(option.displayName, isNot('Ma Shan Zheng'));
      }
    });

    testWidgets('TypographySheet renders plain Chinese font names instead of raw English names',
        (tester) async {
      TypographySettings? latest;

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: TypographySheet(
              settings: const TypographySettings(),
              onChanged: (updated) => latest = updated,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('字体排版'), findsOneWidget);
      expect(find.text('系统默认'), findsOneWidget);
      expect(find.text('系统衬线'), findsOneWidget);
      expect(find.text('System Default'), findsNothing);
      expect(find.text('Ma Shan Zheng'), findsNothing);

      // Scroll horizontal list to reveal Noto Serif and select it.
      final notoFinder = find.byKey(const Key('typography_font_noto_serif'));
      await tester.scrollUntilVisible(
        notoFinder,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('思源宋体'), findsOneWidget);

      await tester.tap(notoFinder);
      await tester.pumpAndSettle();

      expect(latest, isNotNull);
      expect(latest!.fontId, 'noto_serif');
    });
  });
}
