import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/auth_service.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';
import 'package:memodiary/features/timeline/screens/entry_detail_screen.dart';
import 'package:memodiary/features/timeline/widgets/entry_summary_card.dart';

void main() {
  group('Single-Entry Lock & Schema v2 Migration Tests', () {
    test('Fresh schema v2 database supports lockEntry and unlockEntryPermanently', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      final auth = AuthService();
      final pinHash = auth.hashEntryPin('2580');

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_lock_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Secret Diary'),
          contentDelta: '[{"insert":"Top secret body\\n"}]',
          plainText: 'Top secret body',
          entryDate: DateTime(2026, 5, 10),
        ),
      );

      var fetched = await db.getEntryById('entry_lock_1');
      expect(fetched, isNotNull);
      expect(fetched!.isLocked, isFalse);
      expect(fetched.entryPinHash, isNull);

      // Lock entry with PIN hash
      await db.lockEntry('entry_lock_1', pinHash: pinHash);
      fetched = await db.getEntryById('entry_lock_1');
      expect(fetched!.isLocked, isTrue);
      expect(fetched.entryPinHash, equals(pinHash));
      expect(auth.verifyEntryPin('2580', fetched.entryPinHash!), isTrue);
      expect(auth.verifyEntryPin('9999', fetched.entryPinHash!), isFalse);

      // Permanently unlock entry
      await db.unlockEntryPermanently('entry_lock_1');
      fetched = await db.getEntryById('entry_lock_1');
      expect(fetched!.isLocked, isFalse);
      expect(fetched.entryPinHash, isNull);
    });

    test('Simulated v1 -> v2 schema migration adds is_locked and entry_pin_hash without data loss', () async {
      final executor = NativeDatabase.memory(
        setup: (rawDb) {
          // Simulate a pre-existing v1 database with user_version = 1
          rawDb.execute('''
            CREATE TABLE templates (
              id TEXT NOT NULL PRIMARY KEY,
              name TEXT NOT NULL,
              background_type TEXT NOT NULL,
              background_value TEXT NOT NULL,
              font_family TEXT NOT NULL,
              line_spacing REAL NOT NULL DEFAULT 1.5,
              margin_horizontal REAL NOT NULL DEFAULT 16.0,
              is_custom INTEGER NOT NULL DEFAULT 0
            );
          ''');
          rawDb.execute('''
            CREATE TABLE notebooks (
              id TEXT NOT NULL PRIMARY KEY,
              title TEXT NOT NULL,
              default_template_id TEXT NOT NULL REFERENCES templates (id),
              created_at INTEGER NOT NULL
            );
          ''');
          rawDb.execute('''
            CREATE TABLE entries (
              id TEXT NOT NULL PRIMARY KEY,
              notebook_id TEXT NOT NULL REFERENCES notebooks (id),
              template_id TEXT NOT NULL REFERENCES templates (id),
              title TEXT,
              content_delta TEXT NOT NULL,
              plain_text TEXT NOT NULL,
              entry_date INTEGER NOT NULL,
              mood INTEGER,
              weather TEXT,
              is_weekly_review INTEGER NOT NULL DEFAULT 0,
              week_number INTEGER,
              unlock_at INTEGER,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              is_deleted INTEGER NOT NULL DEFAULT 0
            );
          ''');
          rawDb.execute('''
            CREATE TABLE media_attachments (
              id TEXT NOT NULL PRIMARY KEY,
              entry_id TEXT NOT NULL REFERENCES entries (id),
              media_type TEXT NOT NULL,
              relative_path TEXT NOT NULL,
              thumbnail_path TEXT,
              ocr_text TEXT,
              created_at INTEGER NOT NULL
            );
          ''');
          rawDb.execute('''
            CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(
              entry_id UNINDEXED,
              title,
              segmented_plain_text
            );
          ''');
          rawDb.execute('''
            INSERT INTO templates (id, name, background_type, background_value, font_family)
            VALUES ('template_minimalist_white', 'Minimalist White', 'color', '#FFFFFF', 'System Sans');
          ''');
          rawDb.execute('''
            INSERT INTO notebooks (id, title, default_template_id, created_at)
            VALUES ('notebook_default', 'My Diary', 'template_minimalist_white', 1700000000);
          ''');
          rawDb.execute('''
            INSERT INTO entries (id, notebook_id, template_id, title, content_delta, plain_text, entry_date, created_at, updated_at)
            VALUES ('legacy_v1_entry', 'notebook_default', 'template_minimalist_white', 'V1 Entry', '[{"insert":"Legacy text\\n"}]', 'Legacy text', 1700000000, 1700000000, 1700000000);
          ''');
          rawDb.execute('PRAGMA user_version = 1;');
        },
      );

      final db = AppDatabase(executor);
      addTearDown(() => db.close());

      // Trigger migration to schemaVersion 2 by querying the legacy entry
      final migratedEntry = await db.getEntryById('legacy_v1_entry');
      expect(migratedEntry, isNotNull);
      expect(migratedEntry!.title, 'V1 Entry');
      expect(migratedEntry.plainText, 'Legacy text');
      expect(migratedEntry.isLocked, isFalse);
      expect(migratedEntry.entryPinHash, isNull);

      // Verify newly added v2 columns can be updated on migrated row
      final pinHash = AuthService().hashEntryPin('1234');
      await db.lockEntry('legacy_v1_entry', pinHash: pinHash);
      final locked = await db.getEntryById('legacy_v1_entry');
      expect(locked!.isLocked, isTrue);
      expect(locked.entryPinHash, pinHash);
    });

    testWidgets('EntrySummaryCard obscures locked entry snippet and EntryDetailScreen enforces PIN barrier', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      final auth = AuthService();
      final pinHash = auth.hashEntryPin('4321');

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'locked_ui_entry',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Private Reflection'),
          contentDelta: '[{"insert":"Hidden confidential diary body\\n"}]',
          plainText: 'Hidden confidential diary body',
          entryDate: DateTime(2026, 6, 15, 10, 30),
          isLocked: const Value(true),
          entryPinHash: Value(pinHash),
        ),
      );

      final entry = (await db.getEntryById('locked_ui_entry'))!;
      final mediaService = MediaSandboxService();

      // 1. Verify EntrySummaryCard obscures snippet
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntrySummaryCard(
              item: TimelineEntryItem(entry: entry),
              mediaService: mediaService,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Private Reflection'), findsOneWidget);
      expect(find.text('🔒 This entry is locked'), findsOneWidget);
      expect(find.textContaining('Hidden confidential'), findsNothing);

      // 2. Verify EntryDetailScreen shows lock barrier until correct PIN is entered
      await tester.pumpWidget(
        MaterialApp(
          home: EntryDetailScreen(
            entry: entry,
            database: db,
            mediaService: mediaService,
            authService: auth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This Diary Entry is Locked'), findsOneWidget);
      expect(find.text('Private Reflection'), findsNothing);

      // Enter wrong PIN
      await tester.enterText(find.byKey(const Key('entry_unlock_pin_field')), '0000');
      await tester.tap(find.byKey(const Key('entry_unlock_submit_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Incorrect PIN'), findsOneWidget);
      expect(find.text('This Diary Entry is Locked'), findsOneWidget);

      // Enter correct PIN
      await tester.enterText(find.byKey(const Key('entry_unlock_pin_field')), '4321');
      await tester.tap(find.byKey(const Key('entry_unlock_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.text('This Diary Entry is Locked'), findsNothing);
      expect(find.text('Private Reflection'), findsOneWidget);
    });
  });
}

