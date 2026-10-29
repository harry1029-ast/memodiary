import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../constants/album_studio_strings.dart';
import '../data/album_repository.dart';
import '../models/album_studio_models.dart';
import '../services/album_layout_engine.dart';
import '../services/album_studio_controller.dart';
import '../widgets/album_pdf_preview_sheet.dart';
import '../widgets/book_spread_tile.dart';
import '../widgets/studio_drawers/themes_and_style_sheet.dart';
import 'album_flipbook_screen.dart';
import 'album_page_editor_screen.dart';

/// Book Overview Screen (matching Journi Image 10) rendering a vertical feed of
/// open 2-page spreads with a central spine crease shadow, reactive Undo/Redo
/// controls, and a bottom floating action dock (`+ Add`, `Arrange`, `Options`, `→ Continue`).
class AlbumBookOverviewScreen extends StatefulWidget {
  final AlbumCollection collection;
  final List<AlbumPhoto> photos;
  final AlbumRepository repository;
  final MediaSandboxService mediaService;
  final AlbumStudioController? controller;
  final VoidCallback? onImportMorePhotos;

  const AlbumBookOverviewScreen({
    super.key,
    required this.collection,
    required this.photos,
    required this.repository,
    required this.mediaService,
    this.controller,
    this.onImportMorePhotos,
  });

  @override
  State<AlbumBookOverviewScreen> createState() =>
      _AlbumBookOverviewScreenState();
}

