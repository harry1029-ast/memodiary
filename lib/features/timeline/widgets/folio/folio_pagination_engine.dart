import '../../../../core/database/app_database.dart';
import '../../../../core/documents/entry_content_decoder.dart';
import '../../../editor/domain/stationery_sheet_descriptor.dart';
import '../../../scenery/services/shanshui_atmosphere_resolver.dart';
import '../../../templates/models/template_style.dart';
import '../../services/folio_media_pairing.dart';
import 'folio_horizontal_paginator.dart';
import 'folio_leaf_model.dart';
import 'folio_metadata_formatter.dart';
import 'folio_reading_perspective.dart';
import 'folio_vertical_paginator.dart';

/// Pure-Dart pagination engine that chunks rich diary entries into discrete
/// [FolioLeaf] items for the Thread-Bound Folio stage.
class FolioPaginationEngine {
  const FolioPaginationEngine._();

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
    final lunarDateStr = FolioMetadataFormatter.formatFullLunarDate(entryDate);
    final gregorianDateStr = FolioMetadataFormatter.formatGregorianDate(entryDate);
    final effectiveSeal = FolioMetadataFormatter.normalizeSealText(sealText ?? '心迹安放');
    final effectiveSealStyle =
        sealStyle ?? perspective.resolveSealStyle(templateStyle: templateStyle);

    final atmosphere = ShanshuiAtmosphereResolver.resolve(
      now: entryDate,
      latestEntryWeather: entry.weather,
      entryTimestamp: entryDate,
      entryTitle: entry.title,
      entryPlainText: entry.plainText,
    );

    final mountPlan = FolioMediaPairing.pairLeaves(
      entry: entry,
      attachments: attachments,
      templateStyle: templateStyle,
    );
    final coverMounts = mountPlan.firstSheetMounts;
    final heroPhotoPath = coverMounts.isEmpty ? null : coverMounts.first.relativePath;
    final heroMediaType = coverMounts.isEmpty ? null : coverMounts.first.mediaType;

    final parsedBlocks = EntryContentDecoder.decode(
      contentDeltaJson: entry.contentDelta,
      fallbackPlainText: entry.plainText,
    );

    final openingReflection = FolioMetadataFormatter.extractOpeningReflection(
      plainText: entry.plainText,
      title: entry.title,
    );

    final wordCount = entry.plainText.trim().runes.length;
    final hasMountedMedia = mountPlan.hasMounts;
    final hasRenderableContent = parsedBlocks.any(
      (block) =>
          block is EntryMediaBlock ||
          (block is EntryTextBlock && !block.isBlank),
    );
    final isZeroWordDraft =
        wordCount == 0 && !hasRenderableContent && !hasMountedMedia;

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

    final effectiveTheme = perspective.resolveTheme(templateStyle: templateStyle);
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
      FolioHorizontalPaginator.paginateHorizontalLeaves(
        blocks: parsedBlocks,
        layout: rulingLayout,
        theme: effectiveTheme,
        title: entry.title?.trim().isNotEmpty == true ? entry.title!.trim() : '无题',
        lunarDate: lunarDateStr,
        outLeaves: contentLeaves,
      );
    }

    final totalLeaves = 1 + contentLeaves.length;
    final totalContentCount = contentLeaves.length;
    final totalBodyCount = contentLeaves.whereType<FolioContentBodyLeaf>().length;

    final reindexedContentLeaves = <FolioLeaf>[];
    var contentPageCounter = 1;
    var bodyCounter = 0;
    final mountsByLeaf = mountPlan.mountsByLeaf(totalBodyCount);

    for (int index = 0; index < totalContentCount; index++) {
      final currentLeaf = contentLeaves[index];
      final isLast = index == totalContentCount - 1;
      final physicalIndex = index + 1;

      if (currentLeaf is FolioContentBodyLeaf) {
        final leafPhotos = _photosForLeaf(
          mounted: mountsByLeaf[bodyCounter++],
          targetLeafIndex: physicalIndex,
          entryDateStr: gregorianDateStr,
        );
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

    final firstBodyLeafIndex = reindexedContentLeaves
        .whereType<FolioContentBodyLeaf>()
        .map((leaf) => leaf.leafIndex)
        .firstOrNull;
    final curatedPhotos = _photosForLeaf(
      mounted: coverMounts,
      targetLeafIndex: firstBodyLeafIndex ?? (totalLeaves > 1 ? 1 : 0),
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

  /// Converts the attachments mounted on a leaf into Folio photo cards targeting
  /// [targetLeafIndex], preserving persisted overlay drag positions.
  static List<FolioPhotoAttachment> _photosForLeaf({
    required List<MediaAttachment> mounted,
    required int targetLeafIndex,
    required String entryDateStr,
  }) {
    return [
      for (int index = 0; index < mounted.length; index++)
        _toPhoto(mounted[index], index, targetLeafIndex, entryDateStr),
    ];
  }

  static FolioPhotoAttachment _toPhoto(
    MediaAttachment attachment,
    int indexOnLeaf,
    int targetLeafIndex,
    String entryDateStr,
  ) {
    final caption = attachment.caption?.trim() ?? '';
    return FolioPhotoAttachment(
      id: attachment.id,
      relativePath: attachment.relativePath,
      mediaType: EphemeraMediaType.fromEmbedKey(attachment.mediaType),
      title: caption.isNotEmpty ? caption.split('\n').first : '随文影札 ${indexOnLeaf + 1}',
      caption: caption.isNotEmpty ? caption : '随文影札 · 拾光留影',
      date: entryDateStr,
      pageNumber: targetLeafIndex,
      targetLeafIndex: targetLeafIndex,
      overlayXRatio: attachment.overlayXRatio,
      overlayYRatio: attachment.overlayYRatio,
    );
  }
}
