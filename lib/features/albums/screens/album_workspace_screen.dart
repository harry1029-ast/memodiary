import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/cinnabar_seal_badge.dart';
import '../../../core/theme/widgets/ink_metadata_pill.dart';
import '../data/album_repository.dart';
import '../services/album_ingestion_service.dart';
import '../widgets/album_collection_card.dart';
import '../widgets/create_edit_collection_sheet.dart';
import '../widgets/ingestion_progress_dialog.dart';
import '../widgets/photo_annotation_sheet.dart';
import '../widgets/sandboxed_album_image.dart';
import 'album_book_overview_screen.dart';
import 'album_flipbook_screen.dart';

/// Dedicated workspace screen for an open [AlbumCollection].
///
/// Supports browsing 300px thumbnails in an adaptive grid, toggling into
/// accessible drag-and-drop reorder mode (`ReorderableListView`), batch-importing
/// up to 50 photos with progress feedback, and opening `PhotoAnnotationSheet` (写影札).
class AlbumWorkspaceScreen extends StatefulWidget {
  final String collectionId;
  final AlbumCollection? initialCollection;
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final AlbumRepository? repository;
  final ImagePicker? imagePicker;
  final AlbumIngestionService? ingestionService;
  final Future<List<File>> Function()? customFilesPicker;

  const AlbumWorkspaceScreen({
    super.key,
    required this.collectionId,
    this.initialCollection,
    required this.database,
    required this.mediaService,
    this.repository,
    this.imagePicker,
    this.ingestionService,
    this.customFilesPicker,
  });

  @override
  State<AlbumWorkspaceScreen> createState() => _AlbumWorkspaceScreenState();
}

