import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/cinnabar_seal_badge.dart';
import '../../../core/theme/widgets/ink_metadata_pill.dart';
import '../../../core/theme/widgets/xuan_paper_card.dart';
import 'sandboxed_album_image.dart';

/// Contextual actions supported on an [AlbumCollectionCard].
enum AlbumCardAction {
  edit,
  setCover,
  delete,
}

/// Literati Xuan-paper summary card representing a travel memory album collection.
///
/// Renders the title, optional regional vermilion seal (`destinationTag`, e.g. `"江南"`),
/// poetic description prologue, 16:9 cover image preview, route trajectory footer
/// (`📍 杭州 → 乌镇 → 苏州`), and clamped metadata pills (date range & photo count).
class AlbumCollectionCard extends StatelessWidget {
  final AlbumCollection collection;
  final int photoCount;
  final MediaSandboxService mediaService;
  final VoidCallback onTap;
  final ValueChanged<AlbumCardAction>? onActionSelected;

  const AlbumCollectionCard({
    super.key,
    required this.collection,
    required this.photoCount,
    required this.mediaService,
    required this.onTap,
    this.onActionSelected,
  });

  static String formatDateRange(DateTime? startDate, DateTime? endDate) {
    final fmt = DateFormat('yyyy.MM.dd');
    final shortEndFmt = DateFormat('MM.dd');
    if (startDate != null && endDate != null) {
      if (startDate.year == endDate.year) {
        return '${fmt.format(startDate)} – ${shortEndFmt.format(endDate)}';
      }
      return '${fmt.format(startDate)} – ${fmt.format(endDate)}';
    }
    if (startDate != null) {
      return fmt.format(startDate);
    }
    if (endDate != null) {
      return fmt.format(endDate);
    }
    return '未设行程日期';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final dateLabel = formatDateRange(collection.startDate, collection.endDate);
    final destination = collection.destinationTag?.trim();
    final description = collection.description?.trim();
    final route = collection.routeSummary?.trim();

    return XuanPaperCard(
      key: Key('album_card_${collection.id}'),
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header row: Title + Cinnabar Destination Seal + Contextual Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  collection.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: tokens.jiaomo,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (destination != null && destination.isNotEmpty) ...[
                const SizedBox(width: 8),
                CinnabarSealBadge.compact(
                  text: destination,
                  size: 28,
                ),
              ],
              if (onActionSelected != null) ...[
                const SizedBox(width: 4),
                Semantics(
                  label: '更多操作：${collection.title}',
                  button: true,
                  child: PopupMenuButton<AlbumCardAction>(
                    key: Key('album_card_menu_${collection.id}'),
                    tooltip: '更多操作',
                    icon: Icon(
                      Icons.more_horiz,
                      size: 20,
                      color: tokens.danmo,
                    ),
                    onSelected: onActionSelected,
                    itemBuilder: (context) => [
                      PopupMenuItem<AlbumCardAction>(
                        value: AlbumCardAction.edit,
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: tokens.nongmo,
                            ),
                            const SizedBox(width: 10),
                            const Text('编辑影集信息'),
                          ],
                        ),
                      ),
                      PopupMenuItem<AlbumCardAction>(
                        value: AlbumCardAction.setCover,
                        child: Row(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 20,
                              color: tokens.nongmo,
                            ),
                            const SizedBox(width: 10),
                            const Text('更换封面照片'),
                          ],
                        ),
                      ),
                      PopupMenuItem<AlbumCardAction>(
                        value: AlbumCardAction.delete,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: tokens.cinnabar,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '删除影集',
                              style: TextStyle(color: tokens.cinnabar),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // 2. Subtitle / Prologue
          const SizedBox(height: 4),
          Text(
            description != null && description.isNotEmpty
                ? description
                : '山河沿路，笔底留痕',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 13,
              color: tokens.danmo,
              height: 1.4,
            ),
          ),

          // 3. 16:9 Cover Image Frame
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: SandboxedAlbumImage(
              relativePath: collection.coverImagePath,
              mediaService: mediaService,
              cacheWidth: 720,
              borderRadius: 8,
              width: double.infinity,
              placeholderLabel: '尚未添加旅途影像',
            ),
          ),

          // 4. Route Trajectory Line ("📍 杭州 → 乌镇 → 苏州")
          if (route != null && route.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: tokens.cinnabar,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    route,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: tokens.nongmo,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // 5. Metadata Pills (Date Range & Photo Count) with clamped text scaling
          const SizedBox(height: 12),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                InkMetadataPill(
                  icon: Icons.calendar_today_outlined,
                  label: dateLabel,
                  maxWidth: 180,
                ),
                InkMetadataPill(
                  icon: Icons.photo_camera_outlined,
                  label: '$photoCount 张',
                  isAccent: photoCount > 0,
                  maxWidth: 120,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

