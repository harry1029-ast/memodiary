import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../models/album_spread.dart';
import '../services/album_layout_engine.dart';
import '../widgets/album_pdf_preview_sheet.dart';
import '../widgets/album_spread_card.dart';

/// Interactive in-app flipbook viewer for a compiled Travel Memory Album.
///
/// Renders synthesized [AlbumSpread] pages inside a horizontal [PageView]
/// with tactile haptic page turns, a `"第 X / Y 页"` progress pill, single-tap
/// fullscreen chrome toggle, and 1-tap vector PDF photobook export.
class AlbumFlipbookScreen extends StatefulWidget {
  final AlbumCollection collection;
  final List<AlbumPhoto> photos;
  final MediaSandboxService mediaService;
  final Future<Uint8List> Function(Uint8List)? imageTranscoder;
  final Future<String> Function(Uint8List bytes, String fileName)?
      customPdfSaveHandler;
  final Future<void> Function(Uint8List bytes, String fileName)?
      customPdfShareHandler;

  const AlbumFlipbookScreen({
    super.key,
    required this.collection,
    required this.photos,
    required this.mediaService,
    this.imageTranscoder,
    this.customPdfSaveHandler,
    this.customPdfShareHandler,
  });

  @override
  State<AlbumFlipbookScreen> createState() => _AlbumFlipbookScreenState();
}

class _AlbumFlipbookScreenState extends State<AlbumFlipbookScreen> {
  late final PageController _pageController;
  late final List<AlbumSpread> _spreads;
  int _currentIndex = 0;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _spreads = AlbumLayoutEngine.synthesize(
      collection: widget.collection,
      photos: widget.photos,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    HapticFeedback.selectionClick();
  }

  void _goToPreviousPage() {
    if (_currentIndex <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToNextPage() {
    if (_currentIndex >= _spreads.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _openPdfExportSheet() {
    AlbumPdfPreviewSheet.show(
      context,
      collection: widget.collection,
      spreads: _spreads,
      mediaService: widget.mediaService,
      imageTranscoder: widget.imageTranscoder,
      customSaveHandler: widget.customPdfSaveHandler,
      customShareHandler: widget.customPdfShareHandler,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final totalPages = _spreads.length;
    final currentPageNumber = _currentIndex + 1;

    return Scaffold(
      backgroundColor: tokens.xuanGround,
      appBar: _isFullscreen
          ? null
          : AppBar(
              key: const Key('flipbook_app_bar'),
              title: Text(
                widget.collection.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: tokens.jiaomo,
                ),
              ),
              actions: [
                IconButton(
                  key: const Key('flipbook_export_pdf_button'),
                  icon: Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 20,
                    color: tokens.cinnabar,
                  ),
                  tooltip: '导出画册 PDF',
                  onPressed: _openPdfExportSheet,
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                key: const Key('flipbook_fullscreen_toggle'),
                behavior: HitTestBehavior.opaque,
                onTap: _toggleFullscreen,
                child: PageView.builder(
                  key: const Key('flipbook_page_view'),
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: totalPages,
                  onPageChanged: _handlePageChanged,
                  itemBuilder: (context, index) {
                    final spread = _spreads[index];
                    return AlbumSpreadCard(
                      spread: spread,
                      totalPages: totalPages,
                      mediaService: widget.mediaService,
                    );
                  },
                ),
              ),
            ),
            if (!_isFullscreen)
              _buildBottomControlBar(tokens, currentPageNumber, totalPages),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControlBar(
    InkDiaryTokens tokens,
    int currentPageNumber,
    int totalPages,
  ) {
    final canGoPrev = currentPageNumber > 1;
    final canGoNext = currentPageNumber < totalPages;

    return Container(
      key: const Key('flipbook_bottom_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.xuanPureLeaf,
        border: Border(
          top: BorderSide(color: tokens.deckleBorder, width: 0.8),
        ),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              key: const Key('flipbook_prev_page_button'),
              icon: Icon(
                Icons.chevron_left,
                size: 24,
                color: canGoPrev ? tokens.nongmo : tokens.qingmo,
              ),
              tooltip: '上一页',
              onPressed: canGoPrev ? _goToPreviousPage : null,
            ),
            Container(
              key: const Key('flipbook_page_indicator'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.agedFiber,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: tokens.deckleBorder.withValues(alpha: 0.85),
                  width: 0.8,
                ),
              ),
              child: Text(
                '第 $currentPageNumber / $totalPages 页',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.nongmo,
                ),
              ),
            ),
            IconButton(
              key: const Key('flipbook_next_page_button'),
              icon: Icon(
                Icons.chevron_right,
                size: 24,
                color: canGoNext ? tokens.nongmo : tokens.qingmo,
              ),
              tooltip: '下一页',
              onPressed: canGoNext ? _goToNextPage : null,
            ),
          ],
        ),
      ),
    );
  }
}
