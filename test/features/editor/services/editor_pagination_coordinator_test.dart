import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
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
      for (int lineNumber = 1; lineNumber <= 8; lineNumber++) {
        delta.insert('第${lineNumber.toString().padLeft(2, '0')}行日记正文文字\n');
      }

      coordinator.initializeFromDelta(jsonEncode(delta.toJson()));

      expect(coordinator.totalSheets, equals(1));
      expect(coordinator.sheets.first.isOpeningSheet, isTrue);
      final (_, plainText) = coordinator.reSynthesize();
      expect(plainText, contains('第01行'));
      expect(plainText, contains('第08行'));

      coordinator.dispose();
    });

    test('Single long un-newlined paragraph (>30 rows) partitions cleanly without infinite loop', () {
      final longParagraph = List<String>.generate(
        40,
        (segmentIndex) => '秋水共长天一色落霞与孤鹜齐飞第${segmentIndex + 1}节',
      ).join();
      final delta = Delta()..insert('$longParagraph\n');

      // 1. Test unconstrained fallback mode (contentWidth == null)
      final fallbackCoordinator = EditorPaginationCoordinator(contentWidth: null);
      fallbackCoordinator.initializeFromDelta(jsonEncode(delta.toJson()));
      expect(fallbackCoordinator.totalSheets, greaterThanOrEqualTo(3));
      final (_, fallbackPlain) = fallbackCoordinator.reSynthesize();
      expect(fallbackPlain, equals(longParagraph));
      fallbackCoordinator.dispose();

      // 2. Test constrained TextPainter mode (contentWidth: 260.0)
      final constrainedCoordinator = EditorPaginationCoordinator(
        contentWidth: 260.0,
        lineStridePx: 24.0,
      );
      constrainedCoordinator.initializeFromDelta(jsonEncode(delta.toJson()));
      expect(constrainedCoordinator.totalSheets, greaterThanOrEqualTo(3));
      final (_, constrainedPlain) = constrainedCoordinator.reSynthesize();
      expect(constrainedPlain, equals(longParagraph));
      constrainedCoordinator.dispose();
    });

    test('syncLayoutMetrics re-balances sheets when contentWidth changes while preserving selection', () {
      final longParagraph = List<String>.generate(
        22,
        (segmentIndex) => '兰亭修禊暮春清景第${(segmentIndex + 1).toString().padLeft(2, '0')}句',
      ).join();
      final delta = Delta()..insert('$longParagraph\n');

      final coordinator = EditorPaginationCoordinator(contentWidth: null);
      coordinator.initializeFromDelta(jsonEncode(delta.toJson()));
      final fallbackSheetCount = coordinator.totalSheets;

      final openingSheet = coordinator.sheets.first as OpeningSheet;
      openingSheet.controller.updateSelection(
        const TextSelection.collapsed(offset: 12),
        ChangeSource.local,
      );

      // Sync to a wide desktop/tablet width where far fewer wrapped lines are needed
      coordinator.syncLayoutMetrics(contentWidth: 720.0, lineStridePx: 24.0);
      expect(coordinator.totalSheets, lessThan(fallbackSheetCount));
      final updatedOpening = coordinator.sheets.first as OpeningSheet;
      expect(updatedOpening.controller.selection.baseOffset, equals(12));

      final (_, plainText) = coordinator.reSynthesize();
      expect(plainText, equals(longParagraph));
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

      expect(coordinator.totalSheets, equals(5));
      expect(coordinator.sheets[0], isA<OpeningSheet>());
      expect(coordinator.sheets[1], isA<EphemeraSheet>());
      expect(coordinator.sheets[2], isA<ContinuationSheet>());
      expect(coordinator.sheets[3], isA<EphemeraSheet>());
      expect(coordinator.sheets[4], isA<ContinuationSheet>());

      final imageSheet = coordinator.sheets[1] as EphemeraSheet;
      expect(imageSheet.mediaType, equals(EphemeraMediaType.image));
      expect(imageSheet.sandboxedRelativePath, equals('media/photo_autumn.webp'));

      final videoSheet = coordinator.sheets[3] as EphemeraSheet;
      expect(videoSheet.mediaType, equals(EphemeraMediaType.video));
      expect(videoSheet.sandboxedRelativePath, equals('media/stream_video.mp4'));

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
      for (int lineNumber = 1; lineNumber <= 20; lineNumber++) {
        delta.insert('第${lineNumber.toString().padLeft(2, '0')}行测试日记段落文字内容\n');
      }

      coordinator.initializeFromDelta(jsonEncode(delta.toJson()));
      expect(coordinator.totalSheets, greaterThan(1));

      coordinator.updateTypography(
        const TypographySettings(fontSize: 24.0, lineSpacing: 2.0),
      );

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

    test('Removing a legacy ephemera sheet updates total sheets and indices', () {
      final coordinator = EditorPaginationCoordinator();
      final delta = Delta()
        ..insert('初开日记\n')
        ..insert({'image': 'media/legacy_image.webp'})
        ..insert('\n');
      coordinator.initializeFromDelta(jsonEncode(delta.toJson()));

      expect(coordinator.totalSheets, equals(2));
      expect(coordinator.sheets[1], isA<EphemeraSheet>());

      coordinator.activeSheetIndex = 1;
      coordinator.media.removeEphemeraSheet(1);
      expect(coordinator.totalSheets, equals(1));
      expect(coordinator.activeSheetIndex, equals(0));

      coordinator.dispose();
    });

    test('legacy mounting pass waits for the measured layout and places items at that width', () {
      final coordinator = EditorPaginationCoordinator();
      final prose = '${List.filled(60, '湖光山色').join()}\n';
      final attachments = [
        for (final id in ['a', 'b', 'c', 'd'])
          MediaAttachment(
            id: id,
            entryId: 'entry',
            mediaType: 'image',
            relativePath: 'media/$id.webp',
            createdAt: DateTime(2026, 2, 14),
          ),
      ];
      coordinator.initializeFromDelta(
        jsonEncode((Delta()..insert(prose)).toJson()),
        attachments: attachments,
      );
      bool? didMount;
      coordinator.runLegacyMountPassOnFirstLayout((mounted) => didMount = mounted);

      expect(didMount, isNull);
      expect(coordinator.stagedItems, hasLength(4));

      coordinator.syncLayoutMetrics(contentWidth: 120, lineStridePx: 28);

      expect(didMount, isTrue);
      expect(coordinator.stagedItems, isEmpty);
      expect(
        [
          for (final sheet in coordinator.sheets.whereType<TextStationerySheet>())
            sheet.mediaAttachments.map((item) => item.id).toList(),
        ].take(2),
        [
          ['a', 'b', 'c'],
          ['d'],
        ],
      );

      coordinator.dispose();
    });
  });
}
