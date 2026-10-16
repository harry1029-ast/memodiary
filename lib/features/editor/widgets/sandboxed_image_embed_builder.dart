import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../core/services/media_sandbox_service.dart';

/// Custom EmbedBuilder for flutter_quill that resolves sandboxed relative paths
/// (e.g. 'media/{uuid}.webp') to absolute Files using MediaSandboxService.
class SandboxedImageEmbedBuilder extends EmbedBuilder {
  final MediaSandboxService mediaSandboxService;
  final VoidCallback? onImageRemoved;

  const SandboxedImageEmbedBuilder({
    required this.mediaSandboxService,
    this.onImageRemoved,
  });

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final imageSource = embedContext.node.value.data as String;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: FutureBuilder<File>(
        future: _resolveFile(imageSource),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.existsSync()) {
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
                  Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey.shade400),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  file,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.error_outline)),
                  ),
                ),
              ),
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
                        // Remove image embed from Quill document
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

