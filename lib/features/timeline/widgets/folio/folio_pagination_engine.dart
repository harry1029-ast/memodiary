import '../../../../core/database/app_database.dart';
import '../../../scenery/services/shanshui_atmosphere_resolver.dart';
import '../../../templates/models/template_style.dart';
import 'folio_content_parser.dart';
import 'folio_leaf_model.dart';
import 'folio_media_pairing.dart';
import 'folio_reading_perspective.dart';
import 'folio_vertical_paginator.dart';

/// Pure-Dart pagination engine that chunks rich diary entries into discrete
/// [FolioLeaf] items for the Thread-Bound Folio stage.
class FolioPaginationEngine {
  const FolioPaginationEngine._();

  static const int kHorizontalMaxRowsPerLeaf = 14;
  static const int kHorizontalCharsPerRow = 17;

  /// Paginates an [Entry] into a sequence of [FolioLeaf] objects according to
  /// the specified [perspective] and [templateStyle].
  static List<FolioLeaf> paginate({
    required Entry entry,
    TemplateStyle? templateStyle,
    ReadingPerspective perspective = ReadingPerspective.faithfulOriginal,
    List<MediaAttachment> attachments = const [],
    String? sealText,
    SealCarvingStyle? sealStyle,
  }) {
    final entryDate = entry.entryDate;
    final lunarDateStr = FolioContentParser.formatFullLunarDate(entryDate);
    final gregorianDateStr = FolioContentParser.formatGregorianDate(entryDate);
    final effectiveSeal = FolioContentParser.normalizeSealText(sealText ?? '心迹安放');
    final effectiveSealStyle =
        sealStyle ?? perspective.resolveSealStyle(templateStyle: templateStyle);

    final atmosphere = ShanshuiAtmosphereResolver.resolve(
      now: entryDate,
      latestEntryWeather: entry.weather,
      entryTimestamp: entryDate,
      entryTitle: entry.title,
      entryPlainText: entry.plainText,
    );

    String? heroPhotoPath;
    String? heroMediaType;
    if (attachments.isNotEmpty) {
      final firstMedia = attachments.first;
      heroPhotoPath = firstMedia.relativePath;
      heroMediaType = firstMedia.mediaType;
    }

    final parsedBlocks = FolioContentParser.parseContentBlocks(
      contentDeltaJson: entry.contentDelta,
      fallbackPlainText: entry.plainText,
      attachments: attachments,
    );

    final openingReflection = FolioContentParser.extractOpeningReflection(
      plainText: entry.plainText,
      title: entry.title,
    );

    final wordCount = entry.plainText.trim().runes.length;
    final isZeroWordDraft = wordCount == 0 && parsedBlocks.isEmpty && attachments.isEmpty;

    if (isZeroWordDraft) {
      return [
        FolioFrontispieceCoverLeaf(
          leafIndex: 0,
          totalLeaves: 1,
          entryTitle: entry.title?.trim().isNotEmpty == true ? entry.title!.trim() : '无题',
          lunarDate: lunarDateStr,
          gregorianDate: gregorianDateStr,
          weather: entry.weather,
          mood: entry.mood,
          isWeeklyReview: entry.isWeeklyReview,
          weekNumber: entry.weekNumber,
          heroPhotoPath: null,
          sceneryAtmosphere: atmosphere,
          openingReflection: null,
          isZeroWordDraft: true,
          sealText: effectiveSeal,
          sealStyle: effectiveSealStyle,
          wordCount: 0,
        ),
      ];
    }

    final rulingLayout = perspective.rulingLayout;
    final contentLeaves = <FolioLeaf>[];

    if (rulingLayout.isVertical) {
      FolioVerticalPaginator.paginateVerticalLeaves(
        blocks: parsedBlocks,
        layout: rulingLayout,
        title: entry.title?.trim().isNotEmpty == true ? entry.title!.trim() : '无题',
        lunarDate: lunarDateStr,
        outLeaves: contentLeaves,
      );
    } else {
      _paginateHorizontalLeaves(
        blocks: parsedBlocks,
        layout: rulingLayout,
        title: entry.title?.trim().isNotEmpty == true ? entry.title!.trim() : '无题',
        lunarDate: lunarDateStr,
        outLeaves: contentLeaves,
      );
    }

    FolioMediaPairing.appendUnplacedAttachmentLeaves(
      attachments: attachments,
      contentLeaves: contentLeaves,
      title: entry.title?.trim().isNotEmpty == true ? entry.title!.trim() : '无题',
      lunarDate: lunarDateStr,
    );

    final totalLeaves = 1 + contentLeaves.length;
    final totalContentCount = contentLeaves.length;
    final totalBodyCount = contentLeaves.whereType<FolioContentBodyLeaf>().length;
    final basePhotos = FolioMediaPairing.curatePhotos(
      attachments: attachments,
      contentLeaves: const [],
      fallbackHeroPath: heroPhotoPath,
      fallbackMediaType: heroMediaType,
      entryDateStr: gregorianDateStr,
    );

    final reindexedContentLeaves = <FolioLeaf>[];
    var contentPageCounter = 1;
    var bodyCounter = 0;

    for (int index = 0; index < totalContentCount; index++) {
      final currentLeaf = contentLeaves[index];
      final isLast = index == totalContentCount - 1;
      final physicalIndex = index + 1;

      if (currentLeaf is FolioContentBodyLeaf) {
        final leafPhotos = FolioMediaPairing.photosForBodyIndex(basePhotos, bodyCounter++, totalBodyCount);
        reindexedContentLeaves.add(FolioContentBodyLeaf(
          leafIndex: physicalIndex,
          totalLeaves: totalLeaves,
          pageIndexInContent: contentPageCounter++,
          totalContentPages: totalContentCount,
          layout: currentLeaf.layout,
          horizontalRows: currentLeaf.horizontalRows,
          verticalColumns: currentLeaf.verticalColumns,
          title: currentLeaf.title,
          lunarDate: currentLeaf.lunarDate,
          sealText: isLast ? effectiveSeal : null,
          sealStyle: effectiveSealStyle,
          photos: leafPhotos,
          isConcludingLeaf: isLast,
        ));
      } else if (currentLeaf is FolioTippedInEphemeraLeaf) {
        reindexedContentLeaves.add(FolioTippedInEphemeraLeaf(
          leafIndex: physicalIndex,
          totalLeaves: totalLeaves,
          mediaType: currentLeaf.mediaType,
          sandboxedRelativePath: currentLeaf.sandboxedRelativePath,
          caption: currentLeaf.caption,
          aspectRatio: currentLeaf.aspectRatio,
          title: currentLeaf.title,
          lunarDate: currentLeaf.lunarDate,
          sealText: isLast ? effectiveSeal : null,
          sealStyle: effectiveSealStyle,
          isConcludingLeaf: isLast,
        ));
      }
    }

    final curatedPhotos = FolioMediaPairing.curatePhotos(
      attachments: attachments,
      contentLeaves: reindexedContentLeaves,
      fallbackHeroPath: heroPhotoPath,
      fallbackMediaType: heroMediaType,
      entryDateStr: gregorianDateStr,
    );

    final coverLeaf = FolioFrontispieceCoverLeaf(
      leafIndex: 0,
      totalLeaves: totalLeaves,
      entryTitle: entry.title?.trim().isNotEmpty == true ? entry.title!.trim() : '无题',
      lunarDate: lunarDateStr,
      gregorianDate: gregorianDateStr,
      weather: entry.weather,
      mood: entry.mood,
      isWeeklyReview: entry.isWeeklyReview,
      weekNumber: entry.weekNumber,
      heroPhotoPath: heroPhotoPath,
      heroMediaType: heroMediaType,
      sceneryAtmosphere: atmosphere,
      openingReflection: openingReflection,
      isZeroWordDraft: false,
      sealText: effectiveSeal,
      sealStyle: effectiveSealStyle,
      wordCount: wordCount,
      photos: curatedPhotos,
    );

    return [coverLeaf, ...reindexedContentLeaves];
  }

