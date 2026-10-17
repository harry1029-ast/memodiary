import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/widgets/sandboxed_video_embed_builder.dart';
import 'package:memodiary/features/editor/widgets/sandboxed_video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final List<String> calls = [];
  bool isPlaying = false;
  final StreamController<VideoEvent> _eventStreamController =
      StreamController<VideoEvent>.broadcast();

  @override
  Future<void> init() async {
    calls.add('init');
  }

  @override
  Future<void> dispose(int playerId) async {
    calls.add('dispose($playerId)');
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    calls.add('create(${dataSource.sourceType})');
    return 0;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    calls.add('setLooping($playerId, $looping)');
  }

  @override
  Future<void> play(int playerId) async {
    calls.add('play($playerId)');
    isPlaying = true;
    _eventStreamController.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: true,
      ),
    );
  }

  @override
  Future<void> pause(int playerId) async {
    calls.add('pause($playerId)');
    isPlaying = false;
    _eventStreamController.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: false,
      ),
    );
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    calls.add('setVolume($playerId, $volume)');
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    calls.add('setPlaybackSpeed($playerId, $speed)');
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    calls.add('seekTo($playerId, $position)');
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    return Duration.zero;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    Future.microtask(() {
      if (!_eventStreamController.isClosed) {
        _eventStreamController.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(seconds: 15),
            size: const Size(1920, 1080),
          ),
        );
      }
    });
    return _eventStreamController.stream;
  }

  @override
  Widget buildView(int playerId) {
    return const SizedBox(key: ValueKey('fake_video_view'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MediaSandboxService mediaService;
  late FakeVideoPlayerPlatform fakeVideoPlayerPlatform;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('memodiary_video_embed_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );

    fakeVideoPlayerPlatform = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fakeVideoPlayerPlatform;
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('SandboxedVideoPlayer displays poster and initializes on play tap', (tester) async {
    final mediaDir = Directory('${tempDir.path}/media')..createSync(recursive: true);
    final videoFile = File('${mediaDir.path}/test_video.mp4')..writeAsBytesSync([1, 2, 3]);
    final thumbFile = File('${mediaDir.path}/test_video_thumb.webp')..writeAsBytesSync([4, 5, 6]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SandboxedVideoPlayer(
            videoFile: videoFile,
            thumbnailFile: thumbFile,
            duration: const Duration(seconds: 15),
          ),
        ),
      ),
    );

    // Initial poster state
    expect(find.byType(SandboxedVideoPlayer), findsOneWidget);
    expect(find.text('00:15'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Tap play
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify video player platform received init & create calls
    expect(fakeVideoPlayerPlatform.calls, contains('create(DataSourceType.file)'));
    expect(fakeVideoPlayerPlatform.calls, contains('play(0)'));
  });

  testWidgets('SandboxedVideoEmbedBuilder embeds video in QuillEditor and handles removal', (tester) async {
    final mediaDir = Directory('${tempDir.path}/media')..createSync(recursive: true);
    File('${mediaDir.path}/embed_test.mp4').writeAsBytesSync([1, 2, 3]);

    final doc = quill.Document();
    doc.insert(0, quill.BlockEmbed.video('media/embed_test.mp4'));

    final controller = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    bool videoRemoved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: quill.QuillEditor(
            controller: controller,
            focusNode: FocusNode(),
            scrollController: ScrollController(),
            config: quill.QuillEditorConfig(
              embedBuilders: [
                SandboxedVideoEmbedBuilder(
                  mediaSandboxService: mediaService,
                  onVideoRemoved: () => videoRemoved = true,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Pump past the FutureBuilder resolution
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SandboxedVideoPlayer), findsOneWidget);

    // Since readOnly is false (editable), delete button is present
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Tap delete button to remove video
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(videoRemoved, isTrue);
    expect(find.byType(SandboxedVideoPlayer), findsNothing);

    controller.dispose();
  });

  testWidgets('SandboxedVideoPlayer pauses on AppLifecycleState.paused transition', (tester) async {
    final mediaDir = Directory('${tempDir.path}/media')..createSync(recursive: true);
    final videoFile = File('${mediaDir.path}/lifecycle_video.mp4')..writeAsBytesSync([1, 2, 3]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SandboxedVideoPlayer(
            videoFile: videoFile,
            duration: const Duration(seconds: 10),
          ),
        ),
      ),
    );

    // Tap play
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(fakeVideoPlayerPlatform.calls, contains('play(0)'));

    // Trigger app lifecycle paused
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    // Verify pause called
    expect(fakeVideoPlayerPlatform.calls, contains('pause(0)'));
  });
}
