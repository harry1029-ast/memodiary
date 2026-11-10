import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import '../../templates/services/stationery_layout_calculator.dart';
import '../../templates/widgets/template_canvas_container.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/desk_media_handlers.dart';
import '../models/stationery_sheet_configs.dart';
import '../services/editor_pagination_coordinator.dart';
import 'desk_workstation/desk_space_budget.dart';
import 'desk_workstation/desk_workstation_controller.dart';
import 'desk_workstation/desk_palette.dart';
import 'desk_workstation/walnut_desk_painter.dart';
import 'editor_desk_media_area.dart';
import 'editor_text_sheet_view.dart';
import 'keyboard_caret_lift.dart';
import 'paper_heart_metrics.dart';
import 'desk_media_control.dart';
import 'sheet_drop_target.dart';
import 'stationery_ephemera_sheet.dart';
import 'stationery_sheet_border_chrome.dart';

/// Tactile Split Desk procedural paper canvas presenting discrete Stationery Sheets
/// resting on a walnut scholar's desk.
///
/// A header band above the active sheet holds the page indicator. Beneath the sheet
/// rest its Sheet Mount Strip (or, on a text-only last sheet, the diarist's Cinnabar
/// Signature Seal) and the Desk Workstation holding the Staging Handscroll, sharing
/// the desk by a [DeskSpaceBudget]. The sheet's geometry is resolved against the
/// resting desk height, so the software keyboard never resizes or moves it; the
/// [KeyboardCaretLift] only lifts the desk far enough to keep the caret in view.
class EditorPaperCanvas extends StatelessWidget {
  static final _walnutDesk = WalnutDeskPainter(palette: DeskPalette.walnut);
  static final _ebonyDesk = WalnutDeskPainter(palette: DeskPalette.ebony);

  final StationerySheetThemeConfig themeConfig;
  final StationeryLetterheadConfig letterheadConfig;
  final MediaSandboxService mediaSandboxService;
  final VoidCallback onSaveDraft;
  final DeskWorkstationController workstationController;

  /// Height of the software keyboard covering the screen (0 when closed). Read
  /// above the [Scaffold], which strips the keyboard inset from its body's
  /// [MediaQuery] and shrinks the body by it.
  final double keyboardInset;

  final EditorPaginationCoordinator coordinator;
  final PageController pageController;
  final int currentSheetIndex;
  final int totalSheets;
  final VoidCallback? onPreviousSheet;
  final VoidCallback? onNextSheet;
  final ValueChanged<int>? onPageChanged;
  final void Function(int sheetIndex)? onDeleteEphemera;
  final DeskMediaHandlers deskMedia;
  final void Function(String mediaId, String newCaption)? onMediaCaptionChanged;
  final void Function(int sheetIndex)? onSpillBack;

  const EditorPaperCanvas({
    super.key,
    required this.themeConfig,
    required this.letterheadConfig,
    required this.mediaSandboxService,
    required this.onSaveDraft,
    required this.workstationController,
    this.keyboardInset = 0.0,
    required this.coordinator,
    required this.pageController,
    this.currentSheetIndex = 0,
    this.totalSheets = 1,
    this.onPreviousSheet,
    this.onNextSheet,
    this.onPageChanged,
    this.onDeleteEphemera,
    this.deskMedia = const DeskMediaHandlers(),
    this.onMediaCaptionChanged,
    this.onSpillBack,
  });

