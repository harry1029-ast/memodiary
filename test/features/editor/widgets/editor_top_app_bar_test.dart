import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/controllers/editor_autosave_manager.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/editor/widgets/editor_top_app_bar.dart';
import 'package:memodiary/features/editor/widgets/scholar_chest/scholar_chest_drawer.dart';

class _FakeAudioSanctumService extends ChangeNotifier implements AudioSanctumService {
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

void main() {
  group('EditorTopAppBar Widget Tests', () {
    late ValueNotifier<AutosaveStatus> autosaveStatusNotifier;
    late _FakeAudioSanctumService fakeAudioService;

    setUp(() {
      autosaveStatusNotifier = ValueNotifier<AutosaveStatus>(AutosaveStatus.saved);
      fakeAudioService = _FakeAudioSanctumService();
    });

    tearDown(() {
      autosaveStatusNotifier.dispose();
      fakeAudioService.dispose();
    });

    testWidgets('renders all core actions and triggers corresponding callbacks', (tester) async {
      var savedAndExited = false;
      var openedKeepsake = false;
      ScholarArtifactType? chestArtifact;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: EditorTopAppBar(
              paperColor: Colors.white,
              iconColor: Colors.black,
              autosaveStatusNotifier: autosaveStatusNotifier,
              audioSanctumService: fakeAudioService,
              unlockAt: null,
              onSaveAndExit: () => savedAndExited = true,
              onOpenKeepsakeScroll: () => openedKeepsake = true,
              onOpenScholarChest: ([artifact = ScholarArtifactType.stationeryFan]) {
                chestArtifact = artifact;
              },
            ),
          ),
        ),
      );

      // Verify Back button
      expect(find.byTooltip('返回 · Back'), findsOneWidget);
      await tester.tap(find.byTooltip('返回 · Back'));
      expect(savedAndExited, isTrue);

      // Verify Keepsake scroll button
      expect(find.byKey(const Key('top_bar_keepsake_scroll_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('top_bar_keepsake_scroll_button')));
      expect(openedKeepsake, isTrue);

      // Verify Scholar chest button
      expect(find.byKey(const Key('top_bar_scholar_chest_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('top_bar_scholar_chest_button')));
      expect(chestArtifact, equals(ScholarArtifactType.stationeryFan));

      // Verify Done button
      savedAndExited = false;
      expect(find.byKey(const Key('editor_seal_done_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('editor_seal_done_btn')));
      expect(savedAndExited, isTrue);
    });

    testWidgets('updates autosave status label reactively', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: EditorTopAppBar(
              paperColor: Colors.white,
              iconColor: Colors.black,
              autosaveStatusNotifier: autosaveStatusNotifier,
              audioSanctumService: fakeAudioService,
              unlockAt: null,
              onSaveAndExit: () {},
              onOpenKeepsakeScroll: () {},
              onOpenScholarChest: ([artifact = ScholarArtifactType.stationeryFan]) {},
            ),
          ),
        ),
      );

      expect(find.text('已保存'), findsOneWidget);

      autosaveStatusNotifier.value = AutosaveStatus.saving;
      await tester.pump();
      expect(find.text('存墨中...'), findsOneWidget);

      autosaveStatusNotifier.value = AutosaveStatus.unsaved;
      await tester.pump();
      expect(find.text('草稿未存'), findsOneWidget);
    });

    testWidgets('shows soundscape pill when audio is playing and triggers guqin zither artifact', (tester) async {
      ScholarArtifactType? openedArtifact;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: EditorTopAppBar(
              paperColor: Colors.white,
              iconColor: Colors.black,
              autosaveStatusNotifier: autosaveStatusNotifier,
              audioSanctumService: fakeAudioService,
              unlockAt: null,
              onSaveAndExit: () {},
              onOpenKeepsakeScroll: () {},
              onOpenScholarChest: ([artifact = ScholarArtifactType.stationeryFan]) {
                openedArtifact = artifact;
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('top_bar_soundscape_pill')), findsNothing);

      fakeAudioService.setPlaying(true);
      await tester.pump();

      expect(find.byKey(const Key('top_bar_soundscape_pill')), findsOneWidget);
      expect(find.text('清音'), findsOneWidget);

      await tester.tap(find.byKey(const Key('top_bar_soundscape_pill')));
      expect(openedArtifact, equals(ScholarArtifactType.guqinZither));
    });

    testWidgets('shows lock pill when entry is locked in the future and triggers fish lock artifact', (tester) async {
      ScholarArtifactType? openedArtifact;
      final futureDate = DateTime.now().add(const Duration(days: 7));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: EditorTopAppBar(
              paperColor: Colors.white,
              iconColor: Colors.black,
              autosaveStatusNotifier: autosaveStatusNotifier,
              audioSanctumService: fakeAudioService,
              unlockAt: futureDate,
              onSaveAndExit: () {},
              onOpenKeepsakeScroll: () {},
              onOpenScholarChest: ([artifact = ScholarArtifactType.stationeryFan]) {
                openedArtifact = artifact;
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('top_bar_lock_pill')), findsOneWidget);
      expect(find.text('封缄'), findsOneWidget);

      await tester.tap(find.byKey(const Key('top_bar_lock_pill')));
      expect(openedArtifact, equals(ScholarArtifactType.fishLock));
    });
  });
}
