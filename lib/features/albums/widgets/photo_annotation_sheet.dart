import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/cinnabar_seal_badge.dart';
import '../data/album_repository.dart';
import 'sandboxed_album_image.dart';

/// Interactive modal sheet for viewing and editing per-photo travel notations (写影札).
///
/// Displays the high-resolution image preview, multiline story/caption field,
/// location pin tag (e.g. `"西湖断桥"`), capture date picker override, and actions
/// to save, set as collection cover, or delete the photo.
class PhotoAnnotationSheet extends StatefulWidget {
  final AlbumPhoto photo;
  final AlbumCollection collection;
  final AlbumRepository repository;
  final MediaSandboxService mediaService;

  const PhotoAnnotationSheet({
    super.key,
    required this.photo,
    required this.collection,
    required this.repository,
    required this.mediaService,
  });

  static Future<void> show(
    BuildContext context, {
    required AlbumPhoto photo,
    required AlbumCollection collection,
    required AlbumRepository repository,
    required MediaSandboxService mediaService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => PhotoAnnotationSheet(
        photo: photo,
        collection: collection,
        repository: repository,
        mediaService: mediaService,
      ),
    );
  }

  @override
  State<PhotoAnnotationSheet> createState() => _PhotoAnnotationSheetState();
}

class _PhotoAnnotationSheetState extends State<PhotoAnnotationSheet> {
  late final TextEditingController _captionController;
  late final TextEditingController _locationController;
  DateTime? _shotAt;
  late bool _isCurrentCover;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _captionController =
        TextEditingController(text: widget.photo.caption ?? '');
    _locationController =
        TextEditingController(text: widget.photo.locationTag ?? '');
    _shotAt = widget.photo.shotAt;
    _isCurrentCover =
        widget.collection.coverImagePath == widget.photo.relativeImagePath;
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickShotDate() async {
    final now = DateTime.now();
    final initial = _shotAt ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: '选择照片拍摄日期',
    );
    if (picked != null && mounted) {
      setState(() {
        _shotAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          initial.hour,
          initial.minute,
        );
      });
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final captionText = _captionController.text.trim();
      final locationText = _locationController.text.trim();

      await widget.repository.updatePhotoAnnotationAndSyncRoute(
        photoId: widget.photo.id,
        caption: Value(captionText.isEmpty ? null : captionText),
        locationTag: Value(locationText.isEmpty ? null : locationText),
        shotAt: Value(_shotAt),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleSetCover() async {
    await widget.repository.setCollectionCover(
      widget.collection.id,
      widget.photo.id,
    );
    if (mounted) {
      setState(() => _isCurrentCover = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已设为影集封面')),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这张照片？'),
        content: const Text('删除后，该照片及其写影札记将从本机永久移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('annotation_delete_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.repository.deletePhoto(widget.photo.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateFmt = DateFormat('yyyy.MM.dd HH:mm');
    final shotDateLabel =
        _shotAt != null ? dateFmt.format(_shotAt!) : '未记录拍摄时间（点击设置）';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: bottomInset + 20,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header bar: Title + Cover Seal + Delete & Close
                Row(
                  children: [
                    Text(
                      '写影札',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: tokens.jiaomo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_isCurrentCover)
                      const CinnabarSealBadge.compact(
                        text: '封面',
                        size: 28,
                      ),
                    const Spacer(),
                    IconButton(
                      key: const Key('annotation_delete'),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: tokens.cinnabar,
                      ),
                      tooltip: '删除照片',
                      onPressed: _handleDelete,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: tokens.danmo,
                      ),
                      tooltip: '关闭',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. High-Resolution Image Preview with pinch-zoom
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    child: SandboxedAlbumImage(
                      relativePath: widget.photo.relativeImagePath,
                      mediaService: widget.mediaService,
                      cacheWidth: 1200,
                      borderRadius: 10,
                      height: 240,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Location Tag Field ("西湖断桥")
                TextField(
                  key: const Key('annotation_location_field'),
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: '足迹地标',
                    hintText: '如：西湖断桥、京都 · 伏见稻荷',
                    prefixIcon: Icon(
                      Icons.place_outlined,
                      size: 20,
                      color: tokens.cinnabar,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Multiline Story / Caption Field
                TextField(
                  key: const Key('annotation_caption_field'),
                  controller: _captionController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: '光影札记',
                    hintText: '记下此刻的微风、声响与心绪…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),

                // 5. Capture Date Override Tile
                InkWell(
                  key: const Key('annotation_date_tile'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: _pickShotDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tokens.deckleBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 20,
                          color: tokens.danmo,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            shotDateLabel,
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontNotoSerif,
                              fontSize: 14,
                              color:
                                  _shotAt != null ? tokens.jiaomo : tokens.qingmo,
                            ),
                          ),
                        ),
                        if (_shotAt != null)
                          Semantics(
                            label: '清除拍摄时间',
                            button: true,
                            child: InkWell(
                              onTap: () => setState(() => _shotAt = null),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: tokens.danmo,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Action Buttons: Set as Cover & Save Annotation
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('annotation_set_cover'),
                          onPressed: _isCurrentCover ? null : _handleSetCover,
                          icon: Icon(
                            _isCurrentCover
                                ? Icons.check_circle_outline
                                : Icons.photo_library_outlined,
                            size: 18,
                          ),
                          label: Text(_isCurrentCover ? '当前封面' : '设为封面'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          key: const Key('annotation_save'),
                          onPressed: _isSaving ? null : _handleSave,
                          child: const Text('保存札记'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

