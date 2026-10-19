import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/import_export/services/backup_restore_service.dart';
import 'package:memodiary/features/import_export/services/date_parser_engine.dart';
import 'package:memodiary/features/import_export/services/export_service.dart';
import 'package:memodiary/features/search/services/event_suggestion_service.dart';
import 'package:memodiary/features/search/services/natural_language_search_parser.dart';

/// Custom HttpOverrides firewall that intercepts and rejects any outbound network requests.
class QuarantinedHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError('NETWORK_QUARANTINE_VIOLATION: Outbound HTTP/HTTPS requests are strictly forbidden');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Install network quarantine firewall
    HttpOverrides.global = QuarantinedHttpOverrides();
  });

  tearDownAll(() {
    // 2. HttpOverrides Hygiene: Cleanly reset to null in tearDownAll()
    HttpOverrides.global = null;
  });

  group('Privacy & Zero-Cloud Network Quarantine Audit', () {
    test('HttpOverrides firewall blocks any inadvertent network call', () async {
      expect(
        () => HttpClient().getUrl(Uri.parse('https://example.com/telemetry')),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('NETWORK_QUARANTINE_VIOLATION'),
        )),
      );
    });

    test('Core offline workflows operate without triggering network access', () async {
      final db = AppDatabase.memory();
      final tempDir =
          Directory.systemTemp.createTempSync('memodiary_quarantine_test_');

      try {
        // 1. Database CRUD & FTS5 search
        await db.createEntry(
          EntriesCompanion.insert(
            id: 'quarantine_entry_1',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Offline Entry 旅行'),
            contentDelta: jsonEncode([{'insert': 'Completely local notes.\n'}]),
            plainText: 'Completely local notes.',
            entryDate: DateTime(2026, 10, 16),
            isWeeklyReview: const Value(true),
          ),
        );

        final entries = await db.searchEntriesWithFilters(query: 'local');
        expect(entries.length, equals(1));

        // 2. Export engine formatting
        final markdown = ExportService.formatEntryToMarkdown(entries.first);
        expect(markdown, contains('Completely local notes.'));

        // 3. Document date parser
        final candidates = await DateParserEngine.parseDocumentInIsolate(
          text: '2026-10-16 10:00\nOffline parse test',
        );
        expect(candidates.length, equals(1));

        // 4. Phase 9 Natural Language Search Parser & Event Suggestion Service (100% offline)
        const parser = NaturalLanguageSearchParser();
        final parsed = parser.parse(
          '10月所有周记',
          now: DateTime(2026, 10, 18),
        );
        expect(parsed.weeklyReviewOnly, isTrue);

        final suggestionService = EventSuggestionService(db);
        final suggestions = await suggestionService.getSuggestions(
          now: DateTime(2026, 10, 18),
        );
        expect(suggestions.map((s) => s.term), contains('旅行'));

        // 5. Phase 9 Encrypted Backup & Restore Round-Trip (100% offline)
        final mediaService = MediaSandboxService(
          baseDirProvider: () async => tempDir,
        );
        final backupService = BackupRestoreService(
          database: db,
          mediaService: mediaService,
          tempDirProvider: () async => tempDir,
        );
        final mdbakFile = File('${tempDir.path}/quarantine.mdbak');
        await backupService.createBackup(
          destination: mdbakFile,
          passphrase: 'offline-secret-pass',
          pbkdf2Iterations: 1000,
        );
        final restored = await backupService.restoreBackup(
          source: mdbakFile,
          passphrase: 'offline-secret-pass',
        );
        expect(restored.entriesRestored, equals(1));
      } finally {
        await db.close();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('3. Source Manifest Targeting: android/app/src/main/AndroidManifest.xml has zero internet permission', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue, reason: 'Source AndroidManifest.xml must exist');

      final content = manifestFile.readAsStringSync();

      // Assert complete absence of internet or network-related permissions
      expect(
        content.contains('android.permission.INTERNET'),
        isFalse,
        reason: 'android.permission.INTERNET must NEVER be declared in MemoDiary',
      );
      expect(
        content.contains('android.permission.ACCESS_NETWORK_STATE'),
        isFalse,
        reason: 'android.permission.ACCESS_NETWORK_STATE must not be declared',
      );
      expect(
        content.contains('android.permission.ACCESS_WIFI_STATE'),
        isFalse,
        reason: 'android.permission.ACCESS_WIFI_STATE must not be declared',
      );

      // Verify that only local hardware permissions are declared
      expect(content.contains('android.permission.RECORD_AUDIO'), isTrue);
      expect(content.contains('android.permission.CAMERA'), isTrue);
    });

    test('iOS Info.plist maintains offline privacy descriptions and no ATS exceptions', () {
      final plistFile = File('ios/Runner/Info.plist');
      expect(plistFile.existsSync(), isTrue, reason: 'iOS Info.plist must exist');

      final content = plistFile.readAsStringSync();

      // Verify offline purpose strings
      expect(content.contains('NSMicrophoneUsageDescription'), isTrue);
      expect(content.contains('NSSpeechRecognitionUsageDescription'), isTrue);
      expect(content.contains('NSCameraUsageDescription'), isTrue);
      expect(content.contains('NSPhotoLibraryUsageDescription'), isTrue);

      // Verify no NSAllowsArbitraryLoads
      expect(
        content.contains('NSAllowsArbitraryLoads'),
        isFalse,
        reason: 'Arbitrary network loads must not be enabled',
      );
    });

    test('pubspec.yaml dependency audit: 100% free open-source with zero tracking or telemetry SDKs', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue);

      final content = pubspecFile.readAsStringSync();

      const bannedTrackers = [
        'firebase_analytics',
        'firebase_core',
        'firebase_crashlytics',
        'google_mobile_ads',
        'facebook_app_events',
        'sentry_flutter',
        'amplitude_flutter',
        'appsflyer_sdk',
        'mixpanel_flutter',
        'adjust_sdk',
      ];

      for (final banned in bannedTrackers) {
        expect(
          content.contains(banned),
          isFalse,
          reason: 'Banned telemetry/ad package "$banned" must not be present in dependencies',
        );
      }
    });

    group('v1.0.0 Release Metadata & Manifest Audit', () {
      test('pubspec.yaml declares version 1.0.0+1', () {
        final pubspec = File('pubspec.yaml').readAsStringSync();
        expect(
          pubspec.contains(RegExp(r'^version:\s*1\.0\.0\+1', multiLine: true)),
          isTrue,
          reason: 'pubspec.yaml must be bumped to 1.0.0+1 for release certification',
        );
      });

      test('Android manifest references @string/app_name with zero INTERNET permission', () {
        final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
        expect(
          manifest.contains('android:label="@string/app_name"'),
          isTrue,
          reason: 'AndroidManifest.xml must reference localized @string/app_name',
        );
        expect(
          manifest.contains('android.permission.INTERNET'),
          isFalse,
          reason: 'android.permission.INTERNET must never be present',
        );
      });

      test('Android localized strings define English MemoDiary and Chinese 拾光日记', () {
        final enStrings = File('android/app/src/main/res/values/strings.xml');
        expect(enStrings.existsSync(), isTrue);
        expect(
          enStrings.readAsStringSync().contains('<string name="app_name">MemoDiary</string>'),
          isTrue,
        );

        final zhStrings = File('android/app/src/main/res/values-zh/strings.xml');
        expect(zhStrings.existsSync(), isTrue);
        expect(
          zhStrings.readAsStringSync().contains('<string name="app_name">拾光日记</string>'),
          isTrue,
        );
      });

      test('iOS Info.plist and InfoPlist.strings define localized branding and zero network permissions', () {
        final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
        expect(
          infoPlist.contains('<key>CFBundleDisplayName</key>\n\t<string>MemoDiary</string>'),
          isTrue,
        );
        expect(
          infoPlist.contains('<key>CFBundleName</key>\n\t<string>MemoDiary</string>'),
          isTrue,
        );
        expect(
          infoPlist.contains('<key>CFBundleLocalizations</key>'),
          isTrue,
        );
        expect(
          infoPlist.contains('<string>en</string>'),
          isTrue,
        );
        expect(
          infoPlist.contains('<string>zh-Hans</string>'),
          isTrue,
        );

        final zhStrings = File('ios/Runner/zh-Hans.lproj/InfoPlist.strings');
        expect(zhStrings.existsSync(), isTrue);
        final zhContent = zhStrings.readAsStringSync();
        expect(zhContent.contains('"CFBundleDisplayName" = "拾光日记";'), isTrue);
        expect(zhContent.contains('"CFBundleName" = "拾光日记";'), isTrue);
      });

      test('Release merged Android manifest (if generated) contains zero INTERNET permission', () {
        final releaseManifestDir = Directory('build/app/intermediates/merged_manifests/release');
        if (releaseManifestDir.existsSync()) {
          final manifestFiles = releaseManifestDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.xml'));
          for (final file in manifestFiles) {
            final content = file.readAsStringSync();
            expect(
              content.contains('android.permission.INTERNET'),
              isFalse,
              reason: 'Release merged manifest ${file.path} contains forbidden android.permission.INTERNET',
            );
          }
        }
      });
    });
  });
}
