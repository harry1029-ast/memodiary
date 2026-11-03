import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import '../../templates/services/stationery_layout_calculator.dart';
import '../../templates/widgets/template_canvas_container.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/typography_settings.dart';
import '../services/editor_pagination_coordinator.dart';
import 'editor_text_sheet_view.dart';
import 'paper_heart_metrics.dart';
import 'stationery_ephemera_sheet.dart';
import 'stationery_sheet_border_chrome.dart';

/// Full-bleed procedural paper canvas presenting discrete Stationery Sheets in a PageView stage,
/// with Sheet 1 Journal Letterhead, Sheet 2+ running colophons, full-sheet Ephemera mounts,
/// final-sheet-only bounded Cinnabar Seal, and paper-adaptive border navigation chrome.
class EditorPaperCanvas extends StatelessWidget {
  final TemplateStyle templateStyle;
  final TypographySettings typography;
  final ThemeData paperBaseTheme;
  final Color inkColor;
  final bool isPaperDark;
  final GlobalKey letterheadKey;
  final double headerHeight;
  final DateTime entryDate;
  final int? mood;
  final String? weather;
  final TextEditingController titleController;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int?> onMoodChanged;
  final ValueChanged<String?> onWeatherChanged;
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

  final QuillController? controller;
  final FocusNode? focusNode;
  final ScrollController? scrollController;

  const EditorPaperCanvas({
    super.key,
    required this.templateStyle,
    required this.typography,
    required this.paperBaseTheme,
    required this.inkColor,
    required this.isPaperDark,
    required this.letterheadKey,
    required this.headerHeight,
    required this.entryDate,
    required this.mood,
    required this.weather,
    required this.titleController,
    required this.onDateChanged,
    required this.onMoodChanged,
    required this.onWeatherChanged,
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
    this.controller,
    this.focusNode,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (layoutContext, layoutConstraints) {
        final canvasSize = Size(layoutConstraints.maxWidth, layoutConstraints.maxHeight);

        final metrics = StationeryLayoutCalculator.calculate(
          canvasSize: canvasSize,
          style: templateStyle,
          typography: typography,
          compactMargins: true,
        );
        final activeRowHeight = metrics.lineStridePx;

        // Synchronize coordinator metrics
        coordinator.contentWidth = metrics.innerFrameRect.width;
        coordinator.lineStridePx = activeRowHeight;

        // Inner content padding from Paper Heart border
        final double innerContentPaddingLeft;
        if (templateStyle.type == TemplateBackgroundType.grid ||
            templateStyle.type == TemplateBackgroundType.dotGrid) {
          innerContentPaddingLeft = 0.0;
        } else if (templateStyle.type == TemplateBackgroundType.lined) {
          innerContentPaddingLeft = 32.0;
        } else {
          innerContentPaddingLeft = 20.0;
        }
        final double innerContentPaddingRight = (templateStyle.type == TemplateBackgroundType.grid ||
                templateStyle.type == TemplateBackgroundType.dotGrid)
            ? 0.0
            : 20.0;

        final horizontalLeft = metrics.innerFrameRect.left + innerContentPaddingLeft;
        final horizontalRight = math.max(0.0, layoutConstraints.maxWidth - metrics.innerFrameRect.right) +
            innerContentPaddingRight;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Horizontal PageView stage (~280ms easeOutCubic transitions)
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
                    // 1. Procedural Template Canvas per sheet
                    TemplateCanvasContainer(
                      style: templateStyle,
                      typography: typography,
                      scrollOffset: 0.0,
                      headerHeight: sheet is OpeningSheet ? headerHeight : 0.0,
                      layoutMetrics: metrics,
                      customPadding: EdgeInsets.zero,
                      child: const SizedBox.expand(),
                    ),

                    // 2. Paper content theme
                    Theme(
                      data: paperBaseTheme.copyWith(
                        textTheme: paperBaseTheme.textTheme.apply(
                          bodyColor: inkColor,
                          displayColor: inkColor,
                        ),
                      ),
                      child: _buildSheetBody(
                        sheet: sheet,
                        sheetIndex: sheetIndex,
                        metrics: metrics,
                        activeRowHeight: activeRowHeight,
                        horizontalLeft: horizontalLeft,
                        horizontalRight: horizontalRight,
                        maxWidth: layoutConstraints.maxWidth,
                      ),
                    ),
                  ],
                );
              },
            ),

            // Live Cinnabar Signature Seal renders ONLY on the final sheet
            if (currentSheetIndex == totalSheets - 1)
              BoundedCinnabarSeal(
                innerFrameRect: metrics.innerFrameRect,
                containerSize: canvasSize,
                sealStyle: templateStyle.tokens.sealStyle,
              ),

            // Paper-adaptive navigation chevrons and bottom page counter
            StationerySheetBorderChrome(
              currentSheetIndex: currentSheetIndex,
              totalSheets: totalSheets,
              onPreviousSheet: onPreviousSheet,
              onNextSheet: onNextSheet,
              substrate: templateStyle.tokens.substrate,
              isPaperDark: isPaperDark,
              inkColor: inkColor,
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
    required double maxWidth,
  }) {
    if (sheet is TextStationerySheet) {
      return EditorTextSheetView(
        sheet: sheet,
        sheetIndex: sheetIndex,
        metrics: metrics,
        activeRowHeight: activeRowHeight,
        horizontalLeft: horizontalLeft,
        horizontalRight: horizontalRight,
        templateStyle: templateStyle,
        typography: typography,
        inkColor: inkColor,
        isPaperDark: isPaperDark,
        letterheadKey: letterheadKey,
        entryDate: entryDate,
        mood: mood,
        weather: weather,
        titleController: titleController,
        onDateChanged: onDateChanged,
        onMoodChanged: onMoodChanged,
        onWeatherChanged: onWeatherChanged,
        mediaSandboxService: mediaSandboxService,
        onSaveDraft: onSaveDraft,
        onSpillBack: onSpillBack,
      );
    } else if (sheet is EphemeraSheet) {
      return StationeryEphemeraSheet(
        sheet: sheet,
        innerFrameRect: metrics.innerFrameRect,
        title: titleController.text.trim(),
        mediaSandboxService: mediaSandboxService,
        isActiveSheet: currentSheetIndex == sheet.sheetIndex,
        onDelete: onDeleteEphemera != null ? () => onDeleteEphemera!(sheet.sheetIndex) : null,
        onCaptionChanged: (newCaption) => onSaveDraft(),
        isPaperDark: isPaperDark,
        substrate: templateStyle.tokens.substrate,
        inkColor: inkColor,
        fontFamily: typography.fontFamily,
      );
    }
    return const SizedBox.shrink();
  }
}
