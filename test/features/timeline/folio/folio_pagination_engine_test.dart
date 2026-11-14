import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/documents/media_embed_data.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_leaf_model.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_metadata_formatter.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_pagination_engine.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_reading_perspective.dart';

void main() {
  final testDate = DateTime(2026, 11, 23, 21, 15); // 亥时初刻

  Entry createTestEntry({
    String id = 'test-1',
    String title = '暮秋听雨小记',
    String contentDelta = '',
    String plainText = '',
    String? weather = '🌧️ 暮秋微雨',
    int? mood = 4,
    bool isWeeklyReview = false,
    int? weekNumber,
    bool legacyMountsPending = false,
  }) {
    return Entry(
      id: id,
      notebookId: 'nb-1',
      templateId: 'tpl-1',
      title: title,
      contentDelta: contentDelta,
      plainText: plainText,
      entryDate: testDate,
      weather: weather,
      mood: mood,
      isWeeklyReview: isWeeklyReview,
      weekNumber: weekNumber,
      createdAt: testDate,
      updatedAt: testDate,
      isDeleted: false,
      isLocked: false,
      legacyMountsPending: legacyMountsPending,
    );
  }

  group('FolioMetadataFormatter & Utility Tests', () {
    test('normalizes seal text to 4 characters', () {
      expect(FolioMetadataFormatter.normalizeSealText('心迹'), equals('心迹印印'));
      expect(FolioMetadataFormatter.normalizeSealText('拾光存'), equals('拾光存印'));
      expect(FolioMetadataFormatter.normalizeSealText('心迹安放'), equals('心迹安放'));
      expect(FolioMetadataFormatter.normalizeSealText(''), equals('心迹安放'));
      expect(FolioMetadataFormatter.normalizeSealText('   '), equals('心迹安放'));
    });

    test('formats classical lunar and Gregorian dates', () {
      expect(
        FolioMetadataFormatter.formatFullLunarDate(testDate),
        equals('岁次丙午 · 十月十五'),
      );
      // Before the lunar new year (2026-02-17) the year is still 乙巳.
      expect(
        FolioMetadataFormatter.formatFullLunarDate(DateTime(2026, 2, 10)),
        equals('岁次乙巳 · 腊月廿三'),
      );
      // Outside the lunar data range only the stem-branch year is shown.
      expect(
        FolioMetadataFormatter.formatFullLunarDate(DateTime(1899, 6, 1)),
        equals('岁次己亥'),
      );

      final gregorian = FolioMetadataFormatter.formatGregorianDate(testDate);
      expect(gregorian, contains('2026.11.23'));
      expect(gregorian, contains('亥时一刻'));
    });

    test('extracts opening reflection only from explicit {夹注:...}', () {
      final reflection1 = FolioMetadataFormatter.extractOpeningReflection(
        plainText: '晚来天欲雪{夹注:孤灯疾书见闻}，室内小炉温茶。',
      );
      expect(reflection1, equals('眉批夹注：孤灯疾书见闻'));

      final reflection2 = FolioMetadataFormatter.extractOpeningReflection(
        plainText: '暮秋听雨小记\n窗外梧桐叶落声渐密。',
        title: '暮秋听雨小记',
      );
      expect(reflection2, isNull);
    });
  });

  group('ReadingPerspective & Substrate Themes', () {
    test('resolves themes correctly across perspectives', () {
      final faithful = ReadingPerspective.faithfulOriginal.resolveTheme();
      expect(faithful.isDark, isFalse);
      expect(faithful.label, equals('生宣纸'));

      final vermilion = ReadingPerspective.vermilionVertical.resolveTheme();
      expect(vermilion.label, equals('生宣纸'));
      expect(ReadingPerspective.vermilionVertical.rulingLayout, equals(FolioRulingLayout.vermilionVertical));

      final genko = ReadingPerspective.genkoManuscript.resolveTheme();
      expect(genko.label, equals('冷金笺'));
      expect(genko.showGoldFlecks, isTrue);
      expect(ReadingPerspective.genkoManuscript.rulingLayout, equals(FolioRulingLayout.genkoVertical));

      final obsidian = ReadingPerspective.obsidianNight.resolveTheme();
      expect(obsidian.label, equals('松烟夜墨'));
      expect(obsidian.isDark, isTrue);
      expect(ReadingPerspective.obsidianNight.rulingLayout, equals(FolioRulingLayout.faithfulHorizontal));
    });

    test('faithfulOriginal adopts saved TemplateStyle', () {
      const templateTokens = StationeryVisualTokens(
        substrate: PaperSubstrate.obsidian,
        ruleTint: RuleInkTint.slate,
        sealStyle: SealCarvingStyle.baiwen,
      );
      const customStyle = TemplateStyle(
        type: TemplateBackgroundType.lined,
        backgroundColor: Color(0xFF1A1A1A),
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
        tokens: templateTokens,
      );

      final theme = ReadingPerspective.faithfulOriginal.resolveTheme(templateStyle: customStyle);
      expect(theme.isDark, isTrue);

      final sealStyle = ReadingPerspective.faithfulOriginal.resolveSealStyle(templateStyle: customStyle);
      expect(sealStyle, equals(SealCarvingStyle.baiwen));
    });
  });

  group('FolioPaginationEngine Pagination Tests', () {
    test('0-word empty draft produces single Frontispiece leaf with placeholder', () {
      final entry = createTestEntry(
        contentDelta: jsonEncode([]),
        plainText: '',
      );

      final leaves = FolioPaginationEngine.paginate(entry: entry);

      expect(leaves.length, equals(1));
      expect(leaves.first, isA<FolioFrontispieceCoverLeaf>());
      final cover = leaves.first as FolioFrontispieceCoverLeaf;
      expect(cover.isZeroWordDraft, isTrue);
      expect(cover.isConcludingLeaf, isTrue);
      expect(cover.totalLeaves, equals(1));
      expect(cover.wordCount, equals(0));
    });

    test('single-page short entry produces Cover + Content leaf with seal', () {
      final delta = jsonEncode([
        {'insert': '晚来天欲雪，窗外梧桐叶落声渐密。取小泥炉温一壶陈年普洱。\n'},
      ]);
      final entry = createTestEntry(
        contentDelta: delta,
        plainText: '晚来天欲雪，窗外梧桐叶落声渐密。取小泥炉温一壶陈年普洱。',
      );

      final leaves = FolioPaginationEngine.paginate(
        entry: entry,
        perspective: ReadingPerspective.faithfulOriginal,
        sealText: '心迹安放',
      );

      expect(leaves.length, equals(2));
      expect(leaves[0], isA<FolioFrontispieceCoverLeaf>());
      expect(leaves[1], isA<FolioContentBodyLeaf>());

      final cover = leaves[0] as FolioFrontispieceCoverLeaf;
      expect(cover.isZeroWordDraft, isFalse);
      expect(cover.totalLeaves, equals(2));

      final body = leaves[1] as FolioContentBodyLeaf;
      expect(body.pageIndexInContent, equals(1));
      expect(body.totalContentPages, equals(1));
      expect(body.isConcludingLeaf, isTrue);
      expect(body.sealText, equals('心迹安放'));
      expect(body.horizontalRows, isNotNull);
      expect(body.horizontalRows!.isNotEmpty, isTrue);
    });

    test('vertical layouts paginate into RTL columns with 16-cell limit', () {
      final delta = jsonEncode([
        {'insert': '偶读《徐霞客游记》，见其宿云峰寺一段：步步入云，水声山色。\n'},
      ]);
      final entry = createTestEntry(
        contentDelta: delta,
        plainText: '偶读《徐霞客游记》，见其宿云峰寺一段：步步入云，水声山色。',
      );

      final leaves = FolioPaginationEngine.paginate(
        entry: entry,
        perspective: ReadingPerspective.vermilionVertical,
      );

      expect(leaves.length, equals(2));
      final body = leaves[1] as FolioContentBodyLeaf;
      expect(body.layout, equals(FolioRulingLayout.vermilionVertical));
      expect(body.verticalColumns, isNotNull);
      expect(body.verticalColumns!.isNotEmpty, isTrue);
      expect(body.verticalColumns!.first.cells.length, lessThanOrEqualTo(16));
    });

    test('interlinear sub-note {夹注:...} parses into dual-char vertical cells', () {
      final delta = jsonEncode([
        {'insert': '暮秋听雨小记{夹注:孟冬廿三夜}，孤灯疾书见闻。\n'},
      ]);
      final entry = createTestEntry(
        contentDelta: delta,
        plainText: '暮秋听雨小记{夹注:孟冬廿三夜}，孤灯疾书见闻。',
      );

      final leaves = FolioPaginationEngine.paginate(
        entry: entry,
        perspective: ReadingPerspective.genkoManuscript,
      );

      final body = leaves[1] as FolioContentBodyLeaf;
      final allCells = body.verticalColumns!
          .expand((column) => column.cells)
          .toList();

      final jiazhuCells = allCells.where((cell) => cell.isJiazhuPair).toList();
      expect(jiazhuCells.isNotEmpty, isTrue);
      expect(jiazhuCells.first.mainChar.isNotEmpty, isTrue);
    });

    test('500+ word multi-leaf entry chunks across multiple body leaves', () {
      final longText = '古人以寸管收尽烟霞，今人案牍劳形，幸得素笺一方安放朝夕。' * 25; // ~700 chars
      final delta = jsonEncode([
        {'insert': '$longText\n'},
      ]);
      final entry = createTestEntry(
        contentDelta: delta,
        plainText: longText,
      );

      final leaves = FolioPaginationEngine.paginate(
        entry: entry,
        perspective: ReadingPerspective.faithfulOriginal,
      );

      expect(leaves.length, greaterThan(2));
      expect(leaves.first, isA<FolioFrontispieceCoverLeaf>());
      expect(leaves.last, isA<FolioContentBodyLeaf>());
      expect(leaves.last.isConcludingLeaf, isTrue);
      expect(leaves[1].isConcludingLeaf, isFalse);

      final lastBody = leaves.last as FolioContentBodyLeaf;
      expect(lastBody.sealText, equals('心迹安放'));
    });

    test('vertical Folio orders {夹注:...} right-sub-column-first with vertical CJK punctuation and cell styling', () {
      final delta = jsonEncode([
        {'insert': '甲{夹注:「一二三」}乙\n'},
        {'insert': '朱笔', 'attributes': {'color': '#B83B2E'}},
        {'insert': '\n', 'attributes': {'list': 'checked'}},
      ]);
      final entry = createTestEntry(
        contentDelta: delta,
        plainText: '甲{夹注:「一二三」}乙\n朱笔',
      );

      final leaves = FolioPaginationEngine.paginate(
        entry: entry,
        perspective: ReadingPerspective.vermilionVertical,
      );

      final body = leaves[1] as FolioContentBodyLeaf;
      final columns = body.verticalColumns!;
      expect(columns, hasLength(2));

      final firstCells = columns[0].cells;
      expect(firstCells[0].mainChar, equals('甲'));
      final jiazhuCells = firstCells.where((cell) => cell.isJiazhuPair).toList();
      expect(jiazhuCells, hasLength(3));
      expect(jiazhuCells[0].mainChar, equals('﹁'));
      expect(jiazhuCells[0].secondChar, equals('三'));
      expect(jiazhuCells[1].mainChar, equals('一'));
      expect(jiazhuCells[1].secondChar, equals('﹂'));
      expect(jiazhuCells[2].mainChar, equals('二'));
      expect(jiazhuCells[2].secondChar, equals(''));
      expect(firstCells.last.mainChar, equals('乙'));

      final secondCells = columns[1].cells;
      expect(secondCells, hasLength(2));
      expect(secondCells[0].mainChar, equals('朱'));
      expect(secondCells[0].isTodo, isTrue);
      expect(secondCells[0].isChecked, isTrue);
      expect(secondCells[0].color, equals(const Color(0xFFB83B2E)));
    });

    test('resolves JSON MediaEmbedData path, caption, and aspect ratio on Tipped-In Ephemera Leaves', () {
      final delta = jsonEncode([
        {'insert': '前文。\n'},
        {
          'insert': {
            'image': jsonEncode({
              'path': 'media/west_lake.webp',
              'caption': '西湖晴岚',
              'aspect': '4:3',
            }),
          },
        },
        {
          'insert': {
            'video': {
              'path': 'media/rain_clip.mp4',
              'caption': '夜雨声',
              'aspect': '1:1',
            },
          },
        },
        {'insert': '后文。\n'},
      ]);
      final entry = createTestEntry(
        contentDelta: delta,
        plainText: '前文。\n后文。',
      );

      for (final perspective in [
        ReadingPerspective.faithfulOriginal,
        ReadingPerspective.vermilionVertical,
      ]) {
        final leaves = FolioPaginationEngine.paginate(
          entry: entry,
          perspective: perspective,
        );

        final ephemeraLeaves = leaves.whereType<FolioTippedInEphemeraLeaf>().toList();
        expect(ephemeraLeaves, hasLength(2));

        expect(ephemeraLeaves[0].mediaType, equals('image'));
        expect(ephemeraLeaves[0].sandboxedRelativePath, equals('media/west_lake.webp'));
        expect(ephemeraLeaves[0].caption, equals('西湖晴岚'));
        expect(ephemeraLeaves[0].aspectRatio, closeTo(MediaAspectRatio.standard43.ratio!, 0.0001));

        expect(ephemeraLeaves[1].mediaType, equals('video'));
        expect(ephemeraLeaves[1].sandboxedRelativePath, equals('media/rain_clip.mp4'));
        expect(ephemeraLeaves[1].caption, equals('夜雨声'));
        expect(ephemeraLeaves[1].aspectRatio, equals(1.0));
      }
    });

    test('horizontal Folio preserves blank lines, leading indentation, inline formatting, and trailing-newline todos', () {
      final delta = jsonEncode([
        {'insert': '　　第一段\n\n'},
        {'insert': '朱砂', 'attributes': {'bold': true, 'italic': true, 'color': '#B83B2E'}},
        {'insert': '\n', 'attributes': {'list': 'checked'}},
      ]);
      final entry = createTestEntry(
        contentDelta: delta,
        plainText: '　　第一段\n\n朱砂',
      );

      final leaves = FolioPaginationEngine.paginate(
        entry: entry,
        perspective: ReadingPerspective.faithfulOriginal,
      );

      final body = leaves[1] as FolioContentBodyLeaf;
      final rows = body.horizontalRows!;
      expect(rows, hasLength(3));
      expect(rows[0].segments.single.text, equals('　　第一段'));
      expect(rows[1].isEmpty, isTrue);
      expect(rows[2].segments.single.text, equals('朱砂'));
      expect(rows[2].segments.single.isBold, isTrue);
      expect(rows[2].segments.single.isItalic, isTrue);
      expect(rows[2].segments.single.color, equals(const Color(0xFFB83B2E)));
      expect(rows[2].segments.single.isTodo, isTrue);
      expect(rows[2].segments.single.isChecked, isTrue);
    });
  });

  group('FolioPaginationEngine mount-marker pairing', () {
    MediaAttachment photo(String id, {double? overlayX, double? overlayY}) => MediaAttachment(
          id: id,
          entryId: 'test-1',
          mediaType: 'image',
          relativePath: 'media/$id.webp',
          caption: '$id 小景',
          createdAt: testDate,
          overlayXRatio: overlayX,
          overlayYRatio: overlayY,
        );

    /// Thirty short lines span three Stationery Sheets (10 + 14 + 6 rows) and
    /// three horizontal Folio body leaves (14 + 14 + 2 rows). [mountsAfterLine]
    /// writes mount markers at the end of the given 0-based lines.
    Entry threeSheetEntry({Map<int, List<String>> mountsAfterLine = const {}, bool legacyMountsPending = false}) {
      final ops = <Map<String, dynamic>>[];
      final lines = <String>[];
      for (int line = 0; line < 30; line++) {
        final text = '第${line + 1}行墨迹';
        lines.add(text);
        ops.add({'insert': text});
        for (final mediaId in mountsAfterLine[line] ?? const <String>[]) {
          ops.add({
            'insert': {'mount': mediaId},
          });
        }
        ops.add({'insert': '\n'});
      }
      return createTestEntry(
        contentDelta: jsonEncode(ops),
        plainText: lines.join('\n'),
        legacyMountsPending: legacyMountsPending,
      );
    }

    List<List<String>> bodyLeafPhotoIds(List<FolioLeaf> leaves) => leaves
        .whereType<FolioContentBodyLeaf>()
        .map((leaf) => leaf.photos.map((photo) => photo.id).toList())
        .toList();

    test('each mounted item rides on the leaf of the sheet holding its marker', () {
      final entry = threeSheetEntry(mountsAfterLine: {
        2: ['photo_a'],
        15: ['photo_b', 'photo_c'],
      });

      final leaves = FolioPaginationEngine.paginate(
        entry: entry,
        attachments: [photo('photo_a'), photo('photo_b'), photo('photo_c')],
      );

      expect(bodyLeafPhotoIds(leaves), [
        ['photo_a'],
        ['photo_b', 'photo_c'],
        <String>[],
      ]);
      final secondLeaf = leaves.whereType<FolioContentBodyLeaf>().elementAt(1);
      expect(secondLeaf.photos.map((photo) => photo.targetLeafIndex), [secondLeaf.leafIndex, secondLeaf.leafIndex]);
    });

    test('staged items appear on no leaf, no tipped-in leaf and not on the Frontispiece', () {
      final entry = threeSheetEntry(mountsAfterLine: {
        2: ['photo_a'],
      });

      final leaves = FolioPaginationEngine.paginate(
        entry: entry,
        attachments: [photo('photo_staged'), photo('photo_a')],
      );

      final cover = leaves.first as FolioFrontispieceCoverLeaf;
      expect(cover.photos.map((photo) => photo.id), ['photo_a']);
      expect(cover.heroPhotoPath, 'media/photo_a.webp');
      expect(leaves.whereType<FolioTippedInEphemeraLeaf>(), isEmpty);
      expect(bodyLeafPhotoIds(leaves).expand((ids) => ids), ['photo_a']);
    });

    test('an entry with only staged items and no text is a zero-word draft', () {
      final entry = createTestEntry(contentDelta: jsonEncode([{'insert': '\n'}]), plainText: '');

      final leaves = FolioPaginationEngine.paginate(entry: entry, attachments: [photo('photo_staged')]);

      expect(leaves, hasLength(1));
      final cover = leaves.single as FolioFrontispieceCoverLeaf;
      expect(cover.isZeroWordDraft, isTrue);
      expect(cover.heroPhotoPath, isNull);
    });

    test('the Frontispiece showcase counts only the items mounted on sheet 1', () {
      final entry = threeSheetEntry(mountsAfterLine: {
        0: ['photo_a'],
        9: ['photo_b'],
        20: ['photo_c'],
      });

      final leaves = FolioPaginationEngine.paginate(
        entry: entry,
        attachments: [photo('photo_a'), photo('photo_b'), photo('photo_c')],
      );

      final cover = leaves.first as FolioFrontispieceCoverLeaf;
      expect(cover.photos.map((photo) => photo.id), ['photo_a', 'photo_b']);
      expect(cover.photos.first.targetLeafIndex, 1);
    });

    test('overlay cards keep their persisted drag position', () {
      final entry = threeSheetEntry(mountsAfterLine: {
        15: ['photo_a'],
      });

      final leaves = FolioPaginationEngine.paginate(
        entry: entry,
        attachments: [photo('photo_a', overlayX: 0.25, overlayY: 0.75)],
      );

      final card = leaves.whereType<FolioContentBodyLeaf>().elementAt(1).photos.single;
      expect(card.overlayXRatio, 0.25);
      expect(card.overlayYRatio, 0.75);
    });

    test('an entry awaiting the legacy mounting pass pairs its items first-come', () {
      final entry = threeSheetEntry(legacyMountsPending: true);
      final attachments = List.generate(4, (index) => photo('photo_$index'));

      final leaves = FolioPaginationEngine.paginate(entry: entry, attachments: attachments);

      expect(bodyLeafPhotoIds(leaves), [
        ['photo_0', 'photo_1', 'photo_2'],
        ['photo_3'],
        <String>[],
      ]);
    });

    test('an entry past the legacy pass keeps its unmarked items staged', () {
      final entry = threeSheetEntry(mountsAfterLine: {
        27: ['photo_1'],
      });

      final leaves = FolioPaginationEngine.paginate(
        entry: entry,
        attachments: [photo('photo_0'), photo('photo_1')],
      );

      expect(bodyLeafPhotoIds(leaves), [
        <String>[],
        <String>[],
        ['photo_1'],
      ]);
    });
  });
}
