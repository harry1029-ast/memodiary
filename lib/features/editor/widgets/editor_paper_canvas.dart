import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import '../../templates/services/stationery_layout_calculator.dart';
import '../../templates/widgets/template_canvas_container.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/stationery_sheet_configs.dart';
import '../services/editor_pagination_coordinator.dart';
import 'editor_text_sheet_view.dart';
import 'paper_heart_metrics.dart';
import 'stationery_ephemera_sheet.dart';
import 'stationery_sheet_border_chrome.dart';

/// Full-bleed procedural paper canvas presenting discrete Stationery Sheets in a PageView stage,
/// with Sheet 1 Journal Letterhead, Sheet 2+ running colophons, full-sheet Ephemera mounts,
/// final-sheet-only bounded Cinnabar Seal, and paper-adaptive border navigation chrome.
class EditorPaperCanvas extends StatelessWidget {
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

  const EditorPaperCanvas({
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

        final metrics = StationeryLayoutCalculator.calculate(
          canvasSize: canvasSize,
          style: templateStyle,
          typography: typography,
          compactMargins: true,
          maxRows: kStandardFolioRowsPerLeaf,
        );
        final activeRowHeight = metrics.lineStridePx;

        final double innerContentPaddingLeft;
        if (templateStyle.type == TemplateBackgroundType.grid ||
            templateStyle.type == TemplateBackgroundType.dotGrid) {
          innerContentPaddingLeft = 0.0;
        } else if (templateStyle.type == TemplateBackgroundType.lined) {
          innerContentPaddingLeft = 32.0;
        } else {
          innerContentPaddingLeft = 20.0;
        }
        final double innerContentPaddingRight =
            (templateStyle.type == TemplateBackgroundType.grid ||
                    templateStyle.type == TemplateBackgroundType.dotGrid)
                ? 0.0
                : 20.0;

        final usableTextWidth = math.max(
          120.0,
          metrics.innerFrameRect.width - innerContentPaddingLeft - innerContentPaddingRight,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          coordinator.syncLayoutMetrics(
            contentWidth: usableTextWidth,
            lineStridePx: activeRowHeight,
          );
        });

        final horizontalLeft = metrics.innerFrameRect.left + innerContentPaddingLeft;
        final horizontalRight =
            math.max(0.0, layoutConstraints.maxWidth - metrics.innerFrameRect.right) +
                innerContentPaddingRight;

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
                      headerHeight:
                          sheet is OpeningSheet ? letterheadConfig.headerHeight : 0.0,
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
        onDelete:
            onDeleteEphemera != null ? () => onDeleteEphemera!(sheet.sheetIndex) : null,
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
