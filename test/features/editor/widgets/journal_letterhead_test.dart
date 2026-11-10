import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/models/letterhead_data.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';
import 'package:memodiary/features/editor/widgets/lunar_date_seal.dart';

import '../../../helpers/real_cjk_font.dart';

void main() {
  group('JournalLetterhead Widget Tests', () {
    late TextEditingController titleController;
    late DateTime testDate;
    int? selectedMood;
    String? selectedWeather;

    setUp(() {
      titleController = TextEditingController(text: 'Initial Reverie');
      testDate = DateTime(2026, 11, 10, 14, 30);
      selectedMood = 4; // 怡然
      selectedWeather = 'sunny'; // 晴明
    });

    tearDown(() {
      titleController.dispose();
    });

    Widget buildTestWidget({
      double width = 360,
      double textScale = 1.0,
      double rowHeight = 24,
      DateTime? entryDate,
      ValueChanged<DateTime>? onDateChanged,
      ValueChanged<int?>? onMoodChanged,
      ValueChanged<String?>? onWeatherChanged,
    }) {
      return MaterialApp(
        theme: InkDiaryTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: JournalLetterhead(
                  rowHeight: rowHeight,
                  data: LetterheadData.resolve(
                    entryDate: entryDate ?? testDate,
                    mood: selectedMood,
                    weather: selectedWeather,
                  ),
                  titleController: titleController,
                  onDateChanged: onDateChanged ?? (_) {},
                  onMoodChanged: onMoodChanged ?? (_) {},
                  onWeatherChanged: onWeatherChanged ?? (_) {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders seal, both date lines, charms and the title field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('letterhead_date_seal')), findsOneWidget);
      expect(find.text('2026年11月10日 周二'), findsOneWidget);
      expect(find.text('十月初二 · 立冬'), findsOneWidget);
      expect(find.byKey(const Key('letterhead_weather_charm')), findsOneWidget);
      expect(find.byKey(const Key('letterhead_mood_charm')), findsOneWidget);
      expect(find.text('Initial Reverie'), findsOneWidget);
    });

    testWidgets('seal reads the right column first: year on the right, month on the left', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final seal = find.byKey(const Key('letterhead_date_seal'));
      expect(find.descendant(of: seal, matching: find.text('丙')), findsOneWidget);
      expect(find.descendant(of: seal, matching: find.text('午')), findsOneWidget);
      expect(find.descendant(of: seal, matching: find.text('孟')), findsOneWidget);
      expect(find.descendant(of: seal, matching: find.text('冬')), findsOneWidget);

      expect(tester.getCenter(find.descendant(of: seal, matching: find.text('丙'))).dx,
          greaterThan(tester.getCenter(find.descendant(of: seal, matching: find.text('孟'))).dx));
      expect(tester.getCenter(find.descendant(of: seal, matching: find.text('午'))).dx,
          greaterThan(tester.getCenter(find.descendant(of: seal, matching: find.text('冬'))).dx));
      // Characters read top to bottom within a column.
      expect(tester.getCenter(find.descendant(of: seal, matching: find.text('丙'))).dy,
          lessThan(tester.getCenter(find.descendant(of: seal, matching: find.text('午'))).dy));
    });

    testWidgets('out-of-range dates show only the year on the seal and no lunar line', (tester) async {
      await tester.pumpWidget(buildTestWidget(entryDate: DateTime(1850, 6, 1)));
      await tester.pumpAndSettle();

      final seal = find.byKey(const Key('letterhead_date_seal'));
      expect(find.descendant(of: seal, matching: find.text('庚')), findsOneWidget);
      expect(find.descendant(of: seal, matching: find.text('戌')), findsOneWidget);
      expect(find.byKey(const Key('letterhead_lunar_line')), findsNothing);
      expect(find.text('1850年6月1日 周六'), findsOneWidget);
    });

    testWidgets('date lines are at least 13sp and never truncate with an ellipsis', (tester) async {
      await tester.pumpWidget(buildTestWidget(width: 320));
      await tester.pumpAndSettle();

      for (final line in [find.text('2026年11月10日 周二'), find.text('十月初二 · 立冬')]) {
        final text = tester.widget<Text>(line);
        expect(text.style!.fontSize, greaterThanOrEqualTo(13));
        expect(text.overflow, isNot(TextOverflow.ellipsis));
      }
    });

    testWidgets('drops the solar term first when the lunar line does not fit', (tester) async {
      // Seal 44 + charms 2 x 44 + gaps leave about 80px for the centre column.
      await tester.pumpWidget(buildTestWidget(width: 230));
      await tester.pumpAndSettle();

      expect(find.text('十月初二 · 立冬'), findsNothing);
      expect(find.text('十月初二'), findsOneWidget);
      expect(find.textContaining('2026年11月10日'), findsOneWidget);
    });

    testWidgets('clamps text scale at 1.3 and keeps the solar date whole', (tester) async {
      await tester.pumpWidget(buildTestWidget(width: 320, textScale: 3.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final dateText = tester.widget<Text>(find.text('2026年11月10日 周二'));
      expect(dateText.style!.fontSize, greaterThanOrEqualTo(13));
      final renderedHeight = tester.getSize(find.text('2026年11月10日 周二')).height;
      // 13sp * 1.3 clamp * ~1.4 line height; an unclamped 3.0 scale would exceed 54.
      expect(renderedHeight, lessThan(34));
    });

    group('four-row spacing', () {
      // Row heights the app allows: 12sp + 6 up to the largest template font.
      const rowHeights = [18.0, 24.0, 27.0, 48.0];

      for (final rowHeight in rowHeights) {
        for (final textScale in [1.0, 1.3, 3.0]) {
          testWidgets('is exactly 4 rows with nothing overlapping at row $rowHeight, scale $textScale',
              (tester) async {
            await tester.pumpWidget(buildTestWidget(rowHeight: rowHeight, textScale: textScale));
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
            final box = tester.getRect(find.byType(JournalLetterhead));
            expect(box.height, equals(4 * rowHeight));

            final title = tester.getRect(find.byType(TextField));
            final solar = tester.getRect(find.byKey(const Key('letterhead_solar_line')));
            final lunar = tester.getRect(find.byKey(const Key('letterhead_lunar_line')));
            // The title sits on the bottom row; the date lines stay above it.
            expect(title.bottom, closeTo(box.bottom, 0.5));
            expect(title.bottom, lessThanOrEqualTo(box.bottom + 0.01));
            expect(solar.top, greaterThanOrEqualTo(box.top - 0.01));
            expect(solar.bottom, lessThanOrEqualTo(lunar.top + 0.01));
            expect(lunar.bottom, lessThanOrEqualTo(title.top + 0.01));
            if (title.height <= rowHeight) {
              expect(title.top, greaterThanOrEqualTo(box.bottom - rowHeight - 0.01));
            }
            for (final charm in const ['letterhead_weather_charm', 'letterhead_mood_charm']) {
              final charmRect = tester.getRect(find.byKey(Key(charm)));
              expect(charmRect.top, greaterThanOrEqualTo(box.top - 0.01), reason: charm);
              expect(charmRect.bottom, lessThanOrEqualTo(box.bottom + 0.01), reason: charm);
            }
          });
        }
      }

      testWidgets('the title is larger and bolder than both muted date lines', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final titleStyle = tester.widget<TextField>(find.byType(TextField)).style!;
        final solarStyle = tester.widget<Text>(find.byKey(const Key('letterhead_solar_line'))).style!;
        final lunarStyle = tester.widget<Text>(find.byKey(const Key('letterhead_lunar_line'))).style!;
        expect(titleStyle.fontSize!, greaterThanOrEqualTo(solarStyle.fontSize! + 5));
        expect(titleStyle.fontSize!, greaterThanOrEqualTo(lunarStyle.fontSize! + 5));
        expect(titleStyle.fontWeight, FontWeight.bold);
        expect(solarStyle.fontSize, lessThanOrEqualTo(14));
        expect(lunarStyle.fontSize, lessThanOrEqualTo(14));
      });

      testWidgets('about 12px separates the seal from the text', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final sealRight = tester.getCenter(find.byKey(const Key('letterhead_date_seal'))).dx +
            LunarDateSeal.kSealSize / 2;
        final textLeft = tester.getTopLeft(find.byKey(const Key('letterhead_solar_line'))).dx;
        expect(textLeft - sealRight, closeTo(12, 1.0));
        expect(tester.getTopLeft(find.byType(TextField)).dx, closeTo(textLeft, 0.5));
      });

      // At 360dp the editor leaves the letterhead about 278px between its paper margins.
      testWidgets('shows the solar date whole and unscaled in 278px in a real CJK font',
          skip: realCjkFontPath == null, (tester) async {
        await loadRealCjkFont(tester, InkDiaryTheme.fontKaiti);

        await tester.pumpWidget(buildTestWidget(width: 278));
        await tester.pumpAndSettle();

        final solar = find.byKey(const Key('letterhead_solar_line'));
        // getRect applies the FittedBox transform, so a scaled line is narrower
        // than its laid-out size.
        expect(tester.getRect(solar).width, closeTo(tester.getSize(solar).width, 0.01));
        // Proves the real font is in use: Ahem would be 14 * 13 = 182px wide.
        expect(tester.getSize(solar).width, lessThan(14 * 13));
        expect(find.byKey(const Key('letterhead_lunar_line')), findsOneWidget);
      });
    });

    testWidgets('typing into title field updates controller', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final titleFinder = find.byType(TextField);
      expect(titleFinder, findsOneWidget);

      await tester.enterText(titleFinder, 'Autumn Breeze at Dusk');
      await tester.pump();

      expect(titleController.text, equals('Autumn Breeze at Dusk'));
    });

    testWidgets('seal and charms are 44x44 targets', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      for (final key in const [
        'letterhead_date_seal_target',
        'letterhead_weather_charm_target',
        'letterhead_mood_charm_target',
      ]) {
        final size = tester.getSize(find.byKey(Key(key)));
        expect(size.width, greaterThanOrEqualTo(44), reason: key);
        expect(size.height, greaterThanOrEqualTo(44), reason: key);
      }
    });

    testWidgets('charm text is at least 12px and set vertically', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final charm = find.byKey(const Key('letterhead_mood_charm'));
      final labelCharacter = find.descendant(of: charm, matching: find.text('怡'));
      expect(labelCharacter, findsOneWidget);
      expect(tester.widget<Text>(labelCharacter).style!.fontSize, greaterThanOrEqualTo(12));
      expect(find.descendant(of: charm, matching: find.text('🙂')), findsOneWidget);
      expect(tester.getCenter(find.descendant(of: charm, matching: find.text('怡'))).dy,
          lessThan(tester.getCenter(find.descendant(of: charm, matching: find.text('然'))).dy));
    });

    testWidgets('tapping the seal opens the date picker and reports the new date', (tester) async {
      DateTime? updatedDate;
      await tester.pumpWidget(buildTestWidget(onDateChanged: (date) => updatedDate = date));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('letterhead_date_seal_target')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('12'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(updatedDate, isNotNull);
      expect(updatedDate!.year, 2026);
      expect(updatedDate!.month, 11);
      expect(updatedDate!.day, 12);
    });

    testWidgets('tapping the mood charm opens the picker and triggers callback', (tester) async {
      int? updatedMood;
      await tester.pumpWidget(buildTestWidget(onMoodChanged: (mood) => updatedMood = mood));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('letterhead_mood_charm_target')));
      await tester.pumpAndSettle();
      expect(find.textContaining('心境感怀'), findsOneWidget);

      await tester.tap(find.text('欢欣'));
      await tester.pumpAndSettle();
      expect(updatedMood, equals(5));
    });

    testWidgets('tapping the weather charm opens the picker and triggers callback', (tester) async {
      String? updatedWeather;
      await tester.pumpWidget(buildTestWidget(onWeatherChanged: (weather) => updatedWeather = weather));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('letterhead_weather_charm_target')));
      await tester.pumpAndSettle();
      expect(find.textContaining('天候气象'), findsOneWidget);

      await tester.tap(find.text('润雨'));
      await tester.pumpAndSettle();
      expect(updatedWeather, equals('rainy'));
    });

    testWidgets('exposes scoped semantics for the seal, date block and each charm', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('岁次丙午 孟冬初二，轻触修改日期'), findsOneWidget);
      expect(find.bySemanticsLabel('2026年11月10日 周二，农历十月初二，立冬'), findsOneWidget);
      expect(find.bySemanticsLabel('天气晴明，轻触修改'), findsOneWidget);
      expect(find.bySemanticsLabel('心情怡然，轻触修改'), findsOneWidget);
      handle.dispose();
    });
  });
}
