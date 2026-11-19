import 'package:flutter/material.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/ocr/ocr_queue_manager.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/cinnabar_seal_badge.dart';
import 'package:memodiary/core/theme/widgets/octagonal_medallion_button.dart';
import 'package:memodiary/features/scenery/services/scenery_settings_service.dart';
import 'package:memodiary/features/search/screens/search_screen.dart';
import 'package:memodiary/features/settings/screens/settings_screen.dart';
import 'package:memodiary/features/weekly_review/screens/weekly_review_screen.dart';

/// Top AppBar for [TimelineScreen] featuring the `墨记` seal badge, brand title,
/// and three octagonal medallions (`周志复盘`, `检索墨痕`, `设置与私隐`).
class TimelineAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final OcrQueueManager? ocrQueueManager;
  final ScenerySettingsService scenerySettings;
  final VoidCallback onReturnFromSubscreen;
  final VoidCallback onReturnFromSettings;

  const TimelineAppBar({
    super.key,
    required this.database,
    required this.mediaService,
    required this.ocrQueueManager,
    required this.scenerySettings,
    required this.onReturnFromSubscreen,
    required this.onReturnFromSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CinnabarSealBadge.compact(
            text: '墨记',
            size: 28,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'MemoDiary',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: tokens.jiaomo,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '云皓日记',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.danmo,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  '个人离线日记',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                    color: tokens.danmo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OctagonalMedallionButton(
            key: const Key('timeline_weekly_review_button'),
            icon: Icons.calendar_view_week_rounded,
            tooltip: '每周复盘',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeeklyReviewScreen(
                    database: database,
                    mediaService: mediaService,
                  ),
                ),
              ).then((_) => onReturnFromSubscreen());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OctagonalMedallionButton(
            key: const Key('timeline_search_button'),
            icon: Icons.search_rounded,
            tooltip: '搜索',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    database: database,
                    mediaService: mediaService,
                    ocrQueueManager: ocrQueueManager,
                  ),
                ),
              ).then((_) => onReturnFromSubscreen());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 12),
          child: OctagonalMedallionButton(
            key: const Key('timeline_settings_button'),
            icon: Icons.settings_outlined,
            tooltip: '设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    database: database,
                    mediaService: mediaService,
                    ocrQueueManager: ocrQueueManager,
                    scenerySettingsService: scenerySettings,
                  ),
                ),
              ).then((_) => onReturnFromSettings());
            },
          ),
        ),
      ],
    );
  }
}
