import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import '../../templates/services/stationery_layout_calculator.dart';
import '../../templates/widgets/template_canvas_container.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/stationery_sheet_configs.dart';
import '../services/editor_pagination_coordinator.dart';
import 'editor_desk_media_area.dart';
import 'editor_text_sheet_view.dart';
import 'paper_heart_metrics.dart';
import 'stationery_ephemera_sheet.dart';
import 'stationery_sheet_border_chrome.dart';

/// Tactile Split Desk procedural paper canvas presenting discrete Stationery Sheets
/// resting on a scholar's writing desk.
///
/// Beneath the active sheet rest its Sheet Mount Strip and the Staging Handscroll.
/// When the sheet has no mounted items and the handscroll is empty, the 14-row integer-locked
/// stationery card automatically centers vertically on the desk mat with the diarist's
/// Cinnabar Signature Seal resting cleanly beneath it, eliminating empty whitespace voids.
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
  final ValueChanged<String>? onMountMedia;
  final ValueChanged<String>? onEraseMedia;
  final ValueChanged<String>? onUnmountMedia;
  final ValueListenable<int>? mountRefusals;
  final void Function(String mediaId, String newCaption)? onMediaCaptionChanged;
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
    this.onMountMedia,
    this.onEraseMedia,
    this.onUnmountMedia,
    this.mountRefusals,
    this.onMediaCaptionChanged,
    this.onSpillBack,
  });

  @override
  Widget build(BuildContext context) {
    final templateStyle = themeConfig.templateStyle;
    final typography = themeConfig.typography;
    final isDark = themeConfig.isPaperDark;

    // Scholar desk mat tone: warm parchment / tea-wood in light, deep walnut in dark
    final deskColor = isDark ? const Color(0xFF151413) : const Color(0xFFE9E5DC);

    return LayoutBuilder(
      builder: (layoutContext, layoutConstraints) {
        final canvasWidth = layoutConstraints.maxWidth;
        final canvasHeight = layoutConstraints.maxHeight;

        // Bounded card canvas dimensions for integer-locked 14-row calculation
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
        final cardHeight = metrics.innerFrameRect.bottom + 16.0;

        // Resolve the active sheet's mounted items and the staged handscroll items
        final activeSheet = (currentSheetIndex >= 0 && currentSheetIndex < coordinator.sheets.length)
            ? coordinator.sheets[currentSheetIndex]
            : (coordinator.sheets.isNotEmpty ? coordinator.sheets.first : null);
        final mountedItems = activeSheet is TextStationerySheet
            ? List<SheetMediaItem>.unmodifiable(activeSheet.mediaAttachments)
            : const <SheetMediaItem>[];
        final stagedItems = coordinator.stagedItems;

        final bool hasAttachments = mountedItems.isNotEmpty || stagedItems.isNotEmpty;

        final bool keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

        const sealSize = PaperHeartMetrics.kDefaultSealSize;
        const sealGap = 16.0;
        const sealBlockHeight = sealSize + sealGap;

        // Vertical centering on the scholar's desk mat:
        // For text-only entries: center card and seal as a unified vertical unit when keyboard is closed
        final double topOffset;
        if (!hasAttachments && !keyboardVisible && canvasHeight > cardHeight + sealBlockHeight + 24.0) {
          topOffset = math.max(12.0, (canvasHeight - cardHeight - sealBlockHeight) / 2.0);
        } else {
          topOffset = 12.0;
        }

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
            math.max(0.0, canvasWidth - metrics.innerFrameRect.right) + innerContentPaddingRight;

        final deskTopSeal = topOffset + cardHeight + sealGap;
        final canRenderDeskSeal = !hasAttachments &&
            !keyboardVisible &&
            (currentSheetIndex == totalSheets - 1) &&
            (deskTopSeal + sealSize <= canvasHeight);

        return Container(
          color: deskColor,
          child: ClipRect(
            child: Stack(
              children: [
                // Desk Mat watermark indicator
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

                // PageView of Tactile Stationery Cards
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
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.only(top: topOffset),
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minHeight: 0,
                          maxHeight: double.infinity,
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
                                    headerHeight: sheet is OpeningSheet
                                        ? letterheadConfig.headerHeight
                                        : 0.0,
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
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Sheet Mount Strip and Staging Handscroll resting beneath the card
                if (hasAttachments && canvasHeight - (topOffset + cardHeight + 10.0) > 12.0)
                  Positioned(
                    top: topOffset + cardHeight + 10.0,
                    left: 16.0,
                    right: 16.0,
                    bottom: 12.0,
                    child: AnimatedSlide(
                      offset: keyboardVisible ? const Offset(0.0, 1.5) : Offset.zero,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: keyboardVisible ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: IgnorePointer(
                          ignoring: keyboardVisible,
                          child: EditorDeskMediaArea(
                            mountedItems: mountedItems,
                            stagedItems: stagedItems,
                            mediaSandboxService: mediaSandboxService,
                            activeSheetNumber: currentSheetIndex + 1,
                            isPaperDark: themeConfig.isPaperDark,
                            onMountMedia: onMountMedia,
                            onEraseMedia: onEraseMedia,
                            onUnmountMedia: onUnmountMedia,
                            mountRefusals: mountRefusals,
                            onCaptionChanged: (mediaId, newCaption) {
                              coordinator.media.updateCaption(mediaId, newCaption);
                              onMediaCaptionChanged?.call(mediaId, newCaption);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                // Cinnabar Signature Seal resting cleanly beneath the card on text-only entries
                if (canRenderDeskSeal)
                  BoundedCinnabarSeal(
                    innerFrameRect: metrics.innerFrameRect,
                    containerSize: Size(canvasWidth, canvasHeight),
                    sealStyle: templateStyle.tokens.sealStyle,
                    deskTop: deskTopSeal,
                    opacity: 0.85,
                  ),

                // Floating border navigation chevrons and bottom page indicator
                StationerySheetBorderChrome(
                  currentSheetIndex: currentSheetIndex,
                  totalSheets: totalSheets,
                  onPreviousSheet: onPreviousSheet,
                  onNextSheet: onNextSheet,
                  substrate: templateStyle.tokens.substrate,
                  isPaperDark: themeConfig.isPaperDark,
                  inkColor: themeConfig.inkColor,
                  bottomInset: 12.0,
                ),
              ],
            ),
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
