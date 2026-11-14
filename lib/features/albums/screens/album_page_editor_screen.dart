import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/utils/collection_extensions.dart';
import '../constants/album_studio_strings.dart';
import '../data/album_repository.dart';
import '../models/album_studio_models.dart';
import '../services/album_studio_controller.dart';
import '../services/page_layout_catalog.dart';
import '../widgets/interactive_canvas/album_page_canvas.dart';
import '../widgets/photo_annotation_sheet.dart';
import '../widgets/studio_drawers/add_elements_drawer.dart';
import '../widgets/studio_drawers/background_style_drawer.dart';
import '../widgets/studio_drawers/layout_picker_drawer.dart';
import '../widgets/studio_drawers/page_editor_sheets.dart';
import '../widgets/studio_drawers/removed_photos_drawer.dart';

export '../widgets/studio_drawers/page_editor_sheets.dart' show StudioDrawerTab;

/// Interactive single-page scrapbook canvas editor (matching Journi Images 3–9).
///
/// Supports tactile drag-and-drop photo slot swapping, non-destructive pan/zoom
/// cropping, removing/restoring photos via the `'Removed'` holding tray,
/// live collage layout switching, background color/graphic customization,
/// and freeform sticker/text/date/seal overlays with 50-step Undo/Redo.
class AlbumPageEditorScreen extends StatefulWidget {
  final AlbumStudioController controller;
  final AlbumCollection collection;
  final List<AlbumPhoto> photos;
  final AlbumRepository repository;
  final MediaSandboxService mediaService;
  final int initialPageIndex;

  const AlbumPageEditorScreen({
    super.key,
    required this.controller,
    required this.collection,
    required this.photos,
    required this.repository,
    required this.mediaService,
    this.initialPageIndex = 0,
  });

  @override
  State<AlbumPageEditorScreen> createState() => _AlbumPageEditorScreenState();
}

