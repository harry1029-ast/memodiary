import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../../templates/widgets/template_canvas_container.dart';
import '../controllers/editor_autosave_manager.dart';
import '../controllers/editor_chrome_controller.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../domain/stationery_sheet_geometry.dart';
import '../models/desk_media_handlers.dart';
import '../models/stationery_sheet_configs.dart';
import '../services/editor_pagination_coordinator.dart';
import 'desk_workstation/desk_space_budget.dart';
import 'desk_workstation/desk_palette.dart';
import 'desk_workstation/scholar_desk_painter.dart';
import 'desk_header_band_lead.dart';
import 'editor_desk_media_area.dart';
import 'editor_text_sheet_view.dart';
import 'keyboard_desk_lift.dart';
import 'paper_heart_metrics.dart';
import 'desk_media_control.dart';
import 'desk_off_sheet_tap.dart';
import 'page_corner.dart';
import 'sheet_drop_target.dart';
import 'stationery_ephemera_sheet.dart';

/// Tactile Split Desk procedural paper canvas presenting discrete Stationery Sheets
/// resting on the Scholar's Desk.
///
/// A header band above the active sheet holds the page indicator at its left and
/// the tops of the sheet's Tucked Prints at its right, and curled Page Corners at
/// the sheet's foot turn the pages. Beneath the sheet rest, on the last sheet, the
/// diarist's Cinnabar Signature Seal and the Desk Workstation holding the Staging
/// Handscroll, sharing the desk by a [DeskSpaceBudget]. The sheet's geometry is resolved against the
/// resting desk height, so the software keyboard never resizes or moves it; the
/// [KeyboardDeskLift] only lifts the desk to show the whole sheet, or the caret
/// when the sheet cannot fit. Tapping the bare desk off the sheet ends writing.
class EditorPaperCanvas extends StatelessWidget {
  static final _walnutDeskPainter = ScholarDeskPainter(palette: DeskPalette.walnut);
  static final _ebonyDeskPainter = ScholarDeskPainter(palette: DeskPalette.ebony);

  /// The sheet's hairline border, which insets the paper inside the card.
  static const double _kSheetBorderWidth = 0.8;

  final StationerySheetThemeConfig themeConfig;
  final StationeryLetterheadConfig letterheadConfig;
  final MediaSandboxService mediaSandboxService;
  final VoidCallback onSaveDraft;

  /// Supplies the keyboard inset (the [Scaffold] strips it from its body's
  /// [MediaQuery] and shrinks the body by it) and the workstation's state.
  final EditorChromeController chrome;

  final EditorPaginationCoordinator coordinator;
  final PageController pageController;
  final int currentSheetIndex;
  final int totalSheets;
  final VoidCallback? onPreviousSheet;
  final VoidCallback? onNextSheet;
  final ValueChanged<int>? onPageChanged;
  final void Function(int sheetIndex)? onDeleteEphemera;
  final DeskMediaHandlers deskMedia;

  /// The autosave status the header band mirrors while the app bar is away.
  final ValueListenable<AutosaveStatus>? saveStatus;

  /// Ends writing when the diarist taps the bare desk off the sheet.
  final VoidCallback? onTapDeskOffSheet;

  const EditorPaperCanvas({
    super.key,
    required this.themeConfig,
    required this.letterheadConfig,
    required this.mediaSandboxService,
    required this.onSaveDraft,
    required this.chrome,
    required this.coordinator,
    required this.pageController,
    this.currentSheetIndex = 0,
    this.totalSheets = 1,
    this.onPreviousSheet,
    this.onNextSheet,
    this.onPageChanged,
    this.onDeleteEphemera,
    this.deskMedia = const DeskMediaHandlers(),
    this.saveStatus,
    this.onTapDeskOffSheet,
  });

