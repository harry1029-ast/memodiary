import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/media_sandbox_service.dart';
import '../../../editor/services/audio_sanctum_service.dart';
import '../../../templates/models/template_style.dart';
import 'folio_3d_stage.dart';
import 'folio_actions.dart';
import 'folio_content_leaf_page.dart';
import 'folio_desk_chrome.dart';
import 'folio_frontispiece_page.dart';
import 'folio_leaf_model.dart';
import 'folio_page_jump_sheet.dart';
import 'folio_pagination_engine.dart';
import 'folio_reading_perspective.dart';
import 'folio_reading_perspective_sheet.dart';

export 'folio_actions.dart';

/// Interactive Thread-Bound Folio screen resting on the scholar's walnut desk
/// with minimalist top and bottom desk chrome.
class ThreadBoundFolioScreen extends StatefulWidget {
  final Entry entry;
  final TemplateStyle? templateStyle;
  final List<MediaAttachment> attachments;
  final MediaSandboxService? mediaService;
  final AudioSanctumService? audioSanctumService;
  final FolioActions actions;
  final bool enableAmbientAnimation;

  const ThreadBoundFolioScreen({
    super.key,
    required this.entry,
    this.templateStyle,
    this.attachments = const [],
    this.mediaService,
    this.audioSanctumService,
    this.actions = const FolioActions(),
    this.enableAmbientAnimation = true,
  });

  @override
  State<ThreadBoundFolioScreen> createState() => _ThreadBoundFolioScreenState();
}

class _ThreadBoundFolioScreenState extends State<ThreadBoundFolioScreen> {
  ReadingPerspective _perspective = ReadingPerspective.faithfulOriginal;
  int _currentPageIndex = 0;
  bool _isChromeVisible = true;
  late List<FolioLeaf> _leaves;
  late FolioSubstrateTheme _substrateTheme;

  @override
  void initState() {
    super.initState();
    _repaginate();
  }

  @override
  void didUpdateWidget(covariant ThreadBoundFolioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry ||
        oldWidget.templateStyle != widget.templateStyle ||
        oldWidget.attachments != widget.attachments) {
      _repaginate();
    }
  }

  void _repaginate() {
    _substrateTheme = _perspective.resolveTheme(templateStyle: widget.templateStyle);
    _leaves = FolioPaginationEngine.paginate(
      entry: widget.entry,
      templateStyle: widget.templateStyle,
      perspective: _perspective,
      attachments: widget.attachments,
    );
    if (_currentPageIndex >= _leaves.length) {
      _currentPageIndex = (_leaves.length - 1).clamp(0, 9999);
    }
  }

  void _onSelectPerspective(ReadingPerspective newPerspective) {
    setState(() {
      _perspective = newPerspective;
      if (_currentPageIndex == 0 && newPerspective != ReadingPerspective.faithfulOriginal) {
        _currentPageIndex = 1;
      }
      _repaginate();
    });
  }

  void _handlePageTurn(int delta) {
    final nextIndex = _currentPageIndex + delta;
    if (nextIndex >= 0 && nextIndex < _leaves.length) {
      setState(() => _currentPageIndex = nextIndex);
    }
  }

  void _toggleChrome() {
    setState(() => _isChromeVisible = !_isChromeVisible);
  }

  void _openPageJumpSheet() {
    FolioPageJumpSheet.show(
      context: context,
      leaves: _leaves,
      currentIndex: _currentPageIndex,
      onPageSelected: (index) {
        setState(() => _currentPageIndex = index);
      },
    );
  }

  void _handleShare() {
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.entry.entryDate);
    final titleStr = (widget.entry.title?.trim().isNotEmpty ?? false)
        ? '${widget.entry.title!.trim()}\n\n'
        : '';
    final shareText = '$titleStr$dateStr\n\n${widget.entry.plainText}';
    widget.actions.shareHandler?.call(shareText, subject: widget.entry.title);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final dateBreadcrumb = DateFormat('yyyy.MM.dd').format(entry.entryDate);
    final displayTitle = (entry.title?.trim().isNotEmpty ?? false) ? entry.title!.trim() : '无题手稿';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0908),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _toggleChrome,
        child: Stack(
          children: [
            // Center Folio Stage
            Positioned.fill(
              child: Folio3DStage(
                leaves: _leaves,
                theme: _substrateTheme,
                currentPageIndex: _currentPageIndex,
                onPageChanged: (newIndex) => setState(() => _currentPageIndex = newIndex),
                enableAmbientAnimation: widget.enableAmbientAnimation,
                leafBuilder: (context, leaf, isTurningLeaf) {
                  if (leaf is FolioFrontispieceCoverLeaf) {
                    return FolioFrontispiecePage(
                      leaf: leaf,
                      theme: _substrateTheme,
                      mediaService: widget.mediaService,
                      onTurnForward: () => _handlePageTurn(1),
                    );
                  }
                  return FolioContentLeafPage(
                    leaf: leaf,
                    theme: _substrateTheme,
                    mediaService: widget.mediaService,
                    isTurningLeaf: isTurningLeaf,
                    onTurnForward: () => _handlePageTurn(1),
                    onTurnBackward: () => _handlePageTurn(-1),
                  );
                },
              ),
            ),

            // Top Desk Chrome Bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              top: _isChromeVisible ? 0 : -90,
              left: 0,
              right: 0,
              child: FolioTopChrome(
                dateBreadcrumb: dateBreadcrumb,
                displayTitle: displayTitle,
                isEntryLocked: entry.isLocked,
                audioSanctumService: widget.audioSanctumService,
                actions: widget.actions,
                onBack: () => Navigator.pop(context),
              ),
            ),

            // Bottom Desk Action Dock
            AnimatedPositioned(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              bottom: _isChromeVisible ? 0 : -100,
              left: 0,
              right: 0,
              child: FolioBottomDock(
                perspective: _perspective,
                onOpenPerspective: () {
                  FolioReadingPerspectiveSheet.show(
                    context: context,
                    currentPerspective: _perspective,
                    onPerspectiveSelected: _onSelectPerspective,
                  );
                },
                currentPageIndex: _currentPageIndex,
                totalPages: _leaves.length,
                onOpenPageJump: _openPageJumpSheet,
                onPrevPage: _currentPageIndex > 0 ? () => _handlePageTurn(-1) : null,
                onNextPage: _currentPageIndex < _leaves.length - 1 ? () => _handlePageTurn(1) : null,
                onShare: _handleShare,
                onEditEntry: widget.actions.onEditEntry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
