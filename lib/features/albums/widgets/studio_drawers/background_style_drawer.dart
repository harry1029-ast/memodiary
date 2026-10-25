import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../models/album_studio_models.dart';
import '../../services/album_theme_catalog.dart';
import '../page_background_painter.dart';

/// Studio bottom drawer ('Page Colors & Graphics') allowing the user to customize
/// the active page's background color (with auto-contrasting `Aa` text preview),
/// reuse recent colors, and apply procedural vector graphic motifs.
class BackgroundStyleDrawer extends StatelessWidget {
  final PageBackgroundConfig currentConfig;
  final List<int> recentColors;
  final ValueChanged<PageBackgroundConfig> onUpdateBackground;
  final VoidCallback onClose;

  const BackgroundStyleDrawer({
    super.key,
    required this.currentConfig,
    required this.recentColors,
    required this.onUpdateBackground,
    required this.onClose,
  });

  void _selectColor(int bgArgb, int textArgb) {
    onUpdateBackground(
      currentConfig.copyWith(
        backgroundColorArgb: bgArgb,
        textColorArgb: textArgb,
      ),
    );
  }

  void _selectGraphicPattern(String patternId) {
    onUpdateBackground(
      currentConfig.copyWith(
        graphicPatternId: patternId == 'none' ? null : patternId,
        clearGraphicPattern: patternId == 'none',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final activePatternId = currentConfig.graphicPatternId ?? 'none';

    return Container(
      key: const Key('studio_background_style_drawer'),
      height: 295,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: tokens.xuanPureLeaf,
        border: Border(
          top: BorderSide(color: tokens.deckleBorder, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 18,
                color: tokens.cinnabar,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '底色与纸本纹饰 · Page Colors & Graphics',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tokens.jiaomo,
                  ),
                ),
              ),
              IconButton(
                key: const Key('close_background_drawer_button'),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.expand_more, color: tokens.danmo),
                tooltip: '收起面板',
                onPressed: onClose,
              ),
            ],
          ),
          // 1. Suggested Swatches with 'Aa' Contrast Preview
          Text(
            '推荐配色 · Suggested Colors',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 11.5,
              color: tokens.danmo,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AlbumThemeCatalog.universalSwatches.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final swatch = AlbumThemeCatalog.universalSwatches[index];
                final isSelected = currentConfig.backgroundColorArgb ==
                    swatch.backgroundColorArgb;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: swatch.label,
                  child: InkWell(
                    key: Key(
                      'bg_swatch_${swatch.backgroundColorArgb.toRadixString(16)}',
                    ),
                    onTap: () => _selectColor(
                      swatch.backgroundColorArgb,
                      swatch.textColorArgb,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(swatch.backgroundColorArgb),
                        border: Border.all(
                          color: isSelected
                              ? tokens.cinnabar
                              : tokens.deckleBorder,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Aa',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(swatch.textColorArgb),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // 2. Recent Colors Row
          if (recentColors.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 26,
              child: Row(
                children: [
                  Text(
                    '最近使用：',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 11,
                      color: tokens.danmo,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentColors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final argb = recentColors[index];
                        final contrastText =
                            ColorSwatchOption.contrastingTextColorFor(argb);
                        return InkWell(
                          key: Key('recent_color_${argb.toRadixString(16)}'),
                          onTap: () => _selectColor(argb, contrastText),
                          borderRadius: BorderRadius.circular(13),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(argb),
                              border: Border.all(color: tokens.deckleBorder),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          // 3. Background Vector Graphic Patterns
          Text(
            '背景纹饰 · Background Graphics',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 11.5,
              color: tokens.danmo,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AlbumThemeCatalog.allGraphicPatterns.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final pattern = AlbumThemeCatalog.allGraphicPatterns[index];
                final isSelected = activePatternId == pattern.id;
                final previewConfig = currentConfig.copyWith(
                  graphicPatternId: pattern.id == 'none' ? null : pattern.id,
                  clearGraphicPattern: pattern.id == 'none',
                );

                return InkWell(
                  key: Key('bg_graphic_${pattern.id}'),
                  onTap: () => _selectGraphicPattern(pattern.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isSelected ? tokens.cinnabar : tokens.deckleBorder,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            child: CustomPaint(
                              painter: PageBackgroundPainter(
                                config: previewConfig,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? tokens.cinnabarWash
                                : tokens.agedFiber,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(6),
                            ),
                          ),
                          child: Text(
                            pattern.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontNotoSerif,
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color:
                                  isSelected ? tokens.cinnabar : tokens.nongmo,
                            ),
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
