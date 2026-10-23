import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../data/album_repository.dart';
import '../services/album_ingestion_service.dart';
import '../widgets/album_collection_card.dart';
import '../widgets/create_edit_collection_sheet.dart';
import '../widgets/sandboxed_album_image.dart';
import 'album_workspace_screen.dart';

/// Main dashboard screen for the **旅行影集 (Travel Memory Album)** module.
///
/// Reactively watches all collections (`watchAllCollections()`) and photo counts
/// (`watchPhotoCounts()`), rendering literati Xuan-paper cards in a responsive
/// 1- or 2-column layout with create, edit, cover selection, and atomic delete flows.
class AlbumCollectionsScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final AlbumRepository? repository;
  final ImagePicker? imagePicker;
  final AlbumIngestionService? ingestionService;

  const AlbumCollectionsScreen({
    super.key,
    required this.database,
    required this.mediaService,
    this.repository,
    this.imagePicker,
    this.ingestionService,
  });

  @override
  State<AlbumCollectionsScreen> createState() => _AlbumCollectionsScreenState();
}

class _AlbumCollectionsScreenState extends State<AlbumCollectionsScreen> {
  late final AlbumRepository _repository;
  late final Stream<List<AlbumCollection>> _collectionsStream;
  late final Stream<Map<String, int>> _photoCountsStream;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        AlbumRepository(
          database: widget.database,
          mediaService: widget.mediaService,
        );
    _collectionsStream = _repository.watchAllCollections();
    _photoCountsStream = _repository.watchPhotoCounts();
  }

  Future<void> _handleCreateCollection() async {
    final formResult = await CreateEditCollectionSheet.show(context);
    if (formResult == null || !mounted) return;

    await _repository.createCollection(
      title: formResult.title,
      description: formResult.description,
      destinationTag: formResult.destinationTag,
      routeSummary: formResult.routeSummary,
      startDate: formResult.startDate,
      endDate: formResult.endDate,
    );
  }

  Future<void> _handleEditCollection(AlbumCollection collection) async {
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

  Future<void> _handleSelectCover(AlbumCollection collection) async {
    final photos = await _repository.getPhotosForCollection(collection.id);
    if (!mounted) return;

    if (photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先进入影集添加照片，再选择封面')),
      );
      return;
    }

    final selectedPhotoId = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        final tokens = sheetContext.inkTokens;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择「${collection.title}」封面照片',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.jiaomo,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 110,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    final isCurrent =
                        collection.coverImagePath == photo.relativeImagePath;
                    return GestureDetector(
                      key: Key('cover_picker_tile_${photo.id}'),
                      onTap: () => Navigator.of(sheetContext).pop(photo.id),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SandboxedAlbumImage(
                            relativePath: photo.relativeThumbnailPath,
                            mediaService: widget.mediaService,
                            cacheWidth: 300,
                            borderRadius: 8,
                          ),
                          if (isCurrent)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: tokens.cinnabar,
                                  width: 2.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedPhotoId != null && mounted) {
      await _repository.setCollectionCover(collection.id, selectedPhotoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已更新影集封面')),
        );
      }
    }
  }

  Future<void> _handleDeleteCollection(AlbumCollection collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('删除「${collection.title}」？'),
        content: const Text(
          '删除后，该影集内的所有照片文件与写影札记将从设备存储中永久清除，不可恢复。',
        ),
        actions: [
          TextButton(
            key: const Key('album_delete_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('album_delete_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _repository.deleteCollection(collection.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除影集「${collection.title}」')),
        );
      }
    }
  }

  void _openWorkspace(AlbumCollection collection) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AlbumWorkspaceScreen(
          collectionId: collection.id,
          initialCollection: collection,
          database: widget.database,
          mediaService: widget.mediaService,
          repository: _repository,
          imagePicker: widget.imagePicker,
          ingestionService: widget.ingestionService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    return Scaffold(
      backgroundColor: tokens.xuanGround,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '旅行影集',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: tokens.jiaomo,
              ),
            ),
            Text(
              '山河沿路，笔底留痕',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 11,
                color: tokens.danmo,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('albums_add_fab'),
        onPressed: _handleCreateCollection,
        icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
        label: const Text('新建影集'),
      ),
      body: StreamBuilder<List<AlbumCollection>>(
        stream: _collectionsStream,
        builder: (context, collectionsSnapshot) {
          if (collectionsSnapshot.connectionState == ConnectionState.waiting &&
              !collectionsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final collections = collectionsSnapshot.data ?? const [];
          if (collections.isEmpty) {
            return _buildEmptyState(tokens);
          }

          return StreamBuilder<Map<String, int>>(
            stream: _photoCountsStream,
            builder: (context, countsSnapshot) {
              final counts = countsSnapshot.data ?? const <String, int>{};

              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 600) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: GridView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 96),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 340,
                          ),
                          itemCount: collections.length,
                          itemBuilder: (context, index) {
                            final collection = collections[index];
                            return _buildCollectionCard(
                              collection,
                              counts[collection.id] ?? 0,
                            );
                          },
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 96),
                    itemCount: collections.length,
                    itemBuilder: (context, index) {
                      final collection = collections[index];
                      return _buildCollectionCard(
                        collection,
                        counts[collection.id] ?? 0,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCollectionCard(AlbumCollection collection, int photoCount) {
    return AlbumCollectionCard(
      collection: collection,
      photoCount: photoCount,
      mediaService: widget.mediaService,
      onTap: () => _openWorkspace(collection),
      onActionSelected: (action) {
        switch (action) {
          case AlbumCardAction.edit:
            _handleEditCollection(collection);
          case AlbumCardAction.setCover:
            _handleSelectCover(collection);
          case AlbumCardAction.delete:
            _handleDeleteCollection(collection);
        }
      },
    );
  }

  Widget _buildEmptyState(InkDiaryTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: tokens.agedFiber,
                shape: BoxShape.circle,
                border: Border.all(color: tokens.deckleBorder),
              ),
              child: Icon(
                Icons.brush_outlined,
                size: 32,
                color: tokens.danmo,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '尚无旅行影集',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: tokens.jiaomo,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '山河沿路，笔底留痕。将旅途照片整理成册，题写地标与心绪。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13,
                color: tokens.danmo,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('albums_empty_create_button'),
              onPressed: _handleCreateCollection,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新建影集'),
            ),
          ],
        ),
      ),
    );
  }
}

