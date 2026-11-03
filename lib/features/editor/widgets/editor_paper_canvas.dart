import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import '../../templates/services/stationery_layout_calculator.dart';
import '../../templates/widgets/template_canvas_container.dart';
import '../models/typography_settings.dart';
import 'editor_quill_styles_builder.dart';
import 'integer_snapped_letterhead.dart';
import 'journal_letterhead.dart';
import 'paper_heart_metrics.dart';
import 'sandboxed_image_embed_builder.dart';
import 'sandboxed_video_embed_builder.dart';
import 'stationery_sheet_border_chrome.dart';

/// Full-bleed procedural paper canvas presenting the Letterhead, QuillEditor,
/// bounded Cinnabar Signature Seal, and border navigation chrome.
class EditorPaperCanvas extends StatelessWidget {
  final TemplateStyle templateStyle;
  final TypographySettings typography;
  final ThemeData paperBaseTheme;
  final Color inkColor;
  final bool isPaperDark;
  final ScrollController scrollController;
  final GlobalKey letterheadKey;
  final double headerHeight;
  final DateTime entryDate;
  final int? mood;
  final String? weather;
  final TextEditingController titleController;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int?> onMoodChanged;
  final ValueChanged<String?> onWeatherChanged;
  final QuillController controller;
  final FocusNode focusNode;
  final MediaSandboxService mediaSandboxService;
  final VoidCallback onSaveDraft;
  final int currentSheetIndex;
  final int totalSheets;
  final VoidCallback? onPreviousSheet;
  final VoidCallback? onNextSheet;

  const EditorPaperCanvas({
    super.key,
    required this.templateStyle,
    required this.typography,
    required this.paperBaseTheme,
    required this.inkColor,
    required this.isPaperDark,
    required this.scrollController,
    required this.letterheadKey,
    required this.headerHeight,
    required this.entryDate,
    required this.mood,
    required this.weather,
    required this.titleController,
    required this.onDateChanged,
    required this.onMoodChanged,
    required this.onWeatherChanged,
    required this.controller,
    required this.focusNode,
    required this.mediaSandboxService,
    required this.onSaveDraft,
    this.currentSheetIndex = 0,
    this.totalSheets = 1,
    this.onPreviousSheet,
    this.onNextSheet,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (layoutContext, layoutConstraints) {
        final mediaQuery = MediaQuery.of(layoutContext);
        final unconstrainedScreenHeight = mediaQuery.size.height -
            mediaQuery.padding.top -
            mediaQuery.padding.bottom -
            kToolbarHeight -
            56.0;
        final baseCanvasHeight = math.max(layoutConstraints.maxHeight, unconstrainedScreenHeight);
        final scrollExtent = scrollController.hasClients
            ? scrollController.position.maxScrollExtent
            : 0.0;
        final totalPaperHeight = math.max(baseCanvasHeight, baseCanvasHeight + scrollExtent);
        final canvasSize = Size(layoutConstraints.maxWidth, totalPaperHeight);

        final metrics = StationeryLayoutCalculator.calculate(
          canvasSize: canvasSize,
          style: templateStyle,
          typography: typography,
          compactMargins: true,
        );
        final activeRowHeight = metrics.lineStridePx;

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

        // Viewport-bounded Paper Heart metrics for seal and border chrome placement
        final visibleMetrics = StationeryLayoutCalculator.calculate(
          canvasSize: Size(layoutConstraints.maxWidth, layoutConstraints.maxHeight),
          style: templateStyle,
          typography: typography,
          compactMargins: true,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: scrollController,
                builder: (canvasContext, scrollChild) {
                  final scrollOffset = scrollController.hasClients
                      ? scrollController.offset
                      : 0.0;
                  return TemplateCanvasContainer(
                    style: templateStyle,
                    typography: typography,
                    scrollOffset: scrollOffset,
                    headerHeight: headerHeight,
                    layoutMetrics: metrics,
                    customPadding: EdgeInsets.zero,
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
            Theme(
              data: paperBaseTheme.copyWith(
                textTheme: paperBaseTheme.textTheme.apply(
                  bodyColor: inkColor,
                  displayColor: inkColor,
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.only(top: metrics.heavenMarginPx),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. In-Paper Journal Letterhead wrapped inside IntegerSnappedLetterhead
                    IntegerSnappedLetterhead(
                      key: letterheadKey,
                      lineStridePx: activeRowHeight,
                      child: Container(
                        padding: EdgeInsets.only(
                          left: horizontalLeft,
                          right: horizontalRight,
                          top: 8.0,
                          bottom: 8.0,
                        ),
                        child: JournalLetterhead(
                          entryDate: entryDate,
                          mood: mood,
                          weather: weather,
                          titleController: titleController,
                          onDateChanged: onDateChanged,
                          onMoodChanged: onMoodChanged,
                          onWeatherChanged: onWeatherChanged,
                        ),
                      ),
                    ),

                    // 2. Quill Editor Content with contextual margin alignment
                    Padding(
                      padding: EdgeInsets.only(
                        left: horizontalLeft,
                        right: horizontalRight,
                        bottom: 120.0,
                      ),
                      child: QuillEditor(
                        controller: controller,
                        focusNode: focusNode,
                        scrollController: scrollController,
                        config: QuillEditorConfig(
                          placeholder: '提笔落墨，且将心事付素笺... Write your heart out today...',
                          expands: false,
                          scrollable: false,
                          embedBuilders: [
                            SandboxedImageEmbedBuilder(
                              mediaSandboxService: mediaSandboxService,
                              onImageRemoved: onSaveDraft,
                              onEmbedMutated: (mutatedBlock) => onSaveDraft(),
                              rowHeight: activeRowHeight,
                            ),
                            SandboxedVideoEmbedBuilder(
                              mediaSandboxService: mediaSandboxService,
                              onVideoRemoved: onSaveDraft,
                              onEmbedMutated: (mutatedBlock) => onSaveDraft(),
                              rowHeight: activeRowHeight,
                            ),
                          ],
                          customStyles: EditorQuillStylesBuilder.build(
                            typography: typography,
                            inkColor: inkColor,
                            isPaperDark: isPaperDark,
                            lineStridePx: activeRowHeight,
                            backgroundType: templateStyle.type,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Live Cinnabar Signature Seal anchored strictly inside Paper Heart
            BoundedCinnabarSeal(
              innerFrameRect: visibleMetrics.innerFrameRect,
              containerSize: Size(layoutConstraints.maxWidth, layoutConstraints.maxHeight),
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
}