  // --- Horizontal Pagination ---

  static void _paginateHorizontalLeaves({
    required List<FolioContentBlock> blocks,
    required FolioRulingLayout layout,
    required String title,
    required String lunarDate,
    required List<FolioLeaf> outLeaves,
  }) {
    var currentRows = <FolioHorizontalRow>[];

    void flushRows() {
      if (currentRows.isNotEmpty) {
        outLeaves.add(FolioContentBodyLeaf(
          leafIndex: 0,
          totalLeaves: 0,
          pageIndexInContent: 0,
          totalContentPages: 0,
          layout: layout,
          horizontalRows: List.of(currentRows),
          title: title,
          lunarDate: lunarDate,
        ));
        currentRows = <FolioHorizontalRow>[];
      }
    }

    for (final block in blocks) {
      if (block is FolioMediaBlock) {
        flushRows();
        outLeaves.add(FolioTippedInEphemeraLeaf(
          leafIndex: 0,
          totalLeaves: 0,
          mediaType: block.mediaType,
          sandboxedRelativePath: block.relativePath,
          caption: block.caption,
          title: title,
          lunarDate: lunarDate,
        ));
        continue;
      }

      if (block is FolioTextBlock) {
        final paragraphRows = _tokenizeHorizontalParagraph(block);
        for (final row in paragraphRows) {
          currentRows.add(row);
          if (currentRows.length >= kHorizontalMaxRowsPerLeaf) {
            flushRows();
          }
        }
      }
    }

    flushRows();
  }

  static List<FolioHorizontalRow> _tokenizeHorizontalParagraph(FolioTextBlock block) {
    final rows = <FolioHorizontalRow>[];
    var currentRowSegments = <FolioHorizontalSegment>[];
    int currentLen = 0;

    void flushCurrentRow() {
      if (currentRowSegments.isNotEmpty) {
        rows.add(FolioHorizontalRow(segments: List.of(currentRowSegments)));
        currentRowSegments = <FolioHorizontalSegment>[];
        currentLen = 0;
      }
    }

    for (final segment in block.segments) {
      if (segment.isJiazhuNote) {
        final noteLen = segment.text.length + 2;
        if (currentLen + noteLen > kHorizontalCharsPerRow && currentRowSegments.isNotEmpty) {
          flushCurrentRow();
        }
        currentRowSegments.add(segment);
        currentLen += noteLen;
      } else {
        final chars = segment.text.runes.map((rune) => String.fromCharCode(rune)).toList();
        final buffer = StringBuffer();

        for (final character in chars) {
          if (character == '\n') {
            if (buffer.isNotEmpty) {
              currentRowSegments.add(segment.copyWith(text: buffer.toString()));
              buffer.clear();
            }
            flushCurrentRow();
            continue;
          }

          buffer.write(character);
          currentLen++;

          if (currentLen >= kHorizontalCharsPerRow) {
            currentRowSegments.add(segment.copyWith(text: buffer.toString()));
            buffer.clear();
            flushCurrentRow();
          }
        }

        if (buffer.isNotEmpty) {
          currentRowSegments.add(segment.copyWith(text: buffer.toString()));
        }
      }
    }

    flushCurrentRow();
    return rows;
  }
}
