import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Gitignore Safety & Directory Anchor Tests', () {
    late File gitignoreFile;
    late List<String> gitignoreLines;

    setUp(() {
      gitignoreFile = File('.gitignore');
      expect(gitignoreFile.existsSync(), isTrue, reason: '.gitignore must exist at repo root');
      gitignoreLines = gitignoreFile.readAsLinesSync();
    });

    test('no bare unanchored "core" rule that collides with lib/core or test/core', () {
      for (final line in gitignoreLines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

        expect(
          trimmed == 'core',
          isFalse,
          reason: 'Unanchored "core" in .gitignore matches all directories named core '
              '(including lib/core/ and test/core/). Use "/core" or "core.[0-9]*" instead.',
        );
      }
    });

    test('critical application source trees are not ignored by .gitignore patterns', () {
      final bannedPrefixPatterns = <String>['lib', 'lib/', 'test', 'test/'];
      for (final line in gitignoreLines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

        expect(
          bannedPrefixPatterns.contains(trimmed),
          isFalse,
          reason: 'Rule "$trimmed" in .gitignore would unintentionally ignore source code trees.',
        );
      }
    });
  });
}

