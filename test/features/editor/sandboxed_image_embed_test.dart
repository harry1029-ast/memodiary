import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/widgets/sandboxed_image_embed_builder.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late MediaSandboxService sandboxService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('image_embed_test_');
    sandboxService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
      compressor: (sourcePath, targetPath, {minWidth = 1600, minHeight = 1600, quality = 80}) async {
        final src = File(sourcePath);
        return src.copy(targetPath);
      },
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SandboxedImageEmbedBuilder Tests', () {
    test('builder key matches BlockEmbed.imageType', () {
      final builder = SandboxedImageEmbedBuilder(mediaSandboxService: sandboxService);
      expect(builder.key, BlockEmbed.imageType);
      expect(builder.expanded, isFalse);
    });

    testWidgets('resolves and renders relative sandboxed image file', (tester) async {
      // Create test image in sandbox media/ directory
      final mediaDir = Directory(p.join(tempDir.path, 'media'))..createSync(recursive: true);
      final testFile = File(p.join(mediaDir.path, 'embed_test.webp'))..writeAsStringSync('dummy image data');

      final controller = QuillController.basic();
      // Insert image embed with relative path
      controller.document.insert(0, BlockEmbed.image('media/embed_test.webp'));

      final builder = SandboxedImageEmbedBuilder(
        mediaSandboxService: sandboxService,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuillEditor(
              controller: controller,
              focusNode: FocusNode(),
              scrollController: ScrollController(),
              config: QuillEditorConfig(
                embedBuilders: [builder],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that FutureBuilder resolved the image file
      expect(find.byType(Image), findsOneWidget);
      expect(testFile.existsSync(), isTrue);

      controller.dispose();
    });

    testWidgets('displays fallback placeholder when image file is missing in sandbox', (tester) async {
      final controller = QuillController.basic();
      controller.document.insert(0, BlockEmbed.image('media/non_existent.webp'));

      final builder = SandboxedImageEmbedBuilder(
        mediaSandboxService: sandboxService,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuillEditor(
              controller: controller,
              focusNode: FocusNode(),
              scrollController: ScrollController(),
              config: QuillEditorConfig(
                embedBuilders: [builder],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Image not found in sandbox'), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);

      controller.dispose();
    });
  });
}