  @override
  Widget build(BuildContext context) {
    final templateStyle = themeConfig.templateStyle;
    final typography = themeConfig.typography;
    final isDark = themeConfig.isPaperDark;

    return LayoutBuilder(
      builder: (layoutContext, layoutConstraints) {
        final canvasWidth = layoutConstraints.maxWidth;
        // The visible desk changes while the keyboard is open (and the app bar
        // and dock step aside); the sheet is laid out against the resting
        // height so its ruling and text never shift.
        final visibleHeight = layoutConstraints.maxHeight;
        final bool keyboardVisible = chrome.isKeyboardVisible;
        final canvasHeight = chrome.resolveRestingDeskHeight(visibleHeight);

        final geometry = StationerySheetGeometry.resolve(
          canvasWidth: canvasWidth,
          restingDeskHeight: canvasHeight,
          templateStyle: templateStyle,
          typography: typography,
        );
        final metrics = geometry.metrics;
        final activeRowHeight = geometry.lineStridePx;
        final cardHeight = geometry.cardHeight;

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

        final budget = chrome.resolveDeskBudget(
          restingDeskHeight: canvasHeight,
          sheetHeight: cardHeight,
          sealBlockHeight: sealBlockHeight,
          isHandscrollEmpty: stagedItems.isEmpty,
          isLastSheet: currentSheetIndex == totalSheets - 1,
        );
        final topOffset = budget.sheetTop;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          coordinator.syncLayoutMetrics(
            contentWidth: geometry.usableTextWidth,
            lineStridePx: geometry.lineStridePx,
            visibleRows: geometry.rowCapacity.visibleRows,
          );
        });

        final deskTopSeal = topOffset + cardHeight + sealGap;

        return CustomPaint(
          key: const Key('editor_scholar_desk'),
          painter: DeskPalette.of(context) == DeskPalette.ebony ? _ebonyDeskPainter : _walnutDeskPainter,
          child: ClipRect(
            // The desk keeps its resting height while the keyboard covers it,
            // so the lifted sheet is never clipped by its own page view.
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: canvasHeight,
              maxHeight: canvasHeight,
              child: KeyboardDeskLift(
                isKeyboardVisible: keyboardVisible,
                visibleHeight: visibleHeight,
                sheetTop: topOffset,
                sheetBottom: topOffset + cardHeight,
                rowHeight: activeRowHeight,
                activeSheet:
                    activeSheet is TextStationerySheet ? activeSheet : null,
                child: DeskOffSheetTap(
                  sheetRect: Rect.fromLTWH(0.0, topOffset, canvasWidth, cardHeight),
                  onTapOffSheet: onTapDeskOffSheet,
                  child: Stack(
                    children: [
                      // Page indicator (and, while the app bar is away, the save
                      // dot) at the left of the header band; its right side is
                      // left free for the Tucked Prints.
                      Positioned(
                        top: budget.headerTop,
                        left: 16,
                        height: DeskSpaceBudget.kHeaderHeight,
                        child: DeskHeaderBandLead(
                          currentSheetIndex: currentSheetIndex,
                          totalSheets: totalSheets,
                          saveStatus: keyboardVisible ? saveStatus : null,
                          bandTop: budget.headerTop,
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
                                width: _kSheetBorderWidth,
                              ),
                              boxShadow: [
                                // A sheet of paper resting on the desk.
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
                                        ? geometry.openingHeaderHeight
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
                                      geometry: geometry,
                                    ),
                                  ),
                                  // Page Corner folds, drawn on the paper so they
                                  // move with the sheet under a swipe.
                                  PageCornerFolds(
                                    hasPrevious: sheetIndex > 0,
                                    hasNext: sheetIndex < coordinator.totalSheets - 1,
                                    paperColor: templateStyle.backgroundColor,
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
  
                      // Tucked Prints in the header band and the Desk Workstation at the bottom
                      Positioned.fill(
                        child: EditorDeskMediaArea(
                          budget: budget,
                          mountedItems: mountedItems,
                          stagedItems: stagedItems,
                          mediaSandboxService: mediaSandboxService,
                          activeSheetNumber: currentSheetIndex + 1,
                          isPaperDark: themeConfig.isPaperDark,
                          chrome: chrome,
                          handlers: deskMedia,
                        ),
                      ),
  
                      // Cinnabar Signature Seal resting beneath the last sheet
                      if (budget.showSeal)
                        BoundedCinnabarSeal(
                          innerFrameRect: metrics.innerFrameRect,
                          containerSize: Size(canvasWidth, canvasHeight),
                          sealStyle: templateStyle.tokens.sealStyle,
                          deskTop: deskTopSeal,
                          opacity: 0.85,
                        ),
  
                      // Page Corner touch targets over the active sheet's folds
                      Positioned.fill(
                        child: PageCornerTargets(
                          currentSheetIndex: currentSheetIndex,
                          totalSheets: totalSheets,
                          top: topOffset +
                              _kSheetBorderWidth +
                              metrics.innerFrameRect.bottom,
                          onPreviousSheet: onPreviousSheet,
                          onNextSheet: onNextSheet,
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
    );
  }

  Widget _buildSheetBody({
    required StationerySheetDescriptor sheet,
    required int sheetIndex,
    required StationerySheetGeometry geometry,
  }) {
    if (sheet is TextStationerySheet) {
      return EditorTextSheetView(
        sheet: sheet,
        sheetIndex: sheetIndex,
        geometry: geometry,
        themeConfig: themeConfig,
        letterheadConfig: letterheadConfig,
        mediaSandboxService: mediaSandboxService,
        onSaveDraft: onSaveDraft,
      );
    } else if (sheet is EphemeraSheet) {
      return StationeryEphemeraSheet(
        sheet: sheet,
        innerFrameRect: geometry.paperHeart,
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
