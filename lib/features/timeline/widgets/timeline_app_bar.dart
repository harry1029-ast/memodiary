import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/ocr/ocr_queue_manager.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/octagonal_medallion_button.dart';
import 'package:memodiary/features/home/widgets/cloud_avatar.dart';
import 'package:memodiary/features/scenery/services/scenery_settings_service.dart';
import 'package:memodiary/features/search/screens/search_screen.dart';
import 'package:memodiary/features/settings/screens/settings_screen.dart';
import 'package:memodiary/features/weekly_review/screens/weekly_review_screen.dart';

/// Top AppBar for [TimelineScreen] styled as a wooden casement lintel featuring
/// Yunhao branding, the Diarist Panel's cloud-avatar button (`我的`), and three
/// octagonal medallions (`每周复盘`, `搜索`, `设置`).
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

  Widget _buildHeaderMedallion({
    required Key key,
    required IconData icon,
    required String tooltip,
    required AtmospherePalette palette,
    required EdgeInsetsGeometry padding,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: padding,
      child: OctagonalMedallionButton(
        key: key,
        icon: icon,
        tooltip: tooltip,
        iconColor: palette.headerTitleText,
        borderColor: Colors.white.withValues(alpha: 0.24),
        bevelColor: Colors.white.withValues(alpha: 0.14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 10,
      backgroundColor: palette.woodFrameDark,
      foregroundColor: palette.headerTitleText,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
        ),
      ),
      title: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Row(
          children: [
            const DiaristAvatarButton(key: Key('timeline_avatar_button')),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        flex: 5,
                        child: Text(
                          '云皓日记',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: palette.headerTitleText,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        flex: 4,
                        child: Text(
                          'YUNHAO',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                            color: palette.headerSubText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '云伴皓光 · 收录旅途与心事',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: palette.headerSubText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        _buildHeaderMedallion(
          key: const Key('timeline_weekly_review_button'),
          icon: Icons.calendar_view_week_rounded,
          tooltip: '每周复盘',
          palette: palette,
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
        _buildHeaderMedallion(
          key: const Key('timeline_search_button'),
          icon: Icons.search_rounded,
          tooltip: '搜索',
          palette: palette,
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
        _buildHeaderMedallion(
          key: const Key('timeline_settings_button'),
          icon: Icons.settings_outlined,
          tooltip: '设置',
          palette: palette,
          padding: const EdgeInsets.only(left: 4, right: 12),
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
      ],
    );
  }
}
