import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../models/media_embed_data.dart';
import 'grid_snapped_embed_container.dart';

/// Custom EmbedBuilder for flutter_quill that resolves sandboxed relative paths
/// (e.g. 'media/{uuid}.webp') and embeds photos within an Integer-Row Height Snapper
/// and Tipped-In Ephemera Card with contextual captioning and framing actions.
class SandboxedImageEmbedBuilder extends EmbedBuilder {
  final MediaSandboxService mediaSandboxService;
  final VoidCallback? onImageRemoved;
  final ValueChanged<String>? onEmbedMutated;
  final double rowHeight;

  const SandboxedImageEmbedBuilder({
    required this.mediaSandboxService,
    this.onImageRemoved,
    this.onEmbedMutated,
    this.rowHeight = 28.0,
  });

  @override
  String get key => BlockEmbed.imageType;

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
        onImageRemoved?.call();
      },
      onCaptionChanged: (newCaption) {
        final nextData = embedData.copyWith(caption: newCaption);
        final offset = embedContext.node.documentOffset;
        embedContext.controller.replaceText(
          offset,
          1,
          BlockEmbed.image(nextData.toEmbedValue()),
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
          BlockEmbed.image(nextData.toEmbedValue()),
          null,
        );
        onEmbedMutated?.call(nextData.toEmbedValue());
      },
      child: FutureBuilder<File>(
        future: _resolveFile(embedData.path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.grey.shade100,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.existsSync()) {
            return Container(
              color: Colors.grey.shade100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 6),
                  Text(
                    'Image not found in sandbox',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final file = snapshot.data!;
          return Stack(
            alignment: Alignment.topRight,
            children: [
              Image.file(
                file,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.error_outline)),
                ),
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
                        onImageRemoved?.call();
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

  Future<File> _resolveFile(String source) async {
    if (MediaSandboxService.isStrictlyRelative(source)) {
      return mediaSandboxService.getFileFromRelativePath(source);
    }
    // Fallback if already an absolute path
    return File(source);
  }
}
