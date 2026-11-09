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

    test('lib/features/scenery enforces component domain prefix on widget keys', () {
      final sceneryDir = Directory('${rootDir.path}/lib/features/scenery');
      expect(sceneryDir.existsSync(), isTrue);

      const validPrefixes = <String>['scenery_', 'thought_spark_', 'contemplation_'];
      final keyRegex = RegExp(r"Key\('([^']+)'\)");
      final dartFiles = sceneryDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'));

      final violations = <String>[];

      for (final file in dartFiles) {
        final relPath = file.path.replaceFirst('${rootDir.path}/', '');
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trim();
          if (trimmed.startsWith('//') || trimmed.startsWith('*')) {
            continue;
          }

          for (final match in keyRegex.allMatches(line)) {
            final keyName = match.group(1);
            if (keyName != null && !validPrefixes.any((prefix) => keyName.startsWith(prefix))) {
              violations.add('$relPath:${i + 1}: Key(\'$keyName\')');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Widget keys in lib/features/scenery must follow component domain prefix '
            '(scenery_, thought_spark_, contemplation_) per CODING_STANDARDS.md § 1. '
            'Found violations in:\n${violations.join('\n')}',
      );
    });

    test('Non-grandfathered Dart files in lib/ maintain strict file size limit (< 450 LOC)', () {
      const maxAllowedLoc = 450;
      const grandfatheredFilesExceeding450Loc = <String>{
        'lib/core/database/app_database.dart',
        'lib/core/services/media_sandbox_service.dart',
        'lib/core/theme/ink_diary_theme.dart',
        'lib/features/albums/data/album_repository.dart',
        'lib/features/albums/models/album_studio_models.dart',
        'lib/features/albums/screens/album_book_overview_screen.dart',
        'lib/features/albums/screens/album_page_editor_screen.dart',
        'lib/features/albums/screens/album_workspace_screen.dart',
        'lib/features/albums/services/album_studio_controller.dart',
        'lib/features/albums/services/album_studio_pdf_renderer.dart',
        'lib/features/albums/services/album_theme_catalog.dart',
        'lib/features/albums/widgets/page_background_painter.dart',
        'lib/features/analytics/screens/analytics_dashboard_screen.dart',
        'lib/features/editor/widgets/journal_letterhead.dart',
        'lib/features/editor/widgets/soundscape_modal.dart',
        'lib/features/editor/widgets/typography_sheet.dart',
        'lib/features/import_export/services/backup_crypto.dart',
        'lib/features/import_export/services/backup_restore_service.dart',
        'lib/features/import_export/services/date_parser_engine.dart',
        'lib/features/import_export/services/offline_cjk_ttf_generator.dart',
        'lib/features/import_export/services/pdf_entry_serializer.dart',
        'lib/features/import_export/widgets/backup_dialogs.dart',
        'lib/features/intro/widgets/book_3d_stage.dart',
        'lib/features/intro/widgets/living_ink_background_painter.dart',
        'lib/features/scenery/models/ancient_room_palette.dart',
        'lib/features/scenery/models/outdoor_street_palette.dart',
        'lib/features/scenery/models/shanshui_atmosphere.dart',
        'lib/features/scenery/models/shanshui_palette.dart',
        'lib/features/scenery/painters/ancient_room_painter.dart',
        'lib/features/scenery/painters/outdoor_street_painter.dart',
        'lib/features/scenery/painters/outdoor_street_static_architecture.dart',
        'lib/features/scenery/widgets/shanshui_canvas_painter.dart',
        'lib/features/scenery/widgets/shanshui_scenery_card.dart',
        'lib/features/search/screens/search_screen.dart',
        'lib/features/search/services/event_suggestion_service.dart',
        'lib/features/search/services/natural_language_search_parser.dart',
        'lib/features/settings/screens/settings_screen.dart',
        'lib/features/templates/screens/custom_template_editor_screen.dart',
        'lib/features/templates/widgets/template_switcher_sheet.dart',
        'lib/features/timeline/screens/entry_detail_screen.dart',
        'lib/features/timeline/screens/timeline_screen.dart',
        'lib/features/weekly_review/screens/weekly_debrief_detail_screen.dart',
        'lib/features/weekly_review/screens/weekly_review_screen.dart',
      };

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'));

      final violations = <String>[];

      for (final file in dartFiles) {
        final relPath = file.path.replaceFirst('${rootDir.path}/', '');
        if (grandfatheredFilesExceeding450Loc.contains(relPath)) {
          continue;
        }

        final lineCount = file.readAsLinesSync().length;
        if (lineCount >= maxAllowedLoc) {
          violations.add('$relPath: $lineCount LOC (max allowed: < $maxAllowedLoc LOC)');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'All newly authored files in lib/ must remain strictly under 450 lines '
            'per GEMINI.md and CODING_STANDARDS.md § 3. Found files exceeding limit:\n'
            '${violations.join('\n')}',
      );
    });

    test('lib/ enforces displacement over coexistence with zero deprecated backward compatibility markers', () {
      final backwardCompatibilityRegex = RegExp(
        r'(@deprecated|backwards compatibility|backward compatibility)',
        caseSensitive: false,
      );

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'));

      final violations = <String>[];

      for (final file in dartFiles) {
        final relPath = file.path.replaceFirst('${rootDir.path}/', '');
        final lines = file.readAsLinesSync();
        for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
          final line = lines[lineIndex];
          if (backwardCompatibilityRegex.hasMatch(line)) {
            violations.add('$relPath:${lineIndex + 1}: ${line.trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Deprecated backward compatibility wrappers violate CODING_STANDARDS.md § 3 '
            '(Displacement over Coexistence). Found:\n${violations.join('\n')}',
      );
    });

    test('Rich-text emptiness is structural, never trimmed plain text', () {
      final inlineTrimEmptyRegex = RegExp(r'toPlainText\(\)\.trim\(\)\.isEmpty');
      final trimmedAssignmentRegex = RegExp(r'(\w+)\s*=\s*[^;]*toPlainText\(\)\.trim\(\)');
      const lookaheadLines = 3;

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'));

      final violations = <String>[];

      for (final file in dartFiles) {
        final relPath = file.path.replaceFirst('${rootDir.path}/', '');
        final lines = file.readAsLinesSync();
        for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
          final line = lines[lineIndex];
          if (inlineTrimEmptyRegex.hasMatch(line)) {
            violations.add('$relPath:${lineIndex + 1}: ${line.trim()}');
            continue;
          }
          final assignment = trimmedAssignmentRegex.firstMatch(line);
          if (assignment == null) continue;
          final emptinessCheck = RegExp('\\b${assignment.group(1)}\\.(isEmpty|isNotEmpty)\\b');
          final lastLookahead = (lineIndex + lookaheadLines).clamp(0, lines.length - 1);
          for (var nextIndex = lineIndex + 1; nextIndex <= lastLookahead; nextIndex++) {
            if (emptinessCheck.hasMatch(lines[nextIndex])) {
              violations.add('$relPath:${nextIndex + 1}: ${lines[nextIndex].trim()}');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Trimmed plain text used as an emptiness test violates CODING_STANDARDS.md § 2 '
            '(Rich-Text Document Structural Emptiness Invariant); use `document.length <= 1`. '
            'Found:\n${violations.join('\n')}',
      );
    });
  });
}

