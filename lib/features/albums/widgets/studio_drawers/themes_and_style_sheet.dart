import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../services/album_theme_catalog.dart';
import '../page_background_painter.dart';

/// Modal bottom sheet displaying the 5 curated Photobook Themes ('Themes & Style')
/// for 1-tap application across all pages in the book.
class ThemesAndStyleSheet extends StatelessWidget {
  final String activeThemeId;
  final ValueChanged<String> onSelectTheme;

  const ThemesAndStyleSheet({
    super.key,
    required this.activeThemeId,
    required this.onSelectTheme,
  });

  static Future<void> show(
    BuildContext context, {
    required String activeThemeId,
    required ValueChanged<String> onSelectTheme,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ThemesAndStyleSheet(
        activeThemeId: activeThemeId,
        onSelectTheme: (themeId) {
          onSelectTheme(themeId);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      key: const Key('themes_and_style_sheet'),
      height: screenHeight * 0.78,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: tokens.xuanGround,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(color: tokens.deckleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.style_outlined,
                size: 20,
                color: tokens.cinnabar,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '全书主题与风格 · Themes & Style',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: tokens.jiaomo,
                  ),
                ),
              ),
              IconButton(
                key: const Key('close_themes_sheet_button'),
                icon: Icon(Icons.close, color: tokens.danmo),
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            '选择一套主题装帧，将自动为全书所有内页匹配和谐底色与手绘纹饰',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 12,
              color: tokens.danmo,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: AlbumThemeCatalog.allThemes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final theme = AlbumThemeCatalog.allThemes[index];
                final isSelected = theme.id == activeThemeId;

                return InkWell(
                  key: Key('apply_theme_${theme.id}'),
                  onTap: () => onSelectTheme(theme.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tokens.xuanPureLeaf,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? tokens.cinnabar : tokens.deckleBorder,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Vector Motif Thumbnail
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: tokens.deckleBorder),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: CustomPaint(
                              painter: PageBackgroundPainter(
                                config: theme.defaultBackgroundConfig,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Theme Details & Swatches
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      theme.name,
                                      style: TextStyle(
                                        fontFamily: InkDiaryTheme.fontNotoSerif,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: tokens.jiaomo,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tokens.cinnabarWash,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '当前主题',
                                        style: TextStyle(
                                          fontFamily:
                                              InkDiaryTheme.fontNotoSerif,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: tokens.cinnabar,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                theme.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: InkDiaryTheme.fontNotoSerif,
                                  fontSize: 12,
                                  color: tokens.danmo,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (final swatch in theme.suggestedSwatches)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(
                                            swatch.backgroundColorArgb,
                                          ),
                                          border: Border.all(
                                            color: tokens.deckleBorder,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Aa',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  Color(swatch.textColorArgb),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