class _AlbumWorkspaceScreenState extends State<AlbumWorkspaceScreen> {
  late final AlbumRepository _repository;
  late final ImagePicker _imagePicker;
  late final AlbumIngestionService _ingestionService;
  late final Stream<AlbumCollection?> _collectionStream;
  late final Stream<List<AlbumPhoto>> _photosStream;
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        AlbumRepository(
          database: widget.database,
          mediaService: widget.mediaService,
        );
    _imagePicker = widget.imagePicker ?? ImagePicker();
    _ingestionService = widget.ingestionService ??
        AlbumIngestionService(
          repository: _repository,
          mediaService: widget.mediaService,
        );
    _collectionStream = _repository.watchCollectionById(widget.collectionId);
    _photosStream = _repository.watchPhotosForCollection(widget.collectionId);
  }

  Future<void> _handleEditMetadata(AlbumCollection collection) async {
    final formResult = await CreateEditCollectionSheet.show(
      context,
      initialCollection: collection,
    );
    if (formResult == null || !mounted) return;

    await _repository.updateCollection(
      AlbumCollectionsCompanion(
        id: Value(collection.id),
        title: Value(formResult.title),
        description: Value(formResult.description),
        destinationTag: Value(formResult.destinationTag),
        routeSummary: Value(formResult.routeSummary),
        startDate: Value(formResult.startDate),
        endDate: Value(formResult.endDate),
      ),
    );
  }

  Future<void> _handleAddPhotos() async {
    List<File> files;
    if (widget.customFilesPicker != null) {
      files = await widget.customFilesPicker!();
    } else {
      final picked = await _imagePicker.pickMultiImage(
        limit: AlbumIngestionService.maxBatchSize,
      );
      files = picked.map((xfile) => File(xfile.path)).toList();
    }

    if (files.isEmpty || !mounted) return;

    final progressNotifier = ValueNotifier<IngestionProgress>(
      IngestionProgress(
        processed: 0,
        total: files.length > AlbumIngestionService.maxBatchSize
            ? AlbumIngestionService.maxBatchSize
            : files.length,
        failed: 0,
      ),
    );
    var cancelRequested = false;
    var dialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => IngestionProgressDialog(
        progressListenable: progressNotifier,
        onCancel: () {
          cancelRequested = true;
        },
      ),
    ).then((_) {
      dialogOpen = false;
    });

    final result = await _ingestionService.ingest(
      collectionId: widget.collectionId,
      sources: files,
      isCancelled: () => cancelRequested,
      onProgress: (progress) {
        progressNotifier.value = progress;
      },
    );

    if (mounted && dialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    progressNotifier.dispose();

    if (!mounted) return;
    final message = _formatIngestionMessage(result);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatIngestionMessage(IngestionResult result) {
    final buffer = StringBuffer('已导入 ${result.imported} 张照片');
    if (result.failed > 0) {
      buffer.write('，${result.failed} 张失败');
    }
    if (result.wasCancelled) {
      buffer.write('（已停止剩余导入）');
    } else if (result.wasTruncatedToMax) {
      buffer.write('（单次最多导入 ${AlbumIngestionService.maxBatchSize} 张）');
    }
    return buffer.toString();
  }

  Future<void> _handleReorder(
    AlbumCollection collection,
    List<AlbumPhoto> currentPhotos,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex) return;

    final reordered = List<AlbumPhoto>.from(currentPhotos);
    final movedPhoto = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, movedPhoto);

    final preSynthesized =
        await _repository.synthesizeRouteSummary(widget.collectionId);
    final currentRoute = collection.routeSummary?.trim();
    final isAutoRoute = currentRoute == null ||
        currentRoute.isEmpty ||
        currentRoute == preSynthesized;

    await _repository.reorderPhotos(
      widget.collectionId,
      reordered.map((photo) => photo.id).toList(),
    );

    if (isAutoRoute) {
      await _repository.synthesizeRouteSummary(
        widget.collectionId,
        persistToCollection: true,
      );
    }
  }

  void _handleOpenFlipbook(
    AlbumCollection collection,
    List<AlbumPhoto> photos,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AlbumFlipbookScreen(
          collection: collection,
          photos: photos,
          mediaService: widget.mediaService,
          repository: widget.repository,
        ),
      ),
    );
  }

  void _handleOpenStudio(
    AlbumCollection collection,
    List<AlbumPhoto> photos,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AlbumBookOverviewScreen(
          collection: collection,
          photos: photos,
          repository: _repository,
          mediaService: widget.mediaService,
          onImportMorePhotos: _handleAddPhotos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    return StreamBuilder<AlbumCollection?>(
      stream: _collectionStream,
      initialData: widget.initialCollection,
      builder: (context, collectionSnapshot) {
        final collection = collectionSnapshot.data;
        if (collection == null) {
          return Scaffold(
            backgroundColor: tokens.xuanGround,
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return StreamBuilder<List<AlbumPhoto>>(
          stream: _photosStream,
          builder: (context, photosSnapshot) {
            final photos = photosSnapshot.data ?? const <AlbumPhoto>[];

            return Scaffold(
              backgroundColor: tokens.xuanGround,
              appBar: AppBar(
                title: Text(
                  collection.title,
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
                    key: const Key('workspace_studio_icon_button'),
                    icon: Icon(
                      Icons.dashboard_customize_outlined,
                      size: 20,
                      color: tokens.cinnabar,
                    ),
                    tooltip: '进入工作室',
                    onPressed: () => _handleOpenStudio(collection, photos),
                  ),
                  IconButton(
                    key: const Key('workspace_flipbook_icon_button'),
                    icon: Icon(
                      Icons.auto_stories_outlined,
                      size: 20,
                      color: tokens.cinnabar,
                    ),
                    tooltip: '浏览画册',
                    onPressed: () => _handleOpenFlipbook(collection, photos),
                  ),
                  IconButton(
                    key: const Key('workspace_edit_collection_button'),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: tokens.nongmo,
                    ),
                    tooltip: '编辑影集信息',
                    onPressed: () => _handleEditMetadata(collection),
                  ),
                  if (photos.length > 1)
                    TextButton.icon(
                      key: const Key('workspace_reorder_toggle'),
                      onPressed: () {
                        setState(() => _isReordering = !_isReordering);
                      },
                      icon: Icon(
                        _isReordering ? Icons.check : Icons.swap_vert,
                        size: 18,
                        color: _isReordering ? tokens.cinnabar : tokens.nongmo,
                      ),
                      label: Text(
                        _isReordering ? '完成' : '排序',
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                          color:
                              _isReordering ? tokens.cinnabar : tokens.nongmo,
                        ),
                      ),
                    ),
                  IconButton(
                    key: const Key('workspace_add_photos'),
                    icon: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 20,
                      color: tokens.cinnabar,
                    ),
                    tooltip: '添加照片',
                    onPressed: _handleAddPhotos,
                  ),
                ],
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCollectionHeader(tokens, collection, photos),
                  Expanded(
                    child: photos.isEmpty
                        ? _buildEmptyPhotosState(tokens)
                        : _isReordering
                            ? _buildReorderList(tokens, collection, photos)
                            : _buildPhotoGrid(tokens, collection, photos),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCollectionHeader(
    InkDiaryTokens tokens,
    AlbumCollection collection,
    List<AlbumPhoto> photos,
  ) {
    final photoCount = photos.length;
    final destination = collection.destinationTag?.trim();
    final description = collection.description?.trim();
    final route = collection.routeSummary?.trim();
    final dateLabel = AlbumCollectionCard.formatDateRange(
      collection.startDate,
      collection.endDate,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: tokens.xuanPureLeaf,
        border: Border(
          bottom: BorderSide(color: tokens.deckleBorder, width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      InkMetadataPill(
                        icon: Icons.calendar_today_outlined,
                        label: dateLabel,
                        maxWidth: 180,
                      ),
                      InkMetadataPill(
                        icon: Icons.photo_camera_outlined,
                        label: '$photoCount 张影像',
                        isAccent: photoCount > 0,
                        maxWidth: 120,
                      ),
                    ],
                  ),
                ),
              ),
              if (destination != null && destination.isNotEmpty) ...[
                const SizedBox(width: 8),
                CinnabarSealBadge.compact(
                  text: destination,
                  size: 28,
                ),
              ],
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13,
                color: tokens.danmo,
                height: 1.45,
              ),
            ),
          ],
          if (route != null && route.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              key: const Key('workspace_route_banner'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.agedFiber,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tokens.deckleBorder.withValues(alpha: 0.8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: tokens.cinnabar,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      route,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: tokens.nongmo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('workspace_open_studio_button'),
                  onPressed: () => _handleOpenStudio(collection, photos),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.cinnabar,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.dashboard_customize_outlined, size: 17),
                  label: const Text(
                    '浏览画册 / 进入工作室',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('workspace_open_flipbook_button'),
                  onPressed: () => _handleOpenFlipbook(collection, photos),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.cinnabar,
                    side: BorderSide(color: tokens.cinnabar.withValues(alpha: 0.6)),
                    backgroundColor: tokens.cinnabarWash.withValues(alpha: 0.35),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.auto_stories_outlined, size: 17),
                  label: const Text(
                    '生成影卷 / 浏览画册',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPhotosState(InkDiaryTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 42,
              color: tokens.qingmo,
            ),
            const SizedBox(height: 12),
            Text(
              '轻触「添加照片」，收录旅途第一帧光影',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 14,
                color: tokens.danmo,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('workspace_empty_add_button'),
              onPressed: _handleAddPhotos,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('添加照片'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(
    InkDiaryTokens tokens,
    AlbumCollection collection,
    List<AlbumPhoto> photos,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isCover = collection.coverImagePath == photo.relativeImagePath;
        final hasCaption =
            photo.caption != null && photo.caption!.trim().isNotEmpty;
        final location = photo.locationTag?.trim();

        return GestureDetector(
          key: Key('workspace_photo_tile_${photo.id}'),
          onTap: () => PhotoAnnotationSheet.show(
            context,
            photo: photo,
            collection: collection,
            repository: _repository,
            mediaService: widget.mediaService,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SandboxedAlbumImage(
                relativePath: photo.relativeThumbnailPath,
                mediaService: widget.mediaService,
                cacheWidth: 300,
                borderRadius: 8,
              ),
              if (isCover)
                const Positioned(
                  top: 6,
                  left: 6,
                  child: CinnabarSealBadge.compact(
                    text: '封面',
                    size: 24,
                  ),
                ),
              if (hasCaption || (location != null && location.isNotEmpty))
                Positioned(
                  left: 4,
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.jiaomo.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        if (location != null && location.isNotEmpty) ...[
                          const Icon(
                            Icons.place,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                        ],
                        Expanded(
                          child: Text(
                            location != null && location.isNotEmpty
                                ? location
                                : photo.caption!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: InkDiaryTheme.fontNotoSerif,
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReorderList(
    InkDiaryTokens tokens,
    AlbumCollection collection,
    List<AlbumPhoto> photos,
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: photos.length,
      onReorderItem: (oldIndex, newIndex) =>
          _handleReorder(collection, photos, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final photo = photos[index];
        final caption = photo.caption?.trim();
        final location = photo.locationTag?.trim();

        return Container(
          key: Key('reorder_tile_${photo.id}'),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: tokens.xuanPureLeaf,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.deckleBorder),
          ),
          child: Row(
            children: [
              Text(
                '#${index + 1}',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.danmo,
                ),
              ),
              const SizedBox(width: 10),
              SandboxedAlbumImage(
                relativePath: photo.relativeThumbnailPath,
                mediaService: widget.mediaService,
                cacheWidth: 300,
                width: 56,
                height: 56,
                borderRadius: 6,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caption != null && caption.isNotEmpty
                          ? caption
                          : '未题写札记',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 14,
                        color: caption != null && caption.isNotEmpty
                            ? tokens.jiaomo
                            : tokens.qingmo,
                      ),
                    ),
                    if (location != null && location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: tokens.cinnabar,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontNotoSerif,
                                fontSize: 12,
                                color: tokens.danmo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.drag_handle,
                    size: 20,
                    color: tokens.danmo,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