class _AlbumPageEditorScreenState extends State<AlbumPageEditorScreen> {
  StudioDrawerTab? _activeDrawerTab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.selectPage(widget.initialPageIndex);
        final pages = widget.controller.pages;
        final curIdx = pages.safeClampIndex(widget.initialPageIndex);
        if (curIdx != null &&
            pages[curIdx].photoSlots.isEmpty &&
            widget.controller.removedPhotoIds.isNotEmpty) {
          setState(() {
            _activeDrawerTab = StudioDrawerTab.removed;
          });
        }
      }
    });
  }

  AlbumCollection _liveCollection() =>
      widget.controller.collection ?? widget.collection;

  Map<String, AlbumPhoto> _livePhotoById() =>
      (widget.controller.collection != null ||
              widget.controller.photos.isNotEmpty)
          ? widget.controller.photoById
          : {for (final photo in widget.photos) photo.id: photo};

  String _resolveDefaultDateLabel(
    AlbumPageModel page,
    AlbumCollection collection,
  ) {
    if (page.dateHeaderText != null && page.dateHeaderText!.trim().isNotEmpty) {
      return page.dateHeaderText!.trim();
    }
    final date = collection.startDate ?? collection.createdAt;
    return DateFormat('yyyy.MM.dd').format(date);
  }

  void _toggleDrawer(StudioDrawerTab tab) {
    setState(() {
      _activeDrawerTab = (_activeDrawerTab == tab) ? null : tab;
    });
  }

  Future<void> _handleConfirmAndExit() async {
    await widget.controller.saveToRepository();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleEditDateHeader(AlbumPageModel page) async {
    final updated = await showPageDateHeaderSheet(
      context: context,
      initialText: page.dateHeaderText,
    );
    if (updated == null) return;
    widget.controller.updateDateHeaderText(
      pageId: page.id,
      dateHeaderText: updated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final collection = _liveCollection();
        final photoById = _livePhotoById();
        final pages = widget.controller.pages;
        final currentIndex = widget.controller.selectedPageIndex;
        final activePage = widget.controller.selectedPage;

        if (activePage == null || pages.isEmpty) {
          return Scaffold(
            backgroundColor: tokens.xuanGround,
            appBar: AppBar(),
            body: const Center(child: Text('暂无书页')),
          );
        }

        return Scaffold(
          backgroundColor: tokens.xuanGround,
          appBar: AppBar(
            backgroundColor: tokens.xuanPureLeaf,
            elevation: 0,
            titleSpacing: 0,
            leading: IconButton(
              key: const Key('page_editor_confirm_button'),
              icon: Icon(Icons.check, color: tokens.cinnabar, size: 24),
              tooltip: '完成并保存本页',
              onPressed: _handleConfirmAndExit,
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('page_editor_prev_page'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: Icon(
                    Icons.chevron_left,
                    size: 20,
                    color: currentIndex > 0 ? tokens.jiaomo : tokens.qingmo,
                  ),
                  tooltip: '上一页',
                  onPressed: currentIndex > 0
                      ? () => widget.controller.selectPage(currentIndex - 1)
                      : null,
                ),
                Flexible(
                  child: Text(
                    key: const Key('page_editor_page_indicator'),
                    'Page ${currentIndex + 1} / ${pages.length}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tokens.jiaomo,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('page_editor_next_page'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: currentIndex < pages.length - 1
                        ? tokens.jiaomo
                        : tokens.qingmo,
                  ),
                  tooltip: '下一页',
                  onPressed: currentIndex < pages.length - 1
                      ? () => widget.controller.selectPage(currentIndex + 1)
                      : null,
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                key: const Key('page_editor_undo_button'),
                icon: Icon(
                  Icons.undo,
                  size: 20,
                  color: widget.controller.canUndo
                      ? tokens.jiaomo
                      : tokens.qingmo.withValues(alpha: 0.45),
                ),
                tooltip: '撤销 (Undo)',
                onPressed: widget.controller.canUndo
                    ? widget.controller.undo
                    : null,
              ),
              IconButton(
                key: const Key('page_editor_redo_button'),
                icon: Icon(
                  Icons.redo,
                  size: 20,
                  color: widget.controller.canRedo
                      ? tokens.jiaomo
                      : tokens.qingmo.withValues(alpha: 0.45),
                ),
                tooltip: '重做 (Redo)',
                onPressed: widget.controller.canRedo
                    ? widget.controller.redo
                    : null,
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. Interactive Single-Page Canvas Stage
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: tokens.xuanPureLeaf,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: tokens.deckleBorder,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: tokens.jiaomo.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AlbumPageCanvas(
                          key: ValueKey('editor_canvas_${activePage.id}'),
                          page: activePage,
                          photoById: photoById,
                          mediaService: widget.mediaService,
                          isInteractive: true,
                          onSwapSlots: (firstSlot, secondSlot) {
                            widget.controller.swapPhotoSlots(
                              pageId: activePage.id,
                              firstSlotIndex: firstSlot,
                              secondSlotIndex: secondSlot,
                            );
                          },
                          onDropTrayPhoto: (photoId) =>
                              _restorePhotoToPage(activePage, photoId),
                          onUpdatePanZoom: (
                            slotIndex, {
                            panOffsetX,
                            panOffsetY,
                            zoomScale,
                          }) {
                            widget.controller.updatePhotoPanZoom(
                              pageId: activePage.id,
                              slotIndex: slotIndex,
                              panOffsetX: panOffsetX,
                              panOffsetY: panOffsetY,
                              zoomScale: zoomScale,
                            );
                          },
                          onEditPhotoAnnotation: (photo) {
                            PhotoAnnotationSheet.show(
                              context,
                              photo: photo,
                              collection: collection,
                              repository: widget.repository,
                              mediaService: widget.mediaService,
                            );
                          },
                          onRemovePhotoToTray: (slotIndex) {
                            widget.controller.removePhotoToTray(
                              pageId: activePage.id,
                              slotIndex: slotIndex,
                            );
                          },
                          onUpdateOverlay: (overlay) {
                            widget.controller.updateOverlay(
                              pageId: activePage.id,
                              overlay: overlay,
                            );
                          },
                          onDeleteOverlay: (overlayId) {
                            widget.controller.removeOverlay(
                              pageId: activePage.id,
                              overlayId: overlayId,
                            );
                          },
                          onTapDateHeader: () =>
                              _handleEditDateHeader(activePage),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Expandable Studio Bottom Drawer
              if (_activeDrawerTab != null)
                _buildActiveDrawer(activePage, photoById, collection),

              // 3. Bottom Studio Tool Dock
              StudioBottomDock(
                removedCount: widget.controller.removedPhotoIds.length,
                activeTab: _activeDrawerTab,
                onToggleTab: _toggleDrawer,
              ),
            ],
          ),
        );
      },
    );
  }

  void _restorePhotoToPage(AlbumPageModel activePage, String photoId) {
    if (activePage.photoSlots.length >= PageLayoutCatalog.maxPhotosPerPage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AlbumStudioStrings.pageFullNotice(
              PageLayoutCatalog.maxPhotosPerPage,
            ),
            style: const TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
            ),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.controller.restorePhotoFromTray(
      photoId: photoId,
      targetPageId: activePage.id,
    );
  }

  Widget _buildActiveDrawer(
    AlbumPageModel activePage,
    Map<String, AlbumPhoto> photoById,
    AlbumCollection collection,
  ) {
    switch (_activeDrawerTab!) {
      case StudioDrawerTab.removed:
        return RemovedPhotosDrawer(
          removedPhotoIds: widget.controller.removedPhotoIds,
          photoById: photoById,
          mediaService: widget.mediaService,
          onRestorePhoto: (photoId) => _restorePhotoToPage(activePage, photoId),
          onClose: () => setState(() => _activeDrawerTab = null),
        );

      case StudioDrawerTab.add:
        return AddElementsDrawer(
          defaultDateLabel: _resolveDefaultDateLabel(activePage, collection),
          existingOverlayCount: activePage.overlays.length,
          onAddOverlay: (overlay) {
            widget.controller.addOverlay(
              pageId: activePage.id,
              overlay: overlay,
            );
          },
          onClose: () => setState(() => _activeDrawerTab = null),
        );

      case StudioDrawerTab.background:
        return BackgroundStyleDrawer(
          currentConfig: activePage.backgroundConfig,
          recentColors: widget.controller.document.recentBackgroundColors,
          onUpdateBackground: (bgConfig) {
            widget.controller.updatePageBackground(
              pageId: activePage.id,
              backgroundConfig: bgConfig,
            );
          },
          onClose: () => setState(() => _activeDrawerTab = null),
        );

      case StudioDrawerTab.layout:
        return LayoutPickerDrawer(
          page: activePage,
          photoById: photoById,
          mediaService: widget.mediaService,
          onSelectLayout: (templateId) {
            widget.controller.changePageLayout(
              pageId: activePage.id,
              layoutTemplateId: templateId,
            );
          },
          onClose: () => setState(() => _activeDrawerTab = null),
        );
    }
  }
}