  @override
  Widget build(BuildContext context) {
    final templateStyle = themeConfig.templateStyle;
    final typography = themeConfig.typography;
    final isDark = themeConfig.isPaperDark;

    return LayoutBuilder(
      builder: (layoutContext, layoutConstraints) {
        final canvasWidth = layoutConstraints.maxWidth;
        // The visible desk shrinks while the keyboard is open; the sheet is laid
        // out against the resting height so its ruling and text never shift.
        final visibleHeight = layoutConstraints.maxHeight;
        final bool keyboardVisible = keyboardInset > 0;
        final canvasHeight = visibleHeight + keyboardInset;

        // Bounded card canvas dimensions for integer-locked 14-row calculation
        final cardCanvasSize =
            Size(canvasWidth, math.max(380.0, math.min(canvasHeight, 420.0)));
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
        final activeSheet = (currentSheetIndex >= 0 &&
                currentSheetIndex < coordinator.sheets.length)
            ? coordinator.sheets[currentSheetIndex]
            : (coordinator.sheets.isNotEmpty ? coordinator.sheets.first : null);
        final mountedItems = activeSheet is TextStationerySheet
            ? List<SheetMediaItem>.unmodifiable(activeSheet.mediaAttachments)
            : const <SheetMediaItem>[];
        final stagedItems = coordinator.stagedItems;

        const sealSize = PaperHeartMetrics.kDefaultSealSize;
        const sealGap = 16.0;
        const sealBlockHeight = sealSize + sealGap;

        DeskSpaceBudget resolveBudget({required bool isWorkstationCollapsed}) =>
            DeskSpaceBudget.resolve(
              canvasHeight: canvasHeight,
              sheetHeight: cardHeight,
              sealBlockHeight: sealBlockHeight,
              hasMountedItems: mountedItems.isNotEmpty,
              isHandscrollEmpty: stagedItems.isEmpty,
              isWorkstationCollapsed: isWorkstationCollapsed,
              isKeyboardVisible: keyboardVisible,
              isLastSheet: currentSheetIndex == totalSheets - 1,
            );
        final isWorkstationCollapsed = workstationController.resolveInitial(
          workstationFits:
              resolveBudget(isWorkstationCollapsed: false).workstationFits,
        );
        final budget =
            resolveBudget(isWorkstationCollapsed: isWorkstationCollapsed);
        final topOffset = budget.sheetTop;

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
          metrics.innerFrameRect.width -
              innerContentPaddingLeft -
              innerContentPaddingRight,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          coordinator.syncLayoutMetrics(
            contentWidth: usableTextWidth,
            lineStridePx: activeRowHeight,
          );
        });

        final horizontalLeft =
            metrics.innerFrameRect.left + innerContentPaddingLeft;
        final horizontalRight =
            math.max(0.0, canvasWidth - metrics.innerFrameRect.right) +
                innerContentPaddingRight;

        final deskTopSeal = topOffset + cardHeight + sealGap;
        final maxLift = math.max(
          0.0,
          topOffset +
              cardHeight +
              KeyboardCaretLift.kCaretMargin -
              visibleHeight,
        );

        return CustomPaint(
          key: const Key('editor_walnut_desk'),
          painter: DeskPalette.of(context) == DeskPalette.ebony ? _ebonyDesk : _walnutDesk,
          child: ClipRect(
            // The desk keeps its resting height while the keyboard covers it,
            // so the lifted sheet is never clipped by its own page view.
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: canvasHeight,
              maxHeight: canvasHeight,
              child: KeyboardCaretLift(
                isKeyboardVisible: keyboardVisible,
                visibleHeight: visibleHeight,
                maxLift: maxLift,
                activeSheet:
                    activeSheet is TextStationerySheet ? activeSheet : null,
                child: Stack(
                  children: [
                    // Desk engraving in the header band, opposite the page indicator
                    Positioned(
                      top: budget.headerTop,
                      left: 16,
                      height: DeskSpaceBudget.kHeaderHeight,
                      child: const IgnorePointer(
                        child: Center(
                          child: Text(
                            '文房书案',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 2.0,
                              color: Color(0x73FDE68A),
                            ),
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
                        if (sheetIndex < 0 ||
                            sheetIndex >= coordinator.sheets.length) {
                          return const SizedBox.shrink();
                        }
                        final sheet = coordinator.sheets[sheetIndex];

                        final sheetCard = Container(
                          width: canvasWidth,
                          height: cardHeight,
                          decoration: BoxDecoration(
                            color: templateStyle.backgroundColor,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0x33FFFFFF)
                                  : const Color(0x1F000000),
                              width: 0.8,
                            ),
                            boxShadow: [
                              // A sheet of paper resting on the walnut desk.
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 18.0,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
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
                                    textTheme: themeConfig
                                        .paperBaseTheme.textTheme
                                        .apply(
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
                        );

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
                              // Every sheet keeps the same wrapper so a page turn
                              // never remounts its editor (which would drop focus
                              // and bounce the keyboard).
                              child: SheetDropTarget(
                                sheetIndex: sheetIndex,
                                palette: DeskMediaPalette(isPaperDark: isDark),
                                onMount: deskMedia.onMount,
                                isEnabled: sheetIndex == currentSheetIndex,
                                child: sheetCard,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Sheet Mount Strip beneath the card and the Desk Workstation at the bottom
                    Positioned.fill(
                      child: EditorDeskMediaArea(
                        budget: budget,
                        mountedItems: mountedItems,
                        stagedItems: stagedItems,
                        mediaSandboxService: mediaSandboxService,
                        activeSheetNumber: currentSheetIndex + 1,
                        isPaperDark: themeConfig.isPaperDark,
                        handlers: deskMedia,
                        onCaptionChanged: (mediaId, newCaption) {
                          coordinator.media.updateCaption(mediaId, newCaption);
                          onMediaCaptionChanged?.call(mediaId, newCaption);
                        },
                      ),
                    ),

                    // Cinnabar Signature Seal resting cleanly beneath the card on text-only entries
                    if (budget.showSeal)
                      BoundedCinnabarSeal(
                        innerFrameRect: metrics.innerFrameRect,
                        containerSize: Size(canvasWidth, canvasHeight),
                        sealStyle: templateStyle.tokens.sealStyle,
                        deskTop: deskTopSeal,
                        opacity: 0.85,
                      ),

                    // Border navigation chevrons on the sheet, page indicator in the header band
                    StationerySheetBorderChrome(
                      currentSheetIndex: currentSheetIndex,
                      totalSheets: totalSheets,
                      onPreviousSheet: onPreviousSheet,
                      onNextSheet: onNextSheet,
                      substrate: templateStyle.tokens.substrate,
                      isPaperDark: themeConfig.isPaperDark,
                      inkColor: themeConfig.inkColor,
                      sheetTop: topOffset,
                      sheetHeight: cardHeight,
                      indicatorTop: budget.headerTop,
                      indicatorBandHeight: DeskSpaceBudget.kHeaderHeight,
                    ),
                  ],
                ),
              ),
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
        onDelete: onDeleteEphemera != null
            ? () => onDeleteEphemera!(sheet.sheetIndex)
            : null,
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
