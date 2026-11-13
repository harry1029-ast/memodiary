import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/scenery/screens/contemplation_view_screen.dart';
import 'package:memodiary/features/scenery/services/scenery_settings_service.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_scenery_card.dart';
import 'package:memodiary/features/timeline/screens/timeline_screen.dart';
import '../../helpers/mock_secure_storage.dart';

void main() {
  group('TimelineScreen Scenery Realm & Situation Detection Tests', () {
    late AppDatabase db;
    late Directory tempDir;
    late MediaSandboxService mediaService;
    late MockSecureStorage mockStorage;
    late ScenerySettingsService scenerySettings;

    setUp(() async {
      db = AppDatabase.memory();
      tempDir = Directory.systemTemp.createTempSync('timeline_realm_test_');
      mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
      mockStorage = MockSecureStorage();
      scenerySettings = ScenerySettingsService(storage: mockStorage);
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Future<void> pumpTimeline(WidgetTester tester, {double width = 800}) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: TimelineScreen(
            database: db,
            mediaService: mediaService,
            scenerySettingsService: scenerySettings,
            enableSceneryAnimation: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'newest accessible entry with indoor situation keywords resolves Indoor realm and 随文入境 badge',
      (tester) async {
        final now = DateTime.now();
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'indoor_entry_1',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('书房读书记'),
            contentDelta: jsonEncode([{'insert': '在案头泡茶静坐，窗前看书。\n'}]),
            plainText: '在案头泡茶静坐，窗前看书。',
            entryDate: now.subtract(const Duration(hours: 1)),
          ),
        );

        await pumpTimeline(tester);

        expect(find.byType(ShanshuiSceneryCard), findsOneWidget);
        expect(find.byKey(const Key('scenery_realm_badge')), findsOneWidget);
        expect(find.text('随文入境 · 雅室'), findsOneWidget);
        expect(find.text('秋 · 霜枫品茗'), findsOneWidget);
      },
    );

    testWidgets(
      'privacy boundaries: excludes soft-deleted, PIN-locked, and future Time Capsule entries from situation inference',
      (tester) async {
        final now = DateTime.now();

        // 1. Newest entry is soft-deleted with indoor keywords
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'deleted_entry',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('已删除的书房日记'),
            contentDelta: jsonEncode([{'insert': '在书房案头泡茶。\n'}]),
            plainText: '在书房案头泡茶。',
            entryDate: now,
            isDeleted: const Value(true),
          ),
        );

        // 2. Second newest is PIN-locked with indoor keywords
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'locked_entry',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('加锁的书房日记'),
            contentDelta: jsonEncode([{'insert': '在书房案头泡茶。\n'}]),
            plainText: '在书房案头泡茶。',
            entryDate: now.subtract(const Duration(minutes: 10)),
            isLocked: const Value(true),
          ),
        );

        // 3. Third newest is a future Time Capsule sealed until tomorrow
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'time_capsule_entry',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('未到期的胶囊书房日记'),
            contentDelta: jsonEncode([{'insert': '在书房案头泡茶。\n'}]),
            plainText: '在书房案头泡茶。',
            entryDate: now.subtract(const Duration(minutes: 20)),
            unlockAt: Value(now.add(const Duration(days: 1))),
          ),
        );

        // 4. Accessible entry: outdoor street market keywords
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'accessible_outdoor_entry',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('古街市集闲逛'),
            contentDelta: jsonEncode([{'insert': '街头熙熙攘攘，小摊飘香，面馆人声鼎沸。\n'}]),
            plainText: '街头熙熙攘攘，小摊飘香，面馆人声鼎沸。',
            entryDate: now.subtract(const Duration(hours: 2)),
          ),
        );

        await pumpTimeline(tester);

        // Should skip the first 3 ineligible entries and infer Outdoor realm from the 4th
        expect(find.text('随文入境 · 市井'), findsOneWidget);
        expect(find.textContaining('市'), findsAtLeast(1));
      },
    );

    testWidgets(
      'entries older than 24 hours fall back gracefully to Nature realm',
      (tester) async {
        final now = DateTime.now();

        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'old_entry',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('昨天的书房日记'),
            contentDelta: jsonEncode([{'insert': '在书房案头煮茶读书。\n'}]),
            plainText: '在书房案头煮茶读书。',
            entryDate: now.subtract(const Duration(hours: 25)),
          ),
        );

        await pumpTimeline(tester);

        // Decays to Nature realm, isJournalInferred is false
        expect(find.text('林泉'), findsOneWidget);
        expect(find.text('随文入境 · 雅室'), findsNothing);
      },
    );

    testWidgets(
      '1-tap realm switcher on card overrides inferred realm and persists via ScenerySettingsService',
      (tester) async {
        final now = DateTime.now();
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'indoor_entry',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('书房读书'),
            contentDelta: jsonEncode([{'insert': '在案头泡茶。\n'}]),
            plainText: '在案头泡茶。',
            entryDate: now.subtract(const Duration(hours: 1)),
          ),
        );

        await pumpTimeline(tester);

        // Initially inferred as Indoor
        expect(find.text('随文入境 · 雅室'), findsOneWidget);

        // Tap realm badge to open 1-tap realm switcher bottom sheet
        await tester.tap(find.byKey(const Key('scenery_realm_badge')));
        await tester.pumpAndSettle();

        // Tap Outdoor (市井)
        await tester.tap(find.byKey(const Key('scenery_realm_option_outdoor')));
        await tester.pumpAndSettle();

        // Card should now display Outdoor (市井) as manually selected
        expect(mockStorage.data['memodiary_scenery_realm_preference'], equals('outdoor'));
        expect(find.text('市井'), findsOneWidget);
        expect(find.text('随文入境 · 雅室'), findsNothing);
      },
    );

    testWidgets(
      'tapping painting canvas navigates to ContemplationViewScreen with active and real-time state',
      (tester) async {
        final now = DateTime.now();
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'indoor_entry',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('书房读书记'),
            contentDelta: jsonEncode([{'insert': '案头泡茶。\n'}]),
            plainText: '案头泡茶。',
            entryDate: now.subtract(const Duration(hours: 1)),
          ),
        );

        await pumpTimeline(tester);

        // Tap painting canvas
        await tester.tap(find.byKey(const Key('scenery_canvas_tap_target')));
        await tester.pumpAndSettle();

        // Should navigate to ContemplationViewScreen
        expect(find.byType(ContemplationViewScreen), findsOneWidget);
        // Header in ContemplationViewScreen should reflect active Indoor realm
        expect(find.textContaining('品茗'), findsOneWidget);
      },
    );
  });
}
