import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_content_parser.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_leaf_model.dart';
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
    );
  }

  group('FolioContentParser & Utility Tests', () {
    test('normalizes seal text to 4 characters', () {
      expect(FolioContentParser.normalizeSealText('心迹'), equals('心迹印印'));
      expect(FolioContentParser.normalizeSealText('拾光存'), equals('拾光存印'));
      expect(FolioContentParser.normalizeSealText('心迹安放'), equals('心迹安放'));
      expect(FolioContentParser.normalizeSealText(''), equals('心迹安放'));
      expect(FolioContentParser.normalizeSealText('   '), equals('心迹安放'));
    });

    test('formats classical lunar and Gregorian dates', () {
      final lunar = FolioContentParser.formatFullLunarDate(testDate);
      expect(lunar, contains('岁次丙午'));
      expect(lunar, contains('冬月廿三'));

      final gregorian = FolioContentParser.formatGregorianDate(testDate);
      expect(gregorian, contains('2026.11.23'));
      expect(gregorian, contains('亥时一刻'));
    });

    test('extracts opening reflection only from explicit {夹注:...}', () {
      final reflection1 = FolioContentParser.extractOpeningReflection(
        plainText: '晚来天欲雪{夹注:孤灯疾书见闻}，室内小炉温茶。',
      );
      expect(reflection1, equals('眉批夹注：孤灯疾书见闻'));

      final reflection2 = FolioContentParser.extractOpeningReflection(
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

    test('media attachments emit dedicated TippedInEphemeraLeaf', () {
      final entry = createTestEntry(
        contentDelta: jsonEncode([
          {'insert': '窗外细雨蒙蒙。\n'},
        ]),
        plainText: '窗外细雨蒙蒙。',
      );

      final attachment = MediaAttachment(
        id: 'media-1',
        entryId: entry.id,
        mediaType: 'image',
        relativePath: 'media/test_photo.webp',
        thumbnailPath: 'media/thumb_test_photo.webp',
        ocrText: '竹窗听雨图',
        createdAt: testDate,
      );

      final leaves = FolioPaginationEngine.paginate(
        entry: entry,
        attachments: [attachment],
      );

      expect(leaves.length, equals(3));
      expect(leaves[0], isA<FolioFrontispieceCoverLeaf>());
      final cover = leaves[0] as FolioFrontispieceCoverLeaf;
      expect(cover.heroPhotoPath, equals('media/test_photo.webp'));

      // Contains content leaf and tipped-in ephemera leaf
      final ephemeraLeaves = leaves.whereType<FolioTippedInEphemeraLeaf>().toList();
      expect(ephemeraLeaves.length, equals(1));
      expect(ephemeraLeaves.first.sandboxedRelativePath, equals('media/test_photo.webp'));
      expect(ephemeraLeaves.first.caption, contains('竹窗听雨图'));
      expect(leaves.last.isConcludingLeaf, isTrue);
    });
  });
}
