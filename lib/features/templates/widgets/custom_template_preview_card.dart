import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../../editor/models/typography_settings.dart';
import '../../editor/widgets/cinnabar_signature_seal.dart';
import '../models/template_style.dart';
import '../services/stationery_layout_calculator.dart';
import 'template_canvas_container.dart';

/// Live interactive stationery preview card shown at the top of custom template editor.
class CustomTemplatePreviewCard extends StatelessWidget {
  final TemplateStyle previewStyle;
  final double lineSpacing;
  final double marginHorizontal;
  final String templateTitle;
  final SealCarvingStyle sealStyle;

  const CustomTemplatePreviewCard({
    super.key,
    required this.previewStyle,
    required this.lineSpacing,
    required this.marginHorizontal,
    required this.templateTitle,
    required this.sealStyle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: tokens.cinnabar,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '案头即时笺样 · LIVE PREVIEW',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: tokens.jiaomo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (previewContext, constraints) {
            final previewWidth = constraints.maxWidth;
            const previewHeight = 190.0;
            final previewTypography = TypographySettings(
              fontSize: 14,
              lineSpacing: lineSpacing,
              fontFamily: previewStyle.fontFamily,
            );
            final previewMetrics = StationeryLayoutCalculator.calculateMetrics(
              canvasWidth: previewWidth,
              canvasHeight: previewHeight,
              backgroundType: previewStyle.type,
              horizontalMargin: marginHorizontal,
              lineSpacing: lineSpacing,
              fontSize: 14,
              compactMargins: true,
            );

            final isPreviewDark =
                ThemeData.estimateBrightnessForColor(previewStyle.backgroundColor) ==
                    Brightness.dark;
            final previewTokens =
                isPreviewDark ? InkDiaryTokens.dark : InkDiaryTokens.light;
            final activeFont = previewStyle.fontFamily;

            final padLeft = previewMetrics.innerFrameRect.left + 16.0;
            final padTop = previewMetrics.innerFrameRect.top + 8.0;
            final padRight = math.max(
              16.0,
              previewWidth - previewMetrics.innerFrameRect.right + 16.0,
            );

            return Container(
              key: const Key('template_live_preview_card'),
              height: previewHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.agedFiber),
                boxShadow: [
                  BoxShadow(
                    color: tokens.jiaomo.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    TemplateCanvasContainer(
                      style: previewStyle,
                      typography: previewTypography,
                      layoutMetrics: previewMetrics,
                      customPadding:
                          EdgeInsets.fromLTRB(padLeft, padTop, padRight, 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '丙午岁九月廿一 · ☀️ 晴朗',
                            style: TextStyle(
                              fontFamily: activeFont ?? 'serif',
                              fontFamilyFallback: const [
                                'Noto Serif SC',
                                'serif',
                              ],
                              fontSize: 11,
                              letterSpacing: 0.5,
                              color: previewTokens.danmo,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            templateTitle.trim().isEmpty
                                ? '秋山晚眺 · 随笔起兴'
                                : templateTitle.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: activeFont ?? 'serif',
                              fontFamilyFallback: const [
                                'Noto Serif SC',
                                'serif',
                              ],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: previewTokens.jiaomo,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              '秋水初凝，晨光微露，案头烹茶一瓯，静观落叶飘飏。\n拾光日记 · 记录每一个值得珍藏的瞬间。',
                              style: TextStyle(
                                fontFamily: activeFont ?? 'serif',
                                fontFamilyFallback: const [
                                  'Noto Serif SC',
                                  'serif',
                                ],
                                fontSize: 13,
                                height: lineSpacing,
                                letterSpacing: 0.3,
                                color: previewTokens.nongmo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: (previewHeight -
                              previewMetrics.innerFrameRect.bottom +
                              8.0)
                          .clamp(8.0, 26.0),
                      right: (previewWidth -
                              previewMetrics.innerFrameRect.right +
                              12.0)
                          .clamp(12.0, 32.0),
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.65,
                          child: CinnabarSignatureSeal(
                            sealStyle: sealStyle,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
