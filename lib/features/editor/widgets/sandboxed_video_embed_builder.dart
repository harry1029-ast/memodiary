import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../models/media_embed_data.dart';
import 'grid_snapped_embed_container.dart';
import 'sandboxed_video_player.dart';

/// Custom EmbedBuilder for flutter_quill that renders sandboxed video blocks
/// inside an Integer-Row Height Snapper and Tipped-In Ephemera Card
/// with WebP poster thumbnail previews, inline playback, and contextual action bar.
class SandboxedVideoEmbedBuilder extends EmbedBuilder {
  final MediaSandboxService mediaSandboxService;
  final VoidCallback? onVideoRemoved;
  final ValueChanged<String>? onEmbedMutated;
  final double rowHeight;

  const SandboxedVideoEmbedBuilder({
    required this.mediaSandboxService,
    this.onVideoRemoved,
    this.onEmbedMutated,
    this.rowHeight = 28.0,
  });

  @override
  String get key => BlockEmbed.videoType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final embedData = MediaEmbedData.fromRaw(embedContext.node.value.data);

    return GridSnappedEmbedContainer(
      rowHeight: rowHeight,
      aspect: embedData.aspect,
      caption: embedData.caption,
      readOnly: embedContext.readOnly,
      onRemove: () {
        final offset = embedContext.node.documentOffset;
        embedContext.controller.replaceText(offset, 1, '', null);
        onVideoRemoved?.call();
      },
      onCaptionChanged: (newCaption) {
        final nextData = embedData.copyWith(caption: newCaption);
        final offset = embedContext.node.documentOffset;
        embedContext.controller.replaceText(
          offset,
          1,
          BlockEmbed.video(nextData.toEmbedValue()),
          null,
        );
        onEmbedMutated?.call(nextData.toEmbedValue());
      },
      onAspectChanged: (newAspect) {
        final nextData = embedData.copyWith(aspect: newAspect);
        final offset = embedContext.node.documentOffset;
        embedContext.controller.replaceText(
          offset,
          1,
          BlockEmbed.video(nextData.toEmbedValue()),
          null,
        );
        onEmbedMutated?.call(nextData.toEmbedValue());
      },
      child: FutureBuilder<List<File?>>(
        future: _resolveMediaFiles(embedData.path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: const Color(0xFF1E222D),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data![0] == null) {
            return Container(
              color: Colors.grey.shade100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 6),
                  Text(
                    'Video not found in sandbox',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final videoFile = snapshot.data![0]!;
          final thumbFile = snapshot.data![1];

          return Stack(
            alignment: Alignment.topRight,
            children: [
              SandboxedVideoPlayer(
                videoFile: videoFile,
                thumbnailFile: thumbFile,
              ),
              if (!embedContext.readOnly)
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, size: 14, color: Colors.white),
                      onPressed: () {
                        final offset = embedContext.node.documentOffset;
                        embedContext.controller.replaceText(offset, 1, '', null);
                        onVideoRemoved?.call();
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<List<File?>> _resolveMediaFiles(String videoSource) async {
    File videoFile;
    if (MediaSandboxService.isStrictlyRelative(videoSource)) {
      videoFile = await mediaSandboxService.getFileFromRelativePath(videoSource);
    } else {
      videoFile = File(videoSource);
    }

    if (!videoFile.existsSync()) {
      return [null, null];
    }

    // Try finding companion thumbnail: replace .mp4 with _thumb.webp
    File? thumbFile;
    if (videoSource.endsWith('.mp4')) {
      final thumbRelPath = videoSource.replaceAll(RegExp(r'\.mp4$'), '_thumb.webp');
      if (MediaSandboxService.isStrictlyRelative(thumbRelPath)) {
        final candidate = await mediaSandboxService.getFileFromRelativePath(thumbRelPath);
        if (candidate.existsSync()) {
          thumbFile = candidate;
        }
      }
    }

    return [videoFile, thumbFile];
  }
}
