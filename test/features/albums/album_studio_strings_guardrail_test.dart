import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Album Studio Rebranding & Copy Guardrails', () {
    test('Obsolete legacy terms are not present in albums UI source files', () {
      final bannedTokens = ['暂存栏', '放回本页', 'Removed ('];
      final targetDirs = [
        Directory('lib/features/albums/widgets'),
        Directory('lib/features/albums/screens'),
      ];

      for (final dir in targetDirs) {
        expect(dir.existsSync(), isTrue);
        final files = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in files) {
          final content = file.readAsStringSync();
          for (final banned in bannedTokens) {
            expect(
              content.contains(banned),
              isFalse,
              reason:
                  'Found banned legacy string "$banned" in ${file.path}. Use AlbumStudioStrings constant instead.',
            );
          }
        }
      }
    });
  });
}

