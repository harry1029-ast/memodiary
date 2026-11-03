import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import '../../timeline/widgets/folio/folio_silk_corner_mounts_painter.dart';
import '../domain/stationery_sheet_descriptor.dart';
import 'sandboxed_video_player.dart';

/// Resolved color palette for paper-toned matte mounts, silk corners,
/// captions, and colophon chrome across light and dark substrates.
class _EphemeraSubstrateTheme {
  final Color matteColor;
  final Color silkColor;
  final Color borderColor;
  final Color colophonTextColor;
  final Color captionTextColor;
  final Color captionHintColor;
  final Color deleteButtonColor;
  final Color fallbackIconColor;

  const _EphemeraSubstrateTheme({
    required this.matteColor,
    required this.silkColor,
    required this.borderColor,
    required this.colophonTextColor,
    required this.captionTextColor,
    required this.captionHintColor,
    required this.deleteButtonColor,
    required this.fallbackIconColor,
  });

  factory _EphemeraSubstrateTheme.resolve({
    required bool isDark,
    Color? customInkColor,
  }) {
    if (isDark) {
      return _EphemeraSubstrateTheme(
        matteColor: const Color(0xFF141619),
        silkColor: const Color(0xD0C8A055),
        borderColor: const Color(0xFF8C7355).withValues(alpha: 0.35),
        colophonTextColor: customInkColor?.withValues(alpha: 0.7) ?? const Color(0xFF9E998F),
        captionTextColor: customInkColor ?? const Color(0xFFC8C3BC),
        captionHintColor: const Color(0xFF8A857D),
        deleteButtonColor: const Color(0xFFE57373),
        fallbackIconColor: const Color(0xFF8A857D),
      );
    } else {
      return _EphemeraSubstrateTheme(
        matteColor: const Color(0xFFFDFBF7),
        silkColor: const Color(0xC0DFC898),
        borderColor: const Color(0xFF8C7355).withValues(alpha: 0.35),
        colophonTextColor: customInkColor?.withValues(alpha: 0.7) ?? const Color(0xFF78716C),
        captionTextColor: customInkColor ?? const Color(0xFF5C554E),
        captionHintColor: const Color(0xFF9E978F),
        deleteButtonColor: const Color(0xFFB83B2E),
        fallbackIconColor: const Color(0xFF9E978F),
      );
    }
  }
}

/// Dedicated full-sheet ephemera mount presenting an embedded photo or short video
/// inside the Paper Heart with paper-toned matte framing, classical silk corner mounts,
/// inline video playback, editable caption, and accessible deletion.
class StationeryEphemeraSheet extends StatefulWidget {
  final EphemeraSheet sheet;
  final Rect? innerFrameRect;
  final String? title;
  final MediaSandboxService? mediaSandboxService;
  final bool isActiveSheet;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onCaptionChanged;
  final bool isPaperDark;
  final PaperSubstrate? substrate;
  final Color? inkColor;
  final String? fontFamily;

  const StationeryEphemeraSheet({
    super.key,
    required this.sheet,
    this.innerFrameRect,
    this.title,
    this.mediaSandboxService,
    this.isActiveSheet = true,
    this.onDelete,
    this.onCaptionChanged,
    this.isPaperDark = false,
    this.substrate,
    this.inkColor,
    this.fontFamily,
  });

  @override
  State<StationeryEphemeraSheet> createState() => _StationeryEphemeraSheetState();
}

