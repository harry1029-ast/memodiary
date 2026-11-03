import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../editor/services/audio_sanctum_service.dart';
import '../../../editor/widgets/soundscape_modal.dart';
import '../../../templates/models/template_style.dart';
import 'folio_3d_stage.dart';
import 'folio_content_leaf_page.dart';
import 'folio_frontispiece_page.dart';
import 'folio_leaf_model.dart';
import 'folio_pagination_engine.dart';
import 'folio_reading_perspective.dart';
import 'folio_reading_perspective_sheet.dart';

/// Interactive Thread-Bound Folio screen resting on the scholar's walnut desk
/// with minimalist top and bottom desk chrome.
class ThreadBoundFolioScreen extends StatefulWidget {
  final Entry entry;
  final TemplateStyle? templateStyle;
  final List<MediaAttachment> attachments;
  final AudioSanctumService? audioSanctumService;
  final Future<void> Function(String text, {String? subject})? shareHandler;
  final VoidCallback? onEditEntry;
  final VoidCallback? onSoftDelete;
  final VoidCallback? onToggleLock;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportText;
  final bool enableAmbientAnimation;

  const ThreadBoundFolioScreen({
    super.key,
    required this.entry,
    this.templateStyle,
    this.attachments = const [],
    this.audioSanctumService,
    this.shareHandler,
    this.onEditEntry,
    this.onSoftDelete,
    this.onToggleLock,
    this.onExportPdf,
    this.onExportText,
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
      // If switching to a ruling-specific perspective from the cover, advance to page 1
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
                      onTurnForward: () => _handlePageTurn(1),
                    );
                  }
                  return FolioContentLeafPage(
                    leaf: leaf,
                    theme: _substrateTheme,
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
              child: _buildTopChrome(dateBreadcrumb, displayTitle),
            ),

            // Bottom Desk Action Dock
            AnimatedPositioned(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              bottom: _isChromeVisible ? 0 : -100,
              left: 0,
              right: 0,
              child: _buildBottomDock(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopChrome(String dateBreadcrumb, String displayTitle) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 6,
        bottom: 8,
        left: 12,
        right: 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC0A0908),
            Color(0x660A0908),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Back button with subtle date breadcrumb
          IconButton(
            key: const Key('folio_back_btn'),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFFE6E1D8)),
            tooltip: '返回 · $dateBreadcrumb',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),

          // Centered title
          Expanded(
            child: Text(
              displayTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFBF8F1),
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Ambient Soundscape button
          if (widget.audioSanctumService != null)
            ListenableBuilder(
              listenable: widget.audioSanctumService!,
              builder: (context, _) {
                final isPlaying = widget.audioSanctumService!.isPlaying;
                return IconButton(
                  key: const Key('folio_soundscape_btn'),
                  icon: Icon(
                    isPlaying ? Icons.headphones_rounded : Icons.headphones_outlined,
                    size: 20,
                    color: isPlaying ? const Color(0xFFB83B2E) : const Color(0xFFB3ADA3),
                  ),
                  tooltip: '砚边琴韵',
                  onPressed: () {
                    SoundscapeModal.show(
                      context: context,
                      sanctumService: widget.audioSanctumService!,
                    );
                  },
                );
              },
            ),

          // Consolidated More Menu
          PopupMenuButton<String>(
            key: const Key('folio_more_menu_btn'),
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFFE6E1D8)),
            color: const Color(0xFF1E1D1B),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0x33D4AF37), width: 0.8),
            ),
            onSelected: (action) {
              switch (action) {
                case 'lock':
                  widget.onToggleLock?.call();
                  break;
                case 'pdf':
                  widget.onExportPdf?.call();
                  break;
                case 'text':
                  widget.onExportText?.call();
                  break;
                case 'delete':
                  widget.onSoftDelete?.call();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                key: const Key('folio_menu_lock_entry'),
                value: 'lock',
                child: Row(
                  children: [
                    Icon(
                      widget.entry.isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                      size: 18,
                      color: const Color(0xFFE6E1D8),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.entry.isLocked ? '解除私密封缄' : '私密封存',
                      style: const TextStyle(color: Color(0xFFE6E1D8)),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                key: Key('folio_menu_export_pdf'),
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 18, color: Color(0xFFE6E1D8)),
                    SizedBox(width: 10),
                    Text('导出宣纸 PDF', style: TextStyle(color: Color(0xFFE6E1D8))),
                  ],
                ),
              ),
              const PopupMenuItem(
                key: Key('folio_menu_export_text'),
                value: 'text',
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, size: 18, color: Color(0xFFE6E1D8)),
                    SizedBox(width: 10),
                    Text('纯文归档', style: TextStyle(color: Color(0xFFE6E1D8))),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                key: const Key('folio_menu_delete_entry'),
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                    const SizedBox(width: 10),
                    Text('移入岁暮拾遗', style: TextStyle(color: Colors.red.shade400)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDock() {
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.paddingOf(context).bottom + 10,
        left: 18,
        right: 18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xE60A0908),
            Color(0x990A0908),
            Colors.transparent,
          ],
        ),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Perspective switcher
            TextButton.icon(
              key: const Key('folio_reading_perspective_btn'),
              onPressed: () {
                FolioReadingPerspectiveSheet.show(
                  context: context,
                  currentPerspective: _perspective,
                  onPerspectiveSelected: _onSelectPerspective,
                );
              },
              icon: const Icon(Icons.auto_stories_outlined, size: 16, color: Color(0xFFD4AF37)),
              label: Text(
                _perspective.label,
                style: const TextStyle(fontSize: 13, color: Color(0xFFE6E1D8)),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0x1AD4AF37),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            // Page Indicator Pill
            Container(
              key: const Key('folio_page_indicator'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '第 ${_currentPageIndex + 1} / ${_leaves.length} 页',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFB3ADA3),
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // Action Buttons: Share & Edit
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('folio_share_btn'),
                  icon: const Icon(Icons.share_outlined, size: 18, color: Color(0xFFE6E1D8)),
                  tooltip: '分享',
                  onPressed: () {
                    final dateStr = DateFormat('yyyy-MM-dd').format(widget.entry.entryDate);
                    final titleStr = (widget.entry.title?.trim().isNotEmpty ?? false)
                        ? '${widget.entry.title!.trim()}\n\n'
                        : '';
                    final shareText = '$titleStr$dateStr\n\n${widget.entry.plainText}';
                    widget.shareHandler?.call(shareText, subject: widget.entry.title);
                  },
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  key: const Key('folio_edit_entry_btn'),
                  onPressed: widget.onEditEntry,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB83B2E),
                    foregroundColor: const Color(0xFFFAF7F0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('落墨修改', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
