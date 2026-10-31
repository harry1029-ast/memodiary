import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/services/ocr/ocr_models.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../albums/screens/album_workspace_screen.dart';
import '../../timeline/screens/entry_detail_screen.dart';
import '../widgets/ocr_highlight_overlay.dart';

/// Full-screen interactive photo viewer that highlights recognized OCR text lines
/// with pulsing cinnabar bounding boxes and provides direct navigation back
/// to the parent diary entry or travel album collection.
class OcrPhotoViewerScreen extends StatefulWidget {
  final PhotoTextMatch match;
  final String query;
  final MediaSandboxService mediaSandboxService;
  final AppDatabase? database;
  final bool enableAnimation;
  final Size? imageSize;

  const OcrPhotoViewerScreen({
    super.key,
    required this.match,
    required this.query,
    required this.mediaSandboxService,
    this.database,
    this.enableAnimation = false,
    this.imageSize,
  });

  @override
  State<OcrPhotoViewerScreen> createState() => _OcrPhotoViewerScreenState();
}

class _OcrPhotoViewerScreenState extends State<OcrPhotoViewerScreen> {
  File? _resolvedFile;
  bool _isLoadingFile = true;
  Size? _imageSize;
  bool _isVisible = true;
  late final List<OcrLineBlock> _lines;

  @override
  void initState() {
    super.initState();
    _lines = OcrResult.parseBlocksJson(widget.match.ocrBlocksJson);
    _imageSize = widget.imageSize;
    _resolveImageFile();
  }

  Future<void> _resolveImageFile() async {
    try {
      final file = await widget.mediaSandboxService.getFileFromRelativePath(
        widget.match.relativePath,
      );
      if (!mounted) return;
      setState(() {
        _resolvedFile = file;
        _isLoadingFile = false;
      });

      if (file.existsSync() && _imageSize == null) {
        _decodeImageSize(file);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingFile = false;
      });
    }
  }

  void _decodeImageSize(File file) {
    try {
      final imageProvider = FileImage(file);
      final stream = imageProvider.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (imageInfo, synchronousCall) {
          final width = imageInfo.image.width.toDouble();
          final height = imageInfo.image.height.toDouble();
          if (mounted && width > 0 && height > 0) {
            setState(() {
              _imageSize = Size(width, height);
            });
          }
        },
        onError: (exception, stackTrace) {
          // Graceful fallback to default Size(1000, 1000)
        },
      );
      stream.addListener(listener);
    } catch (error) {
      debugPrint('Failed to decode image dimensions: $error');
    }
  }

  void _navigateToParent() {
    if (widget.match.sourceType == PhotoTextMatch.sourceEntryMedia) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (routeContext) => EntryDetailScreen(
            entryId: widget.match.parentId,
            database: widget.database,
            mediaService: widget.mediaSandboxService,
          ),
        ),
      );
    } else if (widget.match.sourceType == PhotoTextMatch.sourceAlbumPhoto) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (routeContext) => AlbumWorkspaceScreen(
            collectionId: widget.match.parentId,
            database: widget.database,
            mediaService: widget.mediaSandboxService,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Scaffold(
      backgroundColor: tokens.xuanGround,
      appBar: AppBar(
        backgroundColor: tokens.xuanGround,
        elevation: 0,
        leading: BackButton(
          color: tokens.nongmo,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.match.parentTitle?.trim().isNotEmpty == true
              ? widget.match.parentTitle!
              : '识图详情',
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontKaiti,
            color: tokens.jiaomo,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(tokens),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Semantics(
        button: true,
        label: _isVisible ? '隐藏高亮' : '显示高亮',
        child: FloatingActionButton.extended(
          key: const Key('ocr_highlight_toggle'),
          onPressed: () {
            setState(() {
              _isVisible = !_isVisible;
            });
          },
          icon: Icon(
            _isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: Colors.white,
          ),
          label: Text(
            _isVisible ? '隐藏高亮' : '显示高亮',
            style: const TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: tokens.jiaomo.withValues(alpha: 0.88),
          elevation: 3,
        ),
      ),
      bottomNavigationBar: _buildBottomBar(tokens),
    );
  }

  Widget _buildBody(InkDiaryTokens tokens) {
    if (_isLoadingFile) {
      return Center(
        child: CircularProgressIndicator(color: tokens.cinnabar),
      );
    }

    final file = _resolvedFile;
    if (file == null || !file.existsSync()) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 48, color: tokens.danmo),
            const SizedBox(height: 12),
            Text(
              '未能载入照片',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                color: tokens.danmo,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    final effectiveImageSize = _imageSize ?? const Size(1000, 1000);

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Hero(
                tag: 'ocr_photo_${widget.match.id}',
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: tokens.danmo,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: OcrHighlightOverlay(
                  lines: _lines,
                  query: widget.query,
                  originalImageSize: effectiveImageSize,
                  isVisible: _isVisible,
                  enableAnimation: widget.enableAnimation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(InkDiaryTokens tokens) {
    final isEntryMedia = widget.match.sourceType == PhotoTextMatch.sourceEntryMedia;
    final buttonLabel = isEntryMedia ? '查看原日记' : '查看相册';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.xuanGround,
        border: Border(
          top: BorderSide(color: tokens.deckleBorder, width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.match.parentTitle != null && widget.match.parentTitle!.isNotEmpty)
                    Text(
                      widget.match.parentTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontKaiti,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: tokens.jiaomo,
                      ),
                    ),
                  if (widget.match.parentDate != null)
                    Text(
                      '${widget.match.parentDate!.year}年${widget.match.parentDate!.month}月${widget.match.parentDate!.day}日',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 12,
                        color: tokens.danmo,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              key: const Key('ocr_viewer_view_parent_button'),
              onPressed: _navigateToParent,
              icon: Icon(
                isEntryMedia ? Icons.menu_book_outlined : Icons.photo_library_outlined,
                size: 18,
              ),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                  fontFamily: InkDiaryTheme.fontKaiti,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: tokens.cinnabar,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
