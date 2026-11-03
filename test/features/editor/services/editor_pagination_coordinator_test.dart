import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/models/media_embed_data.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/services/editor_pagination_coordinator.dart';

void main() {
  group('EditorPaginationCoordinator - Core & Re-Synthesis Tests', () {
    test('0-word draft initializes exactly 1 OpeningSheet and zero continuation sheets', () {
      final coordinator = EditorPaginationCoordinator();
      coordinator.initializeFromDelta('');

      expect(coordinator.totalSheets, equals(1));
      expect(coordinator.sheets.first.isOpeningSheet, isTrue);
      expect(coordinator.sheets.first.sheetIndex, equals(0));

      final opening = coordinator.sheets.first as OpeningSheet;
      expect(opening.isEmpty, isTrue);
      expect(opening.rowCapacity, equals(10));

      final (deltaJson, plainText) = coordinator.reSynthesize();
      expect(plainText, isEmpty);
      expect(jsonDecode(deltaJson), isA<List>());

      coordinator.dispose();
    });

    test('Single-sheet entry beneath 10 rows stays on Sheet 1', () {
      final coordinator = EditorPaginationCoordinator();
      final delta = Delta();
      for (int i = 1; i <= 8; i++) {
        delta.insert('第${i.toString().padLeft(2, '0')}行日记正文文字\n');
      }

      coordinator.initializeFromDelta(jsonEncode(delta.toJson()));

      expect(coordinator.totalSheets, equals(1));
      expect(coordinator.sheets.first.isOpeningSheet, isTrue);
      final (deltaJson, plainText) = coordinator.reSynthesize();
      expect(plainText, contains('第01行'));
      expect(plainText, contains('第08行'));

      coordinator.dispose();
    });

    test('Interleaved media embeds allocate dedicated EphemeraSheets between text sheets', () {
      final coordinator = EditorPaginationCoordinator();
      final delta = Delta()
        ..insert('第一页开篇日记文字\n')
        ..insert({'image': 'media/photo_autumn.webp'})
        ..insert('\n')
        ..insert('第二页中间日记承接段落\n')
        ..insert({'video': 'media/stream_video.mp4'})
        ..insert('\n')
        ..insert('第三页尾声感悟\n');

      coordinator.initializeFromDelta(jsonEncode(delta.toJson()));

      // Sheets structure:
      // Sheet 0: OpeningSheet ('第一页开篇日记文字\n')
      // Sheet 1: EphemeraSheet ('media/photo_autumn.webp')
      // Sheet 2: ContinuationSheet ('第二页中间日记承接段落\n')
      // Sheet 3: EphemeraSheet ('media/stream_video.mp4')
      // Sheet 4: ContinuationSheet ('第三页尾声感悟\n')
      expect(coordinator.totalSheets, equals(5));
      expect(coordinator.sheets[0], isA<OpeningSheet>());
      expect(coordinator.sheets[1], isA<EphemeraSheet>());
      expect(coordinator.sheets[2], isA<ContinuationSheet>());
      expect(coordinator.sheets[3], isA<EphemeraSheet>());
      expect(coordinator.sheets[4], isA<ContinuationSheet>());

      final imageSheet = coordinator.sheets[1] as EphemeraSheet;
      expect(imageSheet.mediaType, equals('image'));
      expect(imageSheet.sandboxedRelativePath, equals('media/photo_autumn.webp'));

      final videoSheet = coordinator.sheets[3] as EphemeraSheet;
      expect(videoSheet.mediaType, equals('video'));
      expect(videoSheet.sandboxedRelativePath, equals('media/stream_video.mp4'));

      // 100% round-trip fidelity
      final (resynthesizedJson, plainText) = coordinator.reSynthesize();
      expect(resynthesizedJson, equals(jsonEncode(delta.toJson())));
      expect(plainText, contains('第一页开篇日记文字'));
      expect(plainText, contains('第三页尾声感悟'));

      coordinator.dispose();
    });

    test('Ephemera caption edits propagate losslessly to re-synthesized Delta', () {
      final coordinator = EditorPaginationCoordinator();
      final delta = Delta()
        ..insert('开篇正文\n')
        ..insert({'image': 'media/photo_lake.webp'})
        ..insert('\n');

      coordinator.initializeFromDelta(jsonEncode(delta.toJson()));
      expect(coordinator.totalSheets, equals(2));

      final ephemeraSheet = coordinator.sheets[1] as EphemeraSheet;
      ephemeraSheet.captionController.text = '清晨湖畔倒影';

      final (resynthesizedJson, _) = coordinator.reSynthesize();
      expect(resynthesizedJson, contains('清晨湖畔倒影'));
      expect(resynthesizedJson, contains('media/photo_lake.webp'));

      coordinator.dispose();
    });

    test('Dynamic typography updates re-balance sheets without data loss', () {
      final coordinator = EditorPaginationCoordinator();
      final delta = Delta();
      for (int i = 1; i <= 20; i++) {
        delta.insert('第${i.toString().padLeft(2, '0')}行测试日记段落文字内容\n');
      }

      coordinator.initializeFromDelta(jsonEncode(delta.toJson()));
      final initialSheetsCount = coordinator.totalSheets;
      expect(initialSheetsCount, greaterThan(1));

      // Update typography with larger font size
      coordinator.updateTypography(
        const TypographySettings(fontSize: 24.0, lineSpacing: 2.0),
      );

      // Re-balanced sheets must still preserve all lines
      final (_, plainText) = coordinator.reSynthesize();
      expect(plainText, contains('第01行'));
      expect(plainText, contains('第20行'));

      coordinator.dispose();
    });

    test('Lossless round-trip with rich inline attributes and headings', () {
      final coordinator = EditorPaginationCoordinator();
      final delta = Delta()
        ..insert('雅集墨韵')
        ..insert('\n', {'header': 1})
        ..insert('兰亭序', {'bold': true, 'color': '#C04851'})
        ..insert('癸丑之岁，{夹注:东晋永和九年}暮春之初\n')
        ..insert('会于会稽山阴之兰亭，修禊事也。\n', {'italic': true})
        ..insert('群贤毕至\n', {'list': 'bullet'})
        ..insert('少长咸集\n', {'list': 'bullet'})
        ..insert({'image': 'media/lanting.webp'})
        ..insert('\n')
        ..insert('此地有崇山峻岭，茂林修竹。\n');

      coordinator.initializeFromDelta(jsonEncode(delta.toJson()));
      final (resynthesizedJson, _) = coordinator.reSynthesize();

      expect(resynthesizedJson, equals(jsonEncode(delta.toJson())));

      coordinator.dispose();
    });

    test('Insert and remove ephemera sheets update total sheets and indices', () {
      final coordinator = EditorPaginationCoordinator();
      coordinator.initializeFromDelta(jsonEncode((Delta()..insert('初开日记\n')).toJson()));

      expect(coordinator.totalSheets, equals(1));

      coordinator.insertEphemeraSheet(
        mediaType: 'image',
        mediaData: const MediaEmbedData(
          path: 'media/inserted_image.webp',
          caption: '即时插入照片',
        ),
      );

      expect(coordinator.totalSheets, equals(2));
      expect(coordinator.sheets[1], isA<EphemeraSheet>());
      expect(coordinator.activeSheetIndex, equals(1));

      coordinator.removeEphemeraSheet(1);
      expect(coordinator.totalSheets, equals(1));
      expect(coordinator.activeSheetIndex, equals(0));

      coordinator.dispose();
    });
  });
}
