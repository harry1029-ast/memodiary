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

/// Variant C: Screen-Adaptive Row Capacity (屏幕全高满版)
///
/// Metaphor: Immersive, full-screen diary sheet.
/// Instead of clamping the editor to a fixed 14 rows, the paper heart vertically
/// expands to fill the entire device viewport with 26-28 rows at standard 24px stride,
/// maximizing writing space and using smooth viewport scrolling during keyboard input.
class ScreenAdaptiveCanvas extends StatelessWidget {
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

  const ScreenAdaptiveCanvas({
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

        // Calculate unconstrained metrics: maxRows is null so it fills the available canvas
        final metrics = StationeryLayoutCalculator.calculate(
          canvasSize: canvasSize,
          style: templateStyle,
          typography: typography,
          compactMargins: true,
          maxRows: null, // Full-height adaptive row capacity (e.g. 26-28 rows)
        );
        final activeRowHeight = metrics.lineStridePx;

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
            math.max(0.0, layoutConstraints.maxWidth - metrics.innerFrameRect.right) + innerPaddingRight;

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
                        activeRowHeight: activeRowHeight,
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
