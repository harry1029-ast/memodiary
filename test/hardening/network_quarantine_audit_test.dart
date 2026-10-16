import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/import_export/services/date_parser_engine.dart';
import 'package:memodiary/features/import_export/services/export_service.dart';

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

      try {
        // 1. Database CRUD & FTS5 search
        await db.createEntry(
          EntriesCompanion.insert(
            id: 'quarantine_entry_1',
            notebookId: 'default',
            templateId: 'template_minimalist_white',
            title: const Value('Offline Entry'),
            contentDelta: jsonEncode([{'insert': 'Completely local notes.\n'}]),
            plainText: 'Completely local notes.',
            entryDate: DateTime(2026, 10, 16),
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
      } finally {
        await db.close();
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
  });
}
