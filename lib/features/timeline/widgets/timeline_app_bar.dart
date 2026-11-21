import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/ocr/ocr_queue_manager.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/octagonal_medallion_button.dart';
import 'package:memodiary/features/intro/screens/book_intro_screen.dart';
import 'package:memodiary/features/scenery/services/scenery_settings_service.dart';
import 'package:memodiary/features/search/screens/search_screen.dart';
import 'package:memodiary/features/settings/screens/settings_screen.dart';
import 'package:memodiary/features/weekly_review/screens/weekly_review_screen.dart';

/// Top AppBar for [TimelineScreen] styled as a wooden casement lintel featuring
/// Yunhao branding, a back-to-cover Cloud-Moon emblem button, and three
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

  /// Replaces the Home Shell with the cover (the cover is never kept below it).
  void _navigateBackToCover(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => BookIntroScreen(
          database: database,
          mediaService: mediaService,
          ocrQueueManager: ocrQueueManager,
        ),
      ),
    );
  }

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
            _BackToCoverEmblemButton(
              key: const Key('timeline_back_to_cover_button'),
              palette: palette,
              onTap: () => _navigateBackToCover(context),
            ),
            const SizedBox(width: 8),
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

class _BackToCoverEmblemButton extends StatelessWidget {
  final AtmospherePalette palette;
  final VoidCallback onTap;

  const _BackToCoverEmblemButton({
    super.key,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: true,
      label: '返回封面',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Center(
              widthFactor: 1.0,
              heightFactor: 1.0,
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(3, 4, 5, 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: palette.accentPrimary.withValues(alpha: 0.55),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 16,
                        color: palette.headerTitleText,
                      ),
                      const SizedBox(width: 2),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [palette.woodFrameMid, palette.woodFrameDark],
                          ),
                          border: Border.all(
                            color: palette.accentPrimary,
                            width: 1.2,
                          ),
                        ),
                        child: CustomPaint(
                          painter: _CloudMoonEmblemPainter(
                            primaryColor: palette.headerTitleText,
                            accentColor: palette.accentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloudMoonEmblemPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  const _CloudMoonEmblemPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24.0;
    final sy = size.height / 24.0;
    canvas.save();
    canvas.scale(sx, sy);

    final moonFillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(13.0, 9.5), 4.6, moonFillPaint);

    final primaryStroke = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3;
    canvas.drawCircle(const Offset(13.0, 9.5), 4.6, primaryStroke);

    final upperCloudPath = Path()
      ..moveTo(4.0, 15.0)
      ..quadraticBezierTo(9.8, 12.2, 15.6, 14.6)
      ..quadraticBezierTo(18.6, 15.8, 21.0, 13.6);
    canvas.drawPath(upperCloudPath, primaryStroke..strokeWidth = 1.45);

    final accentStroke = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;
    final lowerCloudPath = Path()
      ..moveTo(6.2, 17.6)
      ..quadraticBezierTo(12.2, 15.6, 18.4, 17.6);
    canvas.drawPath(lowerCloudPath, accentStroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CloudMoonEmblemPainter oldDelegate) {
    return primaryColor != oldDelegate.primaryColor ||
        accentColor != oldDelegate.accentColor;
  }
}
