import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';

void main() {
  group('JournalLetterhead Widget Tests', () {
    late TextEditingController titleController;
    late DateTime testDate;
    int? selectedMood;
    String? selectedWeather;

    setUp(() {
      titleController = TextEditingController(text: 'Initial Reverie');
      testDate = DateTime(2026, 10, 30, 14, 30);
      selectedMood = 4; // 怡然
      selectedWeather = 'sunny'; // 晴明
    });

    tearDown(() {
      titleController.dispose();
    });

    Widget buildTestWidget({
      ValueChanged<DateTime>? onDateChanged,
      ValueChanged<int?>? onMoodChanged,
      ValueChanged<String?>? onWeatherChanged,
    }) {
      return MaterialApp(
        theme: InkDiaryTheme.light,
        home: Scaffold(
          body: JournalLetterhead(
            entryDate: testDate,
            mood: selectedMood,
            weather: selectedWeather,
            titleController: titleController,
            onDateChanged: onDateChanged ?? (_) {},
            onMoodChanged: onMoodChanged ?? (_) {},
            onWeatherChanged: onWeatherChanged ?? (_) {},
          ),
        ),
      );
    }

    testWidgets('renders date, mood emblem, weather emblem, and title field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Check date and solar term
      expect(find.textContaining('2026年10月30日'), findsOneWidget);
      expect(find.textContaining('霜降'), findsOneWidget);

      // Check mood emblem
      expect(find.text('🙂'), findsOneWidget);
      expect(find.text('怡然'), findsOneWidget);

      // Check weather emblem
      expect(find.text('晴明'), findsOneWidget);

      // Check title field
      expect(find.text('Initial Reverie'), findsOneWidget);
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

    testWidgets('tapping mood emblem opens picker and triggers callback', (tester) async {
      int? updatedMood;
      await tester.pumpWidget(buildTestWidget(
        onMoodChanged: (mood) => updatedMood = mood,
      ));
      await tester.pumpAndSettle();

      // Tap mood emblem
      await tester.tap(find.text('怡然'));
      await tester.pumpAndSettle();

      // Modal bottom sheet opens
      expect(find.textContaining('心境感怀'), findsOneWidget);

      // Tap '欢欣' (value 5)
      await tester.tap(find.text('欢欣'));
      await tester.pumpAndSettle();

      expect(updatedMood, equals(5));
    });

    testWidgets('tapping weather emblem opens picker and triggers callback', (tester) async {
      String? updatedWeather;
      await tester.pumpWidget(buildTestWidget(
        onWeatherChanged: (weather) => updatedWeather = weather,
      ));
      await tester.pumpAndSettle();

      // Tap weather emblem
      await tester.tap(find.text('晴明'));
      await tester.pumpAndSettle();

      // Modal bottom sheet opens
      expect(find.textContaining('天候气象'), findsOneWidget);

      // Tap '润雨'
      await tester.tap(find.text('润雨'));
      await tester.pumpAndSettle();

      expect(updatedWeather, equals('rainy'));
    });
  });
}