class _StationeryEphemeraSheetState extends State<StationeryEphemeraSheet> {
  late Future<({File file, File? thumbFile})> _mediaFilesFuture;
  late MediaSandboxService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.mediaSandboxService ?? MediaSandboxService();
    _mediaFilesFuture = _resolveMediaFiles(widget.sheet.sandboxedRelativePath);
  }

  @override
  void didUpdateWidget(covariant StationeryEphemeraSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaSandboxService != widget.mediaSandboxService) {
      _service = widget.mediaSandboxService ?? MediaSandboxService();
    }
    if (oldWidget.sheet.sandboxedRelativePath != widget.sheet.sandboxedRelativePath) {
      _mediaFilesFuture = _resolveMediaFiles(widget.sheet.sandboxedRelativePath);
    }
  }

  ({File file, File? thumbFile})? _resolveImmediate(String rawPath) {
    if (rawPath.isNotEmpty && !MediaSandboxService.isStrictlyRelative(rawPath)) {
      return (file: File(rawPath), thumbFile: null);
    }
    return null;
  }

  Future<({File file, File? thumbFile})> _resolveMediaFiles(String rawPath) async {
    final mediaFile = MediaSandboxService.isStrictlyRelative(rawPath)
        ? await _service.getFileFromRelativePath(rawPath)
        : File(rawPath);

    File? thumbFile;
    if (rawPath.endsWith('.mp4')) {
      final thumbPath = rawPath.replaceAll(RegExp(r'\.mp4$'), '_thumb.webp');
      final candidate = MediaSandboxService.isStrictlyRelative(thumbPath)
          ? await _service.getFileFromRelativePath(thumbPath)
          : File(thumbPath);
      if (candidate.existsSync()) {
        thumbFile = candidate;
      }
    }

    return (file: mediaFile, thumbFile: thumbFile);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isPaperDark || widget.substrate == PaperSubstrate.obsidian;
    final theme = _EphemeraSubstrateTheme.resolve(
      isDark: isDark,
      customInkColor: widget.inkColor,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final innerRect = widget.innerFrameRect;
        final left = innerRect?.left ?? 20.0;
        final top = innerRect?.top ?? 18.0;
        final right = innerRect != null && constraints.hasBoundedWidth
            ? math.max(0.0, constraints.maxWidth - innerRect.right)
            : 20.0;
        final bottom = innerRect != null && constraints.hasBoundedHeight
            ? math.max(0.0, constraints.maxHeight - innerRect.bottom)
            : 14.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(left, top, right, bottom),
          child: Container(
            key: const Key('stationery_ephemera_paper_heart'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildColophonHeader(theme),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildMediaMount(theme),
                ),
                const SizedBox(height: 8),
                _buildCaptionField(theme),
                const SizedBox(height: 4),
                _buildRemoveButton(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColophonHeader(_EphemeraSubstrateTheme theme) {
    final rawTitle = widget.title?.trim();
    final displayTitle = (rawTitle != null && rawTitle.isNotEmpty) ? rawTitle : '无题';
    final pageNumber = widget.sheet.sheetIndex + 1;
    final colophonText = '《$displayTitle》 · 第 $pageNumber 页';
    final mediaTypeLabel = widget.sheet.mediaType == 'video' ? '动态拓片 · 影印' : '珍藏拓影 · 插页';

    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              colophonText,
              key: const Key('editor_ephemera_colophon_header'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.0,
                letterSpacing: 1.2,
                fontFamily: widget.fontFamily,
                color: theme.colophonTextColor,
              ),
            ),
          ),
          Text(
            mediaTypeLabel,
            style: TextStyle(
              fontSize: 10.0,
              letterSpacing: 0.8,
              fontFamily: widget.fontFamily,
              color: theme.colophonTextColor.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaMount(_EphemeraSubstrateTheme theme) {
    return Stack(
      children: [
        Container(
          key: const Key('editor_ephemera_matte_container'),
          decoration: BoxDecoration(
            color: theme.matteColor,
            border: Border.all(color: theme.borderColor),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            child: FutureBuilder<({File file, File? thumbFile})>(
              initialData: _resolveImmediate(widget.sheet.sandboxedRelativePath),
              future: _mediaFilesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      key: Key('editor_ephemera_loading_indicator'),
                      strokeWidth: 2,
                    ),
                  );
                }

                final data = snapshot.data;
                if (data == null || !data.file.existsSync()) {
                  return _buildFallbackIcon(theme);
                }

                if (widget.sheet.mediaType == 'video') {
                  if (widget.isActiveSheet) {
                    return SandboxedVideoPlayer(
                      key: Key('editor_ephemera_video_player_${widget.sheet.sheetIndex}'),
                      videoFile: data.file,
                      thumbnailFile: data.thumbFile,
                      autoPlay: false,
                    );
                  } else {
                    return _buildSuspendedVideoPreview(data.file, data.thumbFile, theme);
                  }
                }

                return Image.file(
                  data.file,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(theme),
                );
              },
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              key: const Key('editor_ephemera_silk_corners'),
              painter: FolioSilkCornerMountsPainter(
                 silkColor: theme.silkColor,
                 size: 14.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackIcon(_EphemeraSubstrateTheme theme) {
    return Center(
      child: Icon(
        widget.sheet.mediaType == 'video'
            ? Icons.videocam_outlined
            : Icons.photo_outlined,
        key: const Key('editor_ephemera_fallback_icon'),
        size: 40,
        color: theme.fallbackIconColor,
      ),
    );
  }

  Widget _buildSuspendedVideoPreview(File videoFile, File? thumbFile, _EphemeraSubstrateTheme theme) {
    return Stack(
      key: const Key('editor_ephemera_suspended_video'),
      fit: StackFit.expand,
      children: [
        if (thumbFile != null && thumbFile.existsSync())
          Image.file(thumbFile, fit: BoxFit.cover)
        else
          Container(
            color: theme.matteColor,
            child: _buildFallbackIcon(theme),
          ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70, width: 1.5),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptionField(_EphemeraSubstrateTheme theme) {
    return TextField(
      key: const Key('editor_ephemera_caption_field'),
      controller: widget.sheet.captionController,
      focusNode: widget.sheet.focusNode,
      maxLines: 2,
      minLines: 1,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12.0,
        fontStyle: FontStyle.italic,
        fontFamily: widget.fontFamily,
        color: theme.captionTextColor,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: '添加插页题注... · Add caption...',
        hintStyle: TextStyle(
          fontSize: 12.0,
          fontStyle: FontStyle.italic,
          fontFamily: widget.fontFamily,
          color: theme.captionHintColor,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      onChanged: (text) {
        widget.onCaptionChanged?.call(text);
      },
    );
  }

  Widget _buildRemoveButton(_EphemeraSubstrateTheme theme) {
    return Align(
      alignment: Alignment.center,
      child: Semantics(
        label: '移除插页 · Remove Ephemera Sheet',
        button: true,
        container: true,
        excludeSemantics: true,
        child: TextButton.icon(
          key: const Key('editor_remove_ephemera_btn'),
          onPressed: widget.onDelete,
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: const Text(
            '移除插页 · Remove Ephemera Sheet',
            style: TextStyle(fontSize: 11),
          ),
          style: TextButton.styleFrom(
            foregroundColor: theme.deleteButtonColor,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: const Size(44, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}
