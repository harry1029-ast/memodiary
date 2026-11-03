import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/models/media_embed_data.dart';
import 'package:memodiary/features/editor/widgets/sandboxed_video_player.dart';
import 'package:memodiary/features/editor/widgets/stationery_ephemera_sheet.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_silk_corner_mounts_painter.dart';
import 'package:path/path.dart' as p;
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../../helpers/editor_test_harness.dart';

void main() {
  late Directory tempDir;
  late MediaSandboxService sandboxService;

  setUpAll(() {
    VideoPlayerPlatform.instance = FakeEditorVideoPlatform();
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ephemera_sheet_test_');
    sandboxService = SyncTestMediaSandboxService(
      tempDir: tempDir,
      autoCreateMissingOnLookup: false,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget createSubject({
    required EphemeraSheet sheet,
    Rect? innerFrameRect,
    String? title,
    bool isActiveSheet = true,
    VoidCallback? onDelete,
    ValueChanged<String>? onCaptionChanged,
    bool isPaperDark = false,
    PaperSubstrate? substrate,
    Color? inkColor,
    MediaSandboxService? service,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 360,
            height: 600,
            child: StationeryEphemeraSheet(
              sheet: sheet,
              innerFrameRect: innerFrameRect,
              title: title,
              mediaSandboxService: service ?? sandboxService,
              isActiveSheet: isActiveSheet,
              onDelete: onDelete,
              onCaptionChanged: onCaptionChanged,
              isPaperDark: isPaperDark,
              substrate: substrate,
              inkColor: inkColor,
            ),
          ),
        ),
      ),
    );
  }

  group('StationeryEphemeraSheet Photo Mount Tests', () {
    testWidgets('renders sandboxed photo with matte framing, silk corners, and strict SPEC-008 colophon', (tester) async {
      final mediaDir = Directory(p.join(tempDir.path, 'media'))..createSync(recursive: true);
      final photoFile = File(p.join(mediaDir.path, 'garden.webp'))
        ..writeAsBytesSync(kValid1x1PngBytes);

      final sheet = EphemeraSheet(
        sheetIndex: 1,
        mediaType: EphemeraMediaType.image,
        mediaData: const MediaEmbedData(
          path: 'media/garden.webp',
          caption: '春日游园 · Spring Garden',
        ),
      );

      await tester.pumpWidget(
        createSubject(
          sheet: sheet,
          title: '江南杂记',
        ),
      );
      await tester.pumpAndSettle();

      expect(photoFile.existsSync(), isTrue);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byKey(const Key('editor_ephemera_matte_container')), findsOneWidget);
      expect(find.byKey(const Key('editor_ephemera_silk_corners')), findsOneWidget);
      expect(find.text('《江南杂记》 · 第 2 页'), findsOneWidget);
      expect(find.text('珍藏拓影 · 插页'), findsNothing);

      final customPaint = tester.widget<CustomPaint>(find.byKey(const Key('editor_ephemera_silk_corners')));
      expect(customPaint.painter, isA<FolioSilkCornerMountsPainter>());

      sheet.dispose();
    });

    testWidgets('displays fallback photo icon when file is missing in sandbox', (tester) async {
      final sheet = EphemeraSheet(
        sheetIndex: 0,
        mediaType: EphemeraMediaType.image,
        mediaData: const MediaEmbedData(path: 'media/non_existent.webp'),
      );

      await tester.pumpWidget(createSubject(sheet: sheet));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editor_ephemera_fallback_icon')), findsOneWidget);
      expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
      expect(find.byType(Image), findsNothing);

      sheet.dispose();
    });
  });

  group('StationeryEphemeraSheet Video Mount Tests', () {
    testWidgets('renders SandboxedVideoPlayer when sheet is active without right-side subtitle badge', (tester) async {
      final mediaDir = Directory(p.join(tempDir.path, 'media'))..createSync(recursive: true);
      final videoFile = File(p.join(mediaDir.path, 'lake.mp4'))
        ..writeAsBytesSync(kValidMp4FtypBytes);

      final sheet = EphemeraSheet(
        sheetIndex: 2,
        mediaType: EphemeraMediaType.video,
        mediaData: const MediaEmbedData(path: 'media/lake.mp4'),
      );

      await tester.pumpWidget(
        createSubject(
          sheet: sheet,
          title: '西湖夜游',
          isActiveSheet: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(videoFile.existsSync(), isTrue);
      expect(find.byType(SandboxedVideoPlayer), findsOneWidget);
      expect(find.text('《西湖夜游》 · 第 3 页'), findsOneWidget);
      expect(find.text('动态拓片 · 影印'), findsNothing);

      sheet.dispose();
    });

    testWidgets('renders suspended video preview when sheet is not active', (tester) async {
      final mediaDir = Directory(p.join(tempDir.path, 'media'))..createSync(recursive: true);
      File(p.join(mediaDir.path, 'stream.mp4')).writeAsBytesSync(kValidMp4FtypBytes);

      final sheet = EphemeraSheet(
        sheetIndex: 0,
        mediaType: EphemeraMediaType.video,
        mediaData: const MediaEmbedData(path: 'media/stream.mp4'),
      );

      await tester.pumpWidget(
        createSubject(
          sheet: sheet,
          isActiveSheet: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SandboxedVideoPlayer), findsNothing);
      expect(find.byKey(const Key('editor_ephemera_suspended_video')), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      sheet.dispose();
    });

    testWidgets('displays fallback video icon when video file does not exist', (tester) async {
      final sheet = EphemeraSheet(
        sheetIndex: 0,
        mediaType: EphemeraMediaType.video,
        mediaData: const MediaEmbedData(path: 'media/missing_clip.mp4'),
      );

      await tester.pumpWidget(createSubject(sheet: sheet));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editor_ephemera_fallback_icon')), findsOneWidget);
      expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);

      sheet.dispose();
    });
  });

  group('StationeryEphemeraSheet Caption & Editing Tests', () {
    testWidgets('editing caption text field updates currentMediaData and fires onCaptionChanged', (tester) async {
      String? changedCaption;
      final sheet = EphemeraSheet(
        sheetIndex: 0,
        mediaType: EphemeraMediaType.image,
        mediaData: const MediaEmbedData(
          path: 'media/tree.webp',
          caption: '初始题注',
        ),
      );

      await tester.pumpWidget(
        createSubject(
          sheet: sheet,
          onCaptionChanged: (text) => changedCaption = text,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('初始题注'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('editor_ephemera_caption_field')),
        '深秋红枫 · Autumn Leaves',
      );
      await tester.pump();

      expect(changedCaption, equals('深秋红枫 · Autumn Leaves'));
      expect(sheet.currentMediaData.caption, equals('深秋红枫 · Autumn Leaves'));
      expect(sheet.caption, equals('深秋红枫 · Autumn Leaves'));

      sheet.dispose();
    });

    testWidgets('shows placeholder hint when caption is empty', (tester) async {
      final sheet = EphemeraSheet(
        sheetIndex: 0,
        mediaType: EphemeraMediaType.image,
        mediaData: const MediaEmbedData(path: 'media/tree.webp', caption: ''),
      );

      await tester.pumpWidget(createSubject(sheet: sheet));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byKey(const Key('editor_ephemera_caption_field')));
      expect(textField.decoration?.hintText, contains('添加插页题注...'));

      sheet.dispose();
    });
  });

  group('StationeryEphemeraSheet Accessible Deletion Tests', () {
    testWidgets('tap on remove button triggers onDelete callback with semantics label', (tester) async {
      var deleteInvoked = false;
      final sheet = EphemeraSheet(
        sheetIndex: 1,
        mediaType: EphemeraMediaType.image,
        mediaData: const MediaEmbedData(path: 'media/temp.webp'),
      );

      await tester.pumpWidget(
        createSubject(
          sheet: sheet,
          onDelete: () => deleteInvoked = true,
        ),
      );
      await tester.pumpAndSettle();

      final removeBtnFinder = find.byKey(const Key('editor_remove_ephemera_btn'));
      expect(removeBtnFinder, findsOneWidget);
      expect(
        find.bySemanticsLabel('移除插页 · Remove Ephemera Sheet'),
        findsOneWidget,
      );

      await tester.tap(removeBtnFinder);
      await tester.pump();

      expect(deleteInvoked, isTrue);

      sheet.dispose();
    });
  });

  group('StationeryEphemeraSheet Substrate Contrast Adaptation Tests', () {
    testWidgets('adapts matte color and silk corner tint for light substrate', (tester) async {
      final sheet = EphemeraSheet(
        sheetIndex: 0,
        mediaType: EphemeraMediaType.image,
        mediaData: const MediaEmbedData(path: 'media/art.webp'),
      );

      await tester.pumpWidget(
        createSubject(
          sheet: sheet,
          isPaperDark: false,
          substrate: PaperSubstrate.xuan,
        ),
      );
      await tester.pumpAndSettle();

      final matteContainer = tester.widget<Container>(
        find.byKey(const Key('editor_ephemera_matte_container')),
      );
      final decoration = matteContainer.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFFFDFBF7)));

      final customPaint = tester.widget<CustomPaint>(
        find.byKey(const Key('editor_ephemera_silk_corners')),
      );
      final painter = customPaint.painter as FolioSilkCornerMountsPainter;
      expect(painter.silkColor, equals(const Color(0xC0DFC898)));

      sheet.dispose();
    });

    testWidgets('adapts matte color and silk corner tint for dark obsidian substrate', (tester) async {
      final sheet = EphemeraSheet(
        sheetIndex: 0,
        mediaType: EphemeraMediaType.image,
        mediaData: const MediaEmbedData(path: 'media/dark.webp'),
      );

      await tester.pumpWidget(
        createSubject(
          sheet: sheet,
          isPaperDark: true,
          substrate: PaperSubstrate.obsidian,
        ),
      );
      await tester.pumpAndSettle();

      final matteContainer = tester.widget<Container>(
        find.byKey(const Key('editor_ephemera_matte_container')),
      );
      final decoration = matteContainer.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF141619)));

      final customPaint = tester.widget<CustomPaint>(
        find.byKey(const Key('editor_ephemera_silk_corners')),
      );
      final painter = customPaint.painter as FolioSilkCornerMountsPainter;
      expect(painter.silkColor, equals(const Color(0xD0C8A055)));

      sheet.dispose();
    });
  });

  group('StationeryEphemeraSheet Colophon & Geometry Tests', () {
    testWidgets('falls back to 《无题》 when title is empty or null', (tester) async {
      final sheet = EphemeraSheet(
        sheetIndex: 0,
        mediaType: EphemeraMediaType.image,
        mediaData: const MediaEmbedData(path: 'media/untitled.webp'),
      );

      await tester.pumpWidget(createSubject(sheet: sheet, title: null));
      await tester.pumpAndSettle();

      expect(find.text('《无题》 · 第 1 页'), findsOneWidget);

      sheet.dispose();
    });

    testWidgets('constrains Paper Heart strictly to provided innerFrameRect', (tester) async {
      final sheet = EphemeraSheet(
        sheetIndex: 0,
        mediaType: EphemeraMediaType.image,
        mediaData: const MediaEmbedData(path: 'media/rect_test.webp'),
      );

      const targetRect = Rect.fromLTWH(24, 48, 312, 504);

      await tester.pumpWidget(
        createSubject(
          sheet: sheet,
          innerFrameRect: targetRect,
        ),
      );
      await tester.pumpAndSettle();

      final paperHeartFinder = find.byKey(const Key('stationery_ephemera_paper_heart'));
      expect(paperHeartFinder, findsOneWidget);

      final renderedRect = tester.getRect(paperHeartFinder);
      expect(renderedRect.left, equals(targetRect.left));
      expect(renderedRect.top, equals(targetRect.top));
      expect(renderedRect.width, equals(targetRect.width));
      expect(renderedRect.height, equals(targetRect.height));

      sheet.dispose();
    });
  });
}
