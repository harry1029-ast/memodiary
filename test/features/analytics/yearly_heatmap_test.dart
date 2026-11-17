import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/analytics/screens/analytics_dashboard_screen.dart';
import 'package:memodiary/features/analytics/services/analytics_service.dart';
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
      expect(find.text('少'), findsOneWidget);
      expect(find.text('多'), findsOneWidget);
      expect(find.text('Less'), findsNothing);
      expect(find.text('More'), findsNothing);
    });

    testWidgets('AnalyticsDashboardScreen loads database metrics and renders plain Chinese labels without English subtitles', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      await db.entriesDao.createEntry(
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

      expect(find.text('写作统计'), findsOneWidget);
      expect(find.text('总篇数'), findsOneWidget);
      expect(find.text('总字数'), findsOneWidget);
      expect(find.text('当前连续写作'), findsOneWidget);
      expect(find.text('最长连续写作'), findsOneWidget);
      expect(find.text('分享'), findsOneWidget);
      expect(find.text('年度写作热力图'), findsOneWidget);
      expect(find.text('心情分布'), findsOneWidget);

      expect(find.text('Writing Analytics'), findsNothing);
      expect(find.text('Total Entries'), findsNothing);
      expect(find.text('Words / Chars'), findsNothing);
      expect(find.text('Yearly Writing Heatmap (52 Weeks)'), findsNothing);
      expect(find.text('Mood Distribution'), findsNothing);
    });

    test('AnalyticsDashboardScreen.formatShareSummary formats plain Chinese stats summary', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'share_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('日记'),
          contentDelta: '[{"insert":"今天开心\\n"}]',
          plainText: '今天开心',
          entryDate: DateTime(2026, 10, 18, 9, 0),
          mood: const Value(4),
        ),
      );

      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'share_2',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('续记'),
          contentDelta: '[{"insert":"晴天散步\\n"}]',
          plainText: '晴天散步',
          entryDate: DateTime(2026, 10, 17, 9, 0),
          mood: const Value(5),
        ),
      );

      // Verify share summary builder directly via computed stats
      final stats = await AnalyticsService.computeStats(
        db,
        referenceToday: DateTime(2026, 10, 18),
      );
      final summary = AnalyticsDashboardScreen.formatShareSummary(stats);
      expect(summary, contains('写作统计'));
      expect(summary, contains('总篇数：2 篇'));
      expect(summary, contains('总字数：12 字'));
      expect(summary, contains('当前连续写作：2 天'));
      expect(summary, contains('最长连续写作：2 天'));
      expect(summary, isNot(contains('研墨统计')));
      expect(summary, isNot(contains('挥毫字数')));
    });
  });
}

