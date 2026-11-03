import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import '../../templates/services/stationery_layout_calculator.dart';
import '../../templates/widgets/template_canvas_container.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/stationery_sheet_configs.dart';
import '../services/editor_pagination_coordinator.dart';
import '../widgets/editor_text_sheet_view.dart';
import '../widgets/paper_heart_metrics.dart';
import '../widgets/stationery_ephemera_sheet.dart';
import '../widgets/stationery_sheet_border_chrome.dart';

/// Variant A: Tactile Stationery Card (信笺台面卡片)
///
/// Metaphor: A tactile physical sheet of handmade paper resting on a scholar's desk.
/// The desk mat has a warm organic tone; the sheet itself is an elevated card with
/// delicate drop shadows and rounded corners, top-anchored with balanced 14-row margins.
class TactileStationeryCardCanvas extends StatelessWidget {
  final StationerySheetThemeConfig themeConfig;
  final StationeryLetterheadConfig letterheadConfig;
  final MediaSandboxService mediaSandboxService;
  final VoidCallback onSaveDraft;
  final EditorPaginationCoordinator coordinator;
  final PageController pageController;
  final int currentSheetIndex;
  final int totalSheets;
  final VoidCallback? onPreviousSheet;
  final VoidCallback? onNextSheet;
  final ValueChanged<int>? onPageChanged;
  final void Function(int sheetIndex)? onDeleteEphemera;
  final void Function(int sheetIndex)? onSpillBack;

  const TactileStationeryCardCanvas({
    super.key,
    required this.themeConfig,
    required this.letterheadConfig,
    required this.mediaSandboxService,
    required this.onSaveDraft,
    required this.coordinator,
    required this.pageController,
    this.currentSheetIndex = 0,
    this.totalSheets = 1,
    this.onPreviousSheet,
    this.onNextSheet,
    this.onPageChanged,
    this.onDeleteEphemera,
    this.onSpillBack,
  });

