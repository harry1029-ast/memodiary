import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/analytics/screens/analytics_dashboard_screen.dart';
import 'package:memodiary/features/analytics/widgets/yearly_contribution_heatmap.dart';

void main() {
  group('YearlyContributionHeatmap & AnalyticsDashboardScreen Widget Tests', () {
    testWidgets('YearlyContributionHeatmap paints 52x7 activity grid without layout overflow', (tester) async {
      final activityMap = <String, int>{
        '2026-10-18': 3,
        '2026-10-17': 2,
        '2026-10-16': 1,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: YearlyContributionHeatmap(
                dailyActivityMap: activityMap,
                referenceDate: DateTime(2026, 10, 18),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('yearly_contribution_heatmap_canvas')),
        findsOneWidget,
      );
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('AnalyticsDashboardScreen loads database metrics and renders heatmap and mood chart', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'dash_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Morning Note'),
          contentDelta: '[{"insert":"Testing analytics dashboard\\n"}]',
          plainText: 'Testing analytics dashboard',
          entryDate: DateTime(2026, 10, 18, 9, 0),
          mood: const Value(5),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AnalyticsDashboardScreen(
            database: db,
            referenceDate: DateTime(2026, 10, 18),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Writing Analytics'), findsOneWidget);
      expect(find.text('Total Entries'), findsOneWidget);
      expect(find.text('Words / Chars'), findsOneWidget);
      expect(find.text('1 days'), findsWidgets);
      expect(find.text('Yearly Writing Heatmap (52 Weeks)'), findsOneWidget);
      expect(find.text('Mood Distribution'), findsOneWidget);
    });
  });
}