class _AlbumBookOverviewScreenState extends State<AlbumBookOverviewScreen> {
  AlbumStudioController? _controller;
  bool _ownsController = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller;
      _isLoading = false;
    } else {
      _ownsController = true;
      _initController();
    }
  }

  Future<void> _initController() async {
    final doc = await widget.repository.loadOrSynthesizeStudioDocument(
      widget.collection.id,
    );
    if (!mounted) return;
    setState(() {
      _controller = AlbumStudioController(
        collectionId: widget.collection.id,
        initialDocument: doc,
        repository: widget.repository,
      );
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller?.dispose();
    }
    super.dispose();
  }

  Map<String, AlbumPhoto> _buildPhotoLookup() {
    return {
      for (final photo in widget.photos) photo.id: photo,
    };
  }

  Future<void> _handleClose() async {
    await _controller?.saveToRepository();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleOpenPageEditor(int pageIndex) async {
    final ctrl = _controller;
    if (ctrl == null) return;
    ctrl.selectPage(pageIndex);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AlbumPageEditorScreen(
          controller: ctrl,
          collection: widget.collection,
          photos: widget.photos,
          repository: widget.repository,
          mediaService: widget.mediaService,
          initialPageIndex: pageIndex,
        ),
      ),
    );
  }

  void _handleOpenAddSheet() {
    final ctrl = _controller;
    if (ctrl == null) return;
    final tokens = context.inkTokens;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.xuanPureLeaf,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  key: const Key('overview_add_blank_page'),
                  leading: Icon(
                    Icons.note_add_outlined,
                    color: tokens.cinnabar,
                  ),
                  title: Text(
                    '新增空白书页 · Add Blank Page',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontWeight: FontWeight.w600,
                      color: tokens.jiaomo,
                    ),
                  ),
                  subtitle: Text(
                    '在画册末尾添入一页宣纸留白，自由排入照片与贴纸',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 12,
                      color: tokens.danmo,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ctrl.addBlankPage();
                  },
                ),
                if (widget.onImportMorePhotos != null)
                  ListTile(
                    key: const Key('overview_import_photos'),
                    leading: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: tokens.nongmo,
                    ),
                    title: Text(
                      '导入更多照片 · Import Photos',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontWeight: FontWeight.w600,
                        color: tokens.jiaomo,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      widget.onImportMorePhotos!();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleOpenArrangeSheet() {
    final ctrl = _controller;
    if (ctrl == null) return;
    final tokens = context.inkTokens;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.xuanPureLeaf,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: ctrl,
          builder: (context, _) {
            final pages = ctrl.pages;
            return SizedBox(
              key: const Key('book_overview_arrange_sheet'),
              height: MediaQuery.of(context).size.height * 0.65,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.swap_vert, color: tokens.cinnabar, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '调整书页顺序 · Arrange Pages',
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontNotoSerif,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: tokens.jiaomo,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: tokens.danmo),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ReorderableListView.builder(
                        itemCount: pages.length,
                        onReorderItem: (oldIndex, newIndex) {
                          ctrl.reorderPages(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final page = pages[index];
                          return ListTile(
                            key: ValueKey('arrange_page_${page.id}'),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            leading: CircleAvatar(
                              radius: 15,
                              backgroundColor: tokens.agedFiber,
                              child: Text(
                                '${page.pageNumber}',
                                style: TextStyle(
                                  fontFamily: InkDiaryTheme.fontNotoSerif,
                                  fontSize: 12,
                                  color: tokens.jiaomo,
                                ),
                              ),
                            ),
                            title: Text(
                              '第 ${page.pageNumber} 页 (${page.photoSlots.length} 张影像)',
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontNotoSerif,
                                fontSize: 14,
                                color: tokens.jiaomo,
                              ),
                            ),
                            subtitle: Text(
                              '版式: ${page.layoutTemplateId}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: tokens.danmo,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (pages.length > 1)
                                  IconButton(
                                    key: Key('arrange_delete_page_$index'),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 19,
                                      color: tokens.cinnabar,
                                    ),
                                    tooltip: '删除此页 (照片将移入收集箱)',
                                    onPressed: () => ctrl.removePage(page.id),
                                  ),
                                Icon(
                                  Icons.drag_handle,
                                  color: tokens.qingmo,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleOpenOptionsSheet() {
    final ctrl = _controller;
    if (ctrl == null) return;

    ThemesAndStyleSheet.show(
      context,
      activeThemeId: ctrl.document.activeThemeId,
      onSelectTheme: (themeId) {
        ctrl.applyGlobalTheme(themeId);
        ctrl.saveToRepository();
      },
    );
  }

  Future<void> _handleContinueToExport() async {
    final ctrl = _controller;
    if (ctrl == null) return;
    await ctrl.saveToRepository();
    if (!mounted) return;

    final spreads = AlbumLayoutEngine.synthesize(
      collection: widget.collection,
      photos: widget.photos,
    );

    await AlbumPdfPreviewSheet.show(
      context,
      collection: widget.collection,
      spreads: spreads,
      studioDocument: ctrl.document,
      photos: widget.photos,
      mediaService: widget.mediaService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    if (_isLoading || _controller == null) {
      return Scaffold(
        backgroundColor: tokens.xuanGround,
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final ctrl = _controller!;
    final photoById = _buildPhotoLookup();

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final pages = ctrl.pages;
        final spreads = _buildSpreadPairs(pages);
        final removedCount = ctrl.removedPhotoIds.length;

        return Scaffold(
          backgroundColor: tokens.xuanGround,
          appBar: AppBar(
            backgroundColor: tokens.xuanPureLeaf,
            elevation: 0,
            leading: IconButton(
              key: const Key('book_overview_close_button'),
              icon: Icon(Icons.close, color: tokens.jiaomo),
              tooltip: '保存并关闭',
              onPressed: _handleClose,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.collection.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: tokens.jiaomo,
                  ),
                ),
                Text(
                  AlbumStudioStrings.overviewHeaderCount(
                    pages.length,
                    removedCount,
                  ),
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 11,
                    color: tokens.danmo,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                key: const Key('book_overview_undo_button'),
                icon: Icon(
                  Icons.undo,
                  size: 20,
                  color: ctrl.canUndo
                      ? tokens.jiaomo
                      : tokens.qingmo.withValues(alpha: 0.45),
                ),
                tooltip: '撤销 (Undo)',
                onPressed: ctrl.canUndo ? ctrl.undo : null,
              ),
              IconButton(
                key: const Key('book_overview_redo_button'),
                icon: Icon(
                  Icons.redo,
                  size: 20,
                  color: ctrl.canRedo
                      ? tokens.jiaomo
                      : tokens.qingmo.withValues(alpha: 0.45),
                ),
                tooltip: '重做 (Redo)',
                onPressed: ctrl.canRedo ? ctrl.redo : null,
              ),
              IconButton(
                key: const Key('book_overview_flipbook_button'),
                icon: Icon(
                  Icons.auto_stories_outlined,
                  size: 20,
                  color: tokens.nongmo,
                ),
                tooltip: '沉浸翻阅模式',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => AlbumFlipbookScreen(
                        collection: widget.collection,
                        photos: widget.photos,
                        mediaService: widget.mediaService,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              ListView.separated(
                key: const Key('book_overview_spread_list'),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                itemCount: spreads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, spreadIdx) {
                  final pair = spreads[spreadIdx];
                  return BookSpreadTile(
                    spreadIndex: spreadIdx,
                    collection: widget.collection,
                    spreadData: pair,
                    photoById: photoById,
                    mediaService: widget.mediaService,
                    onTapPage: _handleOpenPageEditor,
                    onAddBlankPage: () => ctrl.addBlankPage(),
                  );
                },
              ),
              // Floating Bottom Action Dock
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: SafeArea(
                  top: false,
                  child: _buildFloatingActionDock(tokens),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_SpreadPair> _buildSpreadPairs(List<AlbumPageModel> pages) {
    if (pages.isEmpty) {
      return const [
        _SpreadPair(isCoverLeft: true),
      ];
    }

    final pairs = <_SpreadPair>[
      _SpreadPair(
        isCoverLeft: true,
        rightPage: pages[0],
        rightPageIndex: 0,
      ),
    ];

    var cursor = 1;
    while (cursor < pages.length) {
      final left = pages[cursor];
      final leftIdx = cursor;
      final right = (cursor + 1 < pages.length) ? pages[cursor + 1] : null;
      final rightIdx = (cursor + 1 < pages.length) ? cursor + 1 : null;

      pairs.add(
        _SpreadPair(
          leftPage: left,
          leftPageIndex: leftIdx,
          rightPage: right,
          rightPageIndex: rightIdx,
        ),
      );
      cursor += 2;
    }

    // If pages.length is odd (1, 3, 5...), all currently created spreads have
    // their right leaves populated (Spread 0: Cover + Page 1; Spread 1: Page 2 + Page 3...).
    // Append a trailing spread with an empty left leaf so the user can add Page (N + 1) on the left!
    if (pages.length % 2 != 0) {
      pairs.add(
        _SpreadPair(
          leftPage: null,
          rightPage: null,
          expectedNextPageNumber: pages.length + 1,
        ),
      );
    }

    return pairs;
  }

  Widget _buildFloatingActionDock(InkDiaryTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.xuanPureLeaf.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.deckleBorder),
        boxShadow: [
          BoxShadow(
            color: tokens.jiaomo.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: _OverviewDockButton(
              buttonKey: const Key('book_overview_add_button'),
              icon: Icons.add,
              label: 'Add',
              tokens: tokens,
              onTap: _handleOpenAddSheet,
            ),
          ),
          Flexible(
            child: _OverviewDockButton(
              buttonKey: const Key('book_overview_arrange_button'),
              icon: Icons.grid_view_outlined,
              label: 'Arrange',
              tokens: tokens,
              onTap: _handleOpenArrangeSheet,
            ),
          ),
          Flexible(
            child: _OverviewDockButton(
              buttonKey: const Key('book_overview_options_button'),
              icon: Icons.style_outlined,
              label: 'Options',
              tokens: tokens,
              onTap: _handleOpenOptionsSheet,
            ),
          ),
          FilledButton.icon(
            key: const Key('book_overview_continue_button'),
            style: FilledButton.styleFrom(
              backgroundColor: tokens.cinnabar,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _handleContinueToExport,
            icon: const Icon(Icons.arrow_forward, size: 15),
            label: const Text(
              'Continue',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _SpreadPair = BookSpreadData;

class _OverviewDockButton extends StatelessWidget {
  final Key buttonKey;
  final IconData icon;
  final String label;
  final InkDiaryTokens tokens;
  final VoidCallback onTap;

  const _OverviewDockButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: tokens.jiaomo),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.jiaomo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
