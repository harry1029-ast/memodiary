import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../core/services/media_sandbox_service.dart';
import 'sandboxed_video_player.dart';

/// Custom EmbedBuilder for flutter_quill that renders sandboxed video blocks
/// with inline playback controls, poster previews, and edit-mode deletion.
class SandboxedVideoEmbedBuilder extends EmbedBuilder {
  final MediaSandboxService mediaSandboxService;
  final VoidCallback? onVideoRemoved;

  const SandboxedVideoEmbedBuilder({
    required this.mediaSandboxService,
    this.onVideoRemoved,
  });

  @override
  String get key => BlockEmbed.videoType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final videoSource = embedContext.node.value.data as String;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: FutureBuilder<List<File?>>(
        future: _resolveMediaFiles(videoSource),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data![0] == null) {
            return Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
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

              // Edit mode delete button
              if (!embedContext.readOnly)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, size: 16, color: Colors.white),
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
