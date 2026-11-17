import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Album Studio Rebranding & Copy Guardrails', () {
    test('Obsolete legacy, mixed-English, and poetic filler terms are not present in albums UI source files', () {
      final bannedTokens = [
        '暂存栏',
        '放回本页',
        'Removed (',
        '· Collection Box',
        '· Endpaper',
        '卷尾留白',
        '· Cover',
        '· Add Elements',
        '· Page Colors & Graphics',
        '· Suggested Colors',
        '· Background Graphics',
        '· Collage Layouts',
        '· Add Blank Page',
        '· Import Photos',
        '· Arrange Pages',
        '· Themes & Style',
        '撤销 (Undo)',
        '重做 (Redo)',
        '山河沿路，笔底留痕',
        'Shanshui Ink ·',
        'Jardin ·',
        'Abstract Blue ·',
        'Day at the Beach ·',
        'Playful Rainbow ·',
        '旅行影集',
        '新建影集',
        '编辑旅行影集',
        '写影札',
        '未题写札记',
      ];
      final targetDirs = [
        Directory('lib/features/albums/widgets'),
        Directory('lib/features/albums/screens'),
        Directory('lib/features/albums/constants'),
      ];
      final targetFiles = [
        File('lib/features/albums/services/album_theme_catalog.dart'),
        File('lib/features/albums/services/album_pdf_exporter.dart'),
        File('lib/features/albums/services/album_studio_pdf_renderer.dart'),
      ];

      final filesToCheck = <File>[...targetFiles];
      for (final dir in targetDirs) {
        expect(dir.existsSync(), isTrue);
        filesToCheck.addAll(
          dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart')),
        );
      }

      for (final file in filesToCheck) {
        expect(file.existsSync(), isTrue, reason: '${file.path} should exist');
        final codeOnly = file
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');
        for (final banned in bannedTokens) {
          expect(
            codeOnly.contains(banned),
            isFalse,
            reason:
                'Found banned legacy string "$banned" in ${file.path}. Use plain modern Chinese copy.',
          );
        }
      }
    });
  });
}

