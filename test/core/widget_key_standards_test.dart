import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Key Standards Tests (CODING_STANDARDS.md § 1)', () {
    test('Settings screen keys strictly carry "settings_" domain prefix', () {
      final file = File('lib/features/settings/screens/settings_screen.dart');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final keyRegex = RegExp(r"Key\('([^']+)'\)");
      final matches = keyRegex.allMatches(content);

      expect(matches, isNotEmpty, reason: 'Expected keys in settings_screen.dart');
      for (final match in matches) {
        final keyName = match.group(1)!;
        expect(
          keyName.startsWith('settings_'),
          isTrue,
          reason: 'Key "$keyName" in settings_screen.dart must follow '
              'CODING_STANDARDS.md § 1 prefix standard: "Key(\'settings_<feature>_<element>\')"',
        );
      }
    });
    test('OCR photo viewer and photo match card keys strictly carry "search_" domain prefix', () {
      final files = [
        File('lib/features/search/screens/ocr_photo_viewer_screen.dart'),
        File('lib/features/search/widgets/photo_text_match_card.dart'),
      ];

      final keyRegex = RegExp(r"Key\('([^'$]+)");
      for (final file in files) {
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        final matches = keyRegex.allMatches(content);
        expect(matches, isNotEmpty, reason: 'Expected keys in ${file.path}');
        for (final match in matches) {
          final keyName = match.group(1)!;
          expect(
            keyName.startsWith('search_'),
            isTrue,
            reason: 'Key "$keyName" in ${file.path} must follow '
                'CODING_STANDARDS.md § 1 prefix standard: "Key(\'search_<feature>_<element>\')"',
          );
        }
      }
    });
  });
}