  @override
  Widget build(BuildContext context) {
    final templateStyle = themeConfig.templateStyle;
    final typography = themeConfig.typography;
    final isDark = themeConfig.isPaperDark;

    // Outer desk mat tone: warm natural parchment / tea-wood in light, deep walnut in dark
    final deskColor = isDark ? const Color(0xFF151413) : const Color(0xFFE9E5DC);

    return LayoutBuilder(
      builder: (layoutContext, layoutConstraints) {
        final canvasWidth = layoutConstraints.maxWidth;
        final canvasHeight = layoutConstraints.maxHeight;

        // Calculate metrics using standard canvas width
        final cardCanvasSize = Size(canvasWidth, math.max(380.0, math.min(canvasHeight, 420.0)));
        final metrics = StationeryLayoutCalculator.calculate(
          canvasSize: cardCanvasSize,
          style: templateStyle,
          typography: typography,
          compactMargins: true,
          maxRows: kStandardFolioRowsPerLeaf,
        );
        final activeRowHeight = metrics.lineStridePx;

        // Card height wraps innerFrameRect with 16px bottom padding
        final cardHeight = math.min(canvasHeight - 40.0, metrics.innerFrameRect.bottom + 16.0);

        // Top margin: anchor gracefully near top (16px) when spacious rather than 200px void
        final double topOffset = (canvasHeight > cardHeight + 48.0)
            ? 16.0
            : math.max(4.0, (canvasHeight - cardHeight) / 2.0);

        final double innerPaddingLeft = (templateStyle.type == TemplateBackgroundType.grid ||
                templateStyle.type == TemplateBackgroundType.dotGrid)
            ? 0.0
            : (templateStyle.type == TemplateBackgroundType.lined ? 32.0 : 20.0);
        final double innerPaddingRight = (templateStyle.type == TemplateBackgroundType.grid ||
                templateStyle.type == TemplateBackgroundType.dotGrid)
            ? 0.0
            : 20.0;

        final usableTextWidth = math.max(
          120.0,
          metrics.innerFrameRect.width - innerPaddingLeft - innerPaddingRight,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          coordinator.syncLayoutMetrics(
            contentWidth: usableTextWidth,
            lineStridePx: activeRowHeight,
          );
        });

        final horizontalLeft = metrics.innerFrameRect.left + innerPaddingLeft;
        final horizontalRight =
            math.max(0.0, canvasWidth - metrics.innerFrameRect.right) + innerPaddingRight;

        return Container(
          color: deskColor,
          child: Stack(
            children: [
              // Desk Mat watermark / subtle desk texture indicator
              Positioned(
                top: 8,
                right: 16,
                child: Opacity(
                  opacity: 0.28,
                  child: Text(
                    '书案 · 案头',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.0,
                      color: isDark ? Colors.white38 : const Color(0xFF6B655B),
                    ),
                  ),
                ),
              ),

              // PageView of Tactile Cards
              PageView.builder(
                controller: pageController,
                itemCount: coordinator.totalSheets,
                physics: const PageScrollPhysics(),
                onPageChanged: onPageChanged,
                itemBuilder: (pageContext, sheetIndex) {
                  if (sheetIndex < 0 || sheetIndex >= coordinator.sheets.length) {
                    return const SizedBox.shrink();
                  }
                  final sheet = coordinator.sheets[sheetIndex];

                  return Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: topOffset),
                      child: Container(
                        width: canvasWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: templateStyle.backgroundColor,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isDark ? const Color(0x33FFFFFF) : const Color(0x1F000000),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                              blurRadius: 18.0,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.03),
                              blurRadius: 4.0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              TemplateCanvasContainer(
                                style: templateStyle,
                                typography: typography,
                                scrollOffset: 0.0,
                                headerHeight: sheet is OpeningSheet ? letterheadConfig.headerHeight : 0.0,
                                layoutMetrics: metrics,
                                customPadding: EdgeInsets.zero,
                                child: const SizedBox.expand(),
                              ),
                              Theme(
                                data: themeConfig.paperBaseTheme.copyWith(
                                  textTheme: themeConfig.paperBaseTheme.textTheme.apply(
                                    bodyColor: themeConfig.inkColor,
                                    displayColor: themeConfig.inkColor,
                                  ),
                                ),
                                child: _buildSheetBody(
                                  sheet: sheet,
                                  sheetIndex: sheetIndex,
                                  metrics: metrics,
                                  activeRowHeight: activeRowHeight,
                                  horizontalLeft: horizontalLeft,
                                  horizontalRight: horizontalRight,
                                ),
                              ),
                              if (currentSheetIndex == totalSheets - 1 && sheetIndex == currentSheetIndex)
                                BoundedCinnabarSeal(
                                  innerFrameRect: metrics.innerFrameRect,
                                  containerSize: Size(canvasWidth, cardHeight),
                                  sealStyle: templateStyle.tokens.sealStyle,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Navigation chevrons and page indicator floating on the desk surface
              StationerySheetBorderChrome(
                currentSheetIndex: currentSheetIndex,
                totalSheets: totalSheets,
                onPreviousSheet: onPreviousSheet,
                onNextSheet: onNextSheet,
                substrate: templateStyle.tokens.substrate,
                isPaperDark: themeConfig.isPaperDark,
                inkColor: themeConfig.inkColor,
                bottomInset: (canvasHeight > cardHeight + topOffset + 40.0)
                    ? (canvasHeight - (cardHeight + topOffset)) / 2.0
                    : 8.0,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetBody({
    required StationerySheetDescriptor sheet,
    required int sheetIndex,
    required StationeryLayoutMetrics metrics,
    required double activeRowHeight,
    required double horizontalLeft,
    required double horizontalRight,
  }) {
    if (sheet is TextStationerySheet) {
      return EditorTextSheetView(
        sheet: sheet,
        sheetIndex: sheetIndex,
        metrics: metrics,
        activeRowHeight: activeRowHeight,
        horizontalLeft: horizontalLeft,
        horizontalRight: horizontalRight,
        themeConfig: themeConfig,
        letterheadConfig: letterheadConfig,
        mediaSandboxService: mediaSandboxService,
        onSaveDraft: onSaveDraft,
        onSpillBack: onSpillBack,
      );
    } else if (sheet is EphemeraSheet) {
      return StationeryEphemeraSheet(
        sheet: sheet,
        innerFrameRect: metrics.innerFrameRect,
        title: letterheadConfig.titleController.text.trim(),
        mediaSandboxService: mediaSandboxService,
        isActiveSheet: currentSheetIndex == sheet.sheetIndex,
        onDelete: onDeleteEphemera != null ? () => onDeleteEphemera!(sheet.sheetIndex) : null,
        onCaptionChanged: (newCaption) => onSaveDraft(),
        isPaperDark: themeConfig.isPaperDark,
        substrate: themeConfig.templateStyle.tokens.substrate,
        inkColor: themeConfig.inkColor,
        fontFamily: themeConfig.typography.fontFamily,
      );
    }
    return const SizedBox.shrink();
  }
}
