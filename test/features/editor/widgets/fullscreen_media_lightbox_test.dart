import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/widgets/fullscreen_media_lightbox.dart';
import '../../../helpers/editor_test_harness.dart';

void main() {
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('lightbox_viewer_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
    File('${tempDirectory.path}/media_photo_1.webp').writeAsBytesSync(kValid1x1PngBytes);
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  group('FullscreenMediaLightbox Viewer Tests', () {
    testWidgets('renders distraction-free viewer with pinch-to-zoom interactive viewer and close button', (tester) async {
      const item = SheetMediaItem(
        id: 'lightbox_test_item',
        mediaType: EphemeraMediaType.image,
        relativePath: 'media_photo_1.webp',
        caption: '钱塘江潮',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (innerContext) => ElevatedButton(
                onPressed: () {
                  FullscreenMediaLightbox.show(
                    innerContext,
                    item: item,
                    mediaSandboxService: sandboxService,
                  );
                },
                child: const Text('Open Lightbox'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Lightbox'));
      await tester.pumpAndSettle();

      expect(find.byType(FullscreenMediaLightbox), findsOneWidget);
      expect(find.text('钱塘江潮'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Close button dismisses lightbox
      final closeButton = find.byKey(const Key('fullscreen_lightbox_close_button'));
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.byType(FullscreenMediaLightbox), findsNothing);
    });
  });
}
