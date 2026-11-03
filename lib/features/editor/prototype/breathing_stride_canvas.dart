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

/// Variant B: Dynamic Breathing Stride (自适应呼吸行距)
///
/// Metaphor: Classical manuscript with breathing line stride (宽行阔栏).
/// Maintains 100% 1:1 Folio leaf row-count parity (strictly 14 rows per leaf),
/// but allows line stride to expand from 24px (compact) up to 42px (reading/overview)
/// so the paper heart and double outer border gracefully fill the available vertical canvas.
class BreathingStrideCanvas extends StatelessWidget {
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

  const BreathingStrideCanvas({
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

    return LayoutBuilder(
      builder: (layoutContext, layoutConstraints) {
        final canvasSize = Size(layoutConstraints.maxWidth, layoutConstraints.maxHeight);
        final canvasHeight = canvasSize.height;

        // Calculate dynamic breathing line stride
        // Minimum margins: Heaven ~38px, Earth ~34px -> total ~72px
        final availableHeight = math.max(336.0, canvasHeight - 72.0);
        final rawStride = (availableHeight / kStandardFolioRowsPerLeaf).floorToDouble();
        final breathingStride = rawStride.clamp(24.0, 42.0);

        final totalInnerHeight = kStandardFolioRowsPerLeaf * breathingStride;
        final totalVerticalMargin = math.max(16.0, canvasHeight - totalInnerHeight);
        final heavenMargin = (totalVerticalMargin * 0.52).roundToDouble();
        final earthMargin = totalVerticalMargin - heavenMargin;

        // Horizontal geometry
        final clampedMarginX = templateStyle.resolvedHorizontalMargin.clamp(16.0, 36.0);
        final isGridLike = templateStyle.type == TemplateBackgroundType.grid ||
            templateStyle.type == TemplateBackgroundType.dotGrid;
        final cellAdvance = isGridLike ? breathingStride : (typography.fontSize);
        final availableWidth = math.max(cellAdvance, canvasSize.width - 2.0 * clampedMarginX);
        final columnCount = math.max(1, (availableWidth / cellAdvance).floor());
        final snappedWidth = columnCount * cellAdvance;
        final leftOffset = math.max(0.0, ((canvasSize.width - snappedWidth) / 2.0).roundToDouble());

        final innerFrameRect = Rect.fromLTWH(
          leftOffset,
          heavenMargin,
          snappedWidth,
          totalInnerHeight,
        );

        final metrics = StationeryLayoutMetrics(
          fontSize: typography.fontSize,
          lineStridePx: breathingStride,
          cellAdvancePx: cellAdvance,
          innerFrameRect: innerFrameRect,
          columnCount: columnCount,
          rowCount: kStandardFolioRowsPerLeaf,
          heavenMarginPx: heavenMargin,
          earthMarginPx: earthMargin,
        );

        final double innerPaddingLeft = (isGridLike)
            ? 0.0
            : (templateStyle.type == TemplateBackgroundType.lined ? 32.0 : 20.0);
        final double innerPaddingRight = isGridLike ? 0.0 : 20.0;

        final usableTextWidth = math.max(
          120.0,
          innerFrameRect.width - innerPaddingLeft - innerPaddingRight,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          coordinator.syncLayoutMetrics(
            contentWidth: usableTextWidth,
            lineStridePx: breathingStride,
          );
        });

        final horizontalLeft = innerFrameRect.left + innerPaddingLeft;
        final horizontalRight =
            math.max(0.0, layoutConstraints.maxWidth - innerFrameRect.right) + innerPaddingRight;

        return Stack(
          fit: StackFit.expand,
          children: [
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

                return Stack(
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
                        activeRowHeight: breathingStride,
                        horizontalLeft: horizontalLeft,
                        horizontalRight: horizontalRight,
                      ),
                    ),
                  ],
                );
              },
            ),
            if (currentSheetIndex == totalSheets - 1)
              BoundedCinnabarSeal(
                innerFrameRect: metrics.innerFrameRect,
                containerSize: canvasSize,
                sealStyle: templateStyle.tokens.sealStyle,
              ),
            StationerySheetBorderChrome(
              currentSheetIndex: currentSheetIndex,
              totalSheets: totalSheets,
              onPreviousSheet: onPreviousSheet,
              onNextSheet: onNextSheet,
              substrate: templateStyle.tokens.substrate,
              isPaperDark: themeConfig.isPaperDark,
              inkColor: themeConfig.inkColor,
            ),
          ],
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
