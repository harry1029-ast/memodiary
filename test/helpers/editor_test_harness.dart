import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/dictation_service.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/editor/services/thought_spark_service.dart';

/// Valid 1x1 transparent PNG payload (67 bytes) for deterministic image decoding in tests.
const List<int> kValid1x1PngBytes = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

/// Valid 32-byte ISO BMFF `ftyp` MP4 box header for deterministic video fixtures.
const List<int> kValidMp4FtypBytes = <int>[
  0x00, 0x00, 0x00, 0x20,
  0x66, 0x74, 0x79, 0x70,
  0x69, 0x73, 0x6F, 0x6D,
  0x00, 0x00, 0x02, 0x00,
  0x69, 0x73, 0x6F, 0x6D,
  0x69, 0x73, 0x6F, 0x32,
  0x61, 0x76, 0x63, 0x31,
  0x6D, 0x70, 0x34, 0x31,
];

/// Shared headless fake [VideoPlayerPlatform] for editor and ephemera widget tests.
class FakeEditorVideoPlatform extends VideoPlayerPlatform {
  final StreamController<VideoEvent> _eventController =
      StreamController<VideoEvent>.broadcast();

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<int?> create(DataSource dataSource) async => 0;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _eventController.stream;

  @override
  Widget buildView(int playerId) => const SizedBox(key: ValueKey('fake_video_view'));
}

/// Shared stub [ImagePicker] returning deterministic image or video [XFile] fixtures.
class StubEditorImagePicker extends ImagePicker {
  final XFile? imageResult;
  final XFile? videoResult;

  /// Gallery multi-pick result; defaults to [imageResult] alone.
  final List<XFile>? multiImageResults;

  StubEditorImagePicker({
    this.imageResult,
    this.videoResult,
    this.multiImageResults,
  });

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async =>
      imageResult;

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async =>
      multiImageResults ?? [if (imageResult != null) imageResult!];

  @override
  Future<XFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async =>
      videoResult;
}

/// Synchronous `dart:io` sandbox double avoiding `FakeAsync` deadlocks inside `testWidgets`.
class SyncTestMediaSandboxService extends MediaSandboxService {
  final Directory tempDir;
  final bool autoCreateMissingOnLookup;
  int _counter = 0;

  SyncTestMediaSandboxService({
    required this.tempDir,
    this.autoCreateMissingOnLookup = true,
  }) : super(baseDirProvider: () async => tempDir);

  @override
  Future<String> copyAndCompressImage(File sourceFile) async {
    final mediaDir = Directory('${tempDir.path}/media');
    if (!mediaDir.existsSync()) {
      mediaDir.createSync(recursive: true);
    }
    _counter++;
    final targetRelativePath = 'media/photo_${_counter}_test.webp';
    final targetFile = File('${tempDir.path}/$targetRelativePath');
    if (sourceFile.existsSync()) {
      sourceFile.copySync(targetFile.path);
    } else {
      targetFile.writeAsBytesSync(kValid1x1PngBytes);
    }
    return targetRelativePath;
  }

  @override
  Future<VideoSandboxResult> copyAndSandboxVideo(
    File sourceFile, {
    Duration maxDuration = const Duration(seconds: 60),
  }) async {
    final mediaDir = Directory('${tempDir.path}/media');
    if (!mediaDir.existsSync()) {
      mediaDir.createSync(recursive: true);
    }
    _counter++;
    final targetRelativePath = 'media/video_${_counter}_test.mp4';
    final targetFile = File('${tempDir.path}/$targetRelativePath');
    if (sourceFile.existsSync()) {
      sourceFile.copySync(targetFile.path);
    } else {
      targetFile.writeAsBytesSync(kValidMp4FtypBytes);
    }
    return VideoSandboxResult(
      relativePath: targetRelativePath,
      thumbnailPath: '',
      durationSeconds: 10,
    );
  }

  @override
  Future<File> getFileFromRelativePath(String relativePath) async {
    final file = File('${tempDir.path}/$relativePath');
    if (!file.existsSync() && autoCreateMissingOnLookup) {
      final parentDir = file.parent;
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }
      if (relativePath.endsWith('.mp4')) {
        file.writeAsBytesSync(kValidMp4FtypBytes);
      } else {
        file.writeAsBytesSync(kValid1x1PngBytes);
      }
    }
    return file;
  }
}

/// Shared fake [AudioSanctumService] for top bar and editor sanctum widget tests.
class FakeAudioSanctumService extends ChangeNotifier implements AudioSanctumService {
  bool _isPlaying = false;

  @override
  bool get isPlaying => _isPlaying;

  void setPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Reusable harness helper that mounts [EntryEditorScreen] with optional viewport overrides
/// and settles initial asynchronous entry loading.
Future<void> pumpEntryEditorScreen(
  WidgetTester tester, {
  required AppDatabase database,
  required MediaSandboxService mediaSandboxService,
  required String entryId,
  ImagePicker? imagePicker,
  DictationService? dictationService,
  ThoughtSparkService? thoughtSparkService,
  AudioSanctumService? audioSanctumService,
  Size? viewportSize,
  ThemeData? theme,
  bool launchFromRoute = false,
}) async {
  if (viewportSize != null) {
    tester.view.physicalSize = viewportSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  EntryEditorScreen buildEditor() => EntryEditorScreen(
        database: database,
        mediaSandboxService: mediaSandboxService,
        entryId: entryId,
        imagePicker: imagePicker,
        dictationService: dictationService,
        thoughtSparkService: thoughtSparkService,
        audioSanctumService: audioSanctumService,
      );

  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? InkDiaryTheme.light,
      home: launchFromRoute
          ? Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    key: const Key('launch_editor'),
                    onPressed: () => Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => buildEditor()),
                    ),
                    child: const Text('launch'),
                  ),
                ),
              ),
            )
          : buildEditor(),
    ),
  );
  await tester.pumpAndSettle();
  if (launchFromRoute) {
    await tester.tap(find.byKey(const Key('launch_editor')));
    await tester.pumpAndSettle();
  }
}

