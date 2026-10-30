import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Code Style & Mechanical Standards Audit (CODING_STANDARDS.md § 1)', () {
    final rootDir = Directory.current;
    final libDir = Directory('${rootDir.path}/lib');
    final albumsDir = Directory('${rootDir.path}/lib/features/albums');

    test('lib/features/albums enforces zero single-letter lambda parameters', () {
      expect(albumsDir.existsSync(), isTrue, reason: 'lib/features/albums directory should exist');

      final singleLetterLambdaRegex = RegExp(r'\(\s*[a-zA-Z]\s*\)\s*=>');
      final singleLetterBlockRegex = RegExp(r'\(\s*[a-zA-Z]\s*\)\s*\{');
      final twoSingleLetterRegex = RegExp(r'\(\s*[a-zA-Z]\s*,\s*[a-zA-Z]\s*\)\s*(=>|\{)');

      final dartFiles = albumsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'));

      final violations = <String>[];

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trim();
          // Skip comments
          if (trimmed.startsWith('//') || trimmed.startsWith('*') || trimmed.startsWith('/*')) {
            continue;
          }

          if (singleLetterLambdaRegex.hasMatch(line) ||
              singleLetterBlockRegex.hasMatch(line) ||
              twoSingleLetterRegex.hasMatch(line)) {
            final relPath = file.path.replaceFirst('${rootDir.path}/', '');
            violations.add('$relPath:${i + 1}: $trimmed');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Single-letter variables in lambdas or callbacks violate CODING_STANDARDS.md § 1 '
            '(Domain Names over Single Letters). Found:\n${violations.join('\n')}',
      );
    });

    test('All non-generated files in lib/ adhere to collection mapping identifier standards', () {
      expect(libDir.existsSync(), isTrue);

      // Known legacy files grandfathered until refactored by future feature phases:
      const grandfatheredLegacyFiles = <String>{
        'lib/core/database/app_database.dart',
        'lib/core/database/database_key_manager.dart',
        'lib/core/services/auth_service.dart',
        'lib/features/analytics/services/analytics_service.dart',
        'lib/features/import_export/models/backup_manifest.dart',
        'lib/features/import_export/screens/import_staging_screen.dart',
        'lib/features/import_export/services/backup_restore_service.dart',
        'lib/features/search/services/event_suggestion_service.dart',
        'lib/features/timeline/screens/timeline_screen.dart',
      };

      final singleLetterCollectionRegex = RegExp(
        r'\.(map|where|forEach|expand|any|every)\(\s*\([a-zA-Z]\)\s*(=>|\{)',
      );

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'));

      final violations = <String>[];

      for (final file in dartFiles) {
        final relPath = file.path.replaceFirst('${rootDir.path}/', '');
        if (grandfatheredLegacyFiles.contains(relPath)) {
          continue;
        }

        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trim();
          if (trimmed.startsWith('//') || trimmed.startsWith('*')) {
            continue;
          }

          if (singleLetterCollectionRegex.hasMatch(line)) {
            violations.add('$relPath:${i + 1}: $trimmed');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Collection mappings must use expressive domain names (e.g. .map((photo) => ...)) '
            'per CODING_STANDARDS.md § 1. Found violations in:\n${violations.join('\n')}',
      );
    });
  });
}

