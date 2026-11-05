import 'package:flutter/material.dart';

import '../../../../core/services/media_sandbox_service.dart';
import '../../../editor/domain/stationery_sheet_descriptor.dart';
import '../../../editor/widgets/fullscreen_media_lightbox.dart';
import 'folio_cover_showcase.dart';
import 'folio_leaf_model.dart';
import 'folio_leaf_scaffold.dart';
import 'folio_photo_sleeve_modal.dart';
import 'folio_reading_perspective.dart';

/// Page 0: Ceremonial Frontispiece Cover of the Thread-Bound Folio.
class FolioFrontispiecePage extends StatelessWidget {
  final FolioFrontispieceCoverLeaf leaf;
  final FolioSubstrateTheme theme;
  final MediaSandboxService? mediaService;
  final VoidCallback? onTurnForward;
  final ValueChanged<int>? onJumpToPage;

  const FolioFrontispiecePage({
    super.key,
    required this.leaf,
    required this.theme,
    this.mediaService,
    this.onTurnForward,
    this.onJumpToPage,
  });

  void _openPhotoSleeveModal(BuildContext context) {
    if (leaf.photos.isEmpty) return;
    FolioPhotoSleeveModal.show(
      context: context,
      entryTitle: leaf.entryTitle,
      photos: leaf.photos,
      theme: theme,
      mediaService: mediaService,
      onJumpToPage: onJumpToPage,
    );
  }

  void _handlePhotoTap(BuildContext context, FolioPhotoAttachment photo) {
    if (mediaService != null) {
      final sheetItem = SheetMediaItem(
        id: photo.id,
        mediaType: photo.mediaType,
        relativePath: photo.relativePath,
        caption: photo.caption,
      );
      FullscreenMediaLightbox.show(
        context,
        item: sheetItem,
        mediaSandboxService: mediaService!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = theme.isDark ? const Color(0xFFE07A6B) : const Color(0xFFB83B2E);

    return FolioLeafScaffold(
      theme: theme,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopMetadata(accentColor),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  border: Border.all(color: accentColor.withValues(alpha: 0.42), width: 1.4),
                  color: theme.isDark ? Colors.white.withValues(alpha: 0.015) : Colors.white.withValues(alpha: 0.25),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTitleBanner(context, accentColor),
                    const SizedBox(height: 14),
                    Expanded(
                      child: FolioCoverShowcase(
                        leaf: leaf,
                        theme: theme,
                        mediaService: mediaService,
                        onOpenSleeveModal: () => _openPhotoSleeveModal(context),
                        onPhotoTap: (photo) => _handlePhotoTap(context, photo),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildReflectionOrPlaceholder(accentColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildBottomFooter(accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMetadata(Color accentColor) {
    const moodLabels = ['低落', '平淡', '平静', '愉快', '欣喜'];
    final moodText = leaf.mood != null ? moodLabels[(leaf.mood! - 1).clamp(0, 4)] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              border: Border.all(color: accentColor.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              leaf.lunarDate,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: accentColor,
                letterSpacing: 1.0,
                fontFamily: theme.fontFamily,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leaf.weather != null && leaf.weather!.isNotEmpty)
              Text(leaf.weather!, style: TextStyle(fontSize: 10.5, color: theme.inkSecondary)),
            if (moodText != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.inkSecondary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(moodText, style: TextStyle(fontSize: 9.5, color: theme.inkPrimary)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTitleBanner(BuildContext context, Color accentColor) {
    final photoCount = leaf.photos.length;
    final badgeLabel = switch (photoCount) {
      1 => '单幅画心 · 1帧',
      2 => '双屏对幅 · 2帧',
      3 => '三景册页 · 3帧',
      > 3 => '集锦画匣 · $photoCount帧',
      _ => '扉页 · 封面',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leaf.gregorianDate.isNotEmpty
                    ? leaf.gregorianDate
                    : '拾光日记 · 岁时扉页',
                style: TextStyle(fontSize: 10.0, letterSpacing: 1.2, color: theme.inkSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                leaf.entryTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                  fontFamily: theme.fontFamily,
                  color: theme.inkPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: photoCount > 0 ? () => _openPhotoSleeveModal(context) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  border: Border.all(color: accentColor.withValues(alpha: 0.40)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(fontSize: 10.0, color: accentColor, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            if (leaf.isWeeklyReview) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFFD4AF37)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  leaf.weekNumber != null ? '周报 · 第${leaf.weekNumber}周' : '周回顾',
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF9E7812)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildReflectionOrPlaceholder(Color accentColor) {
    if (leaf.isZeroWordDraft) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.06),
          border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '「此卷留白，静待泼墨」',
            style: TextStyle(
              fontSize: 13.0,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w500,
              fontFamily: theme.fontFamily,
              color: accentColor,
            ),
          ),
        ),
      );
    }

    if (leaf.openingReflection != null && leaf.openingReflection!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.06),
          border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 0.8),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          leaf.openingReflection!,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.45,
            fontFamily: theme.fontFamily,
            color: theme.inkPrimary.withValues(alpha: 0.9),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottomFooter(Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '扉页 · 第 1 / ${leaf.totalLeaves} 页',
          style: TextStyle(fontSize: 10.0, letterSpacing: 1.1, color: theme.inkSecondary),
        ),
        if (onTurnForward != null && !leaf.isZeroWordDraft)
          Semantics(
            button: true,
            label: '轻翻展读正文',
            child: GestureDetector(
              onTap: onTurnForward,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Text(
                  '轻翻展读正文 ⇢',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: accentColor),
                ),
              ),
            ),
          )
        else
          Text(leaf.isZeroWordDraft ? '卷末 · 静候落笔' : '', style: TextStyle(fontSize: 10.0, color: theme.inkSecondary)),
      ],
    );
  }
}
