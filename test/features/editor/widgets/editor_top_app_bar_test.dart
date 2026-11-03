import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/controllers/editor_autosave_manager.dart';
import 'package:memodiary/features/editor/widgets/editor_top_app_bar.dart';
import 'package:memodiary/features/editor/widgets/scholar_chest/scholar_chest_drawer.dart';

import '../../../helpers/editor_test_harness.dart';

void main() {
  group('EditorTopAppBar Widget Tests', () {
    late ValueNotifier<AutosaveStatus> autosaveStatusNotifier;
    late FakeAudioSanctumService fakeAudioService;

    setUp(() {
      autosaveStatusNotifier = ValueNotifier<AutosaveStatus>(AutosaveStatus.saved);
      fakeAudioService = FakeAudioSanctumService();
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

      expect(find.byTooltip('返回 · Back'), findsOneWidget);
      await tester.tap(find.byTooltip('返回 · Back'));
      expect(savedAndExited, isTrue);

      expect(find.byKey(const Key('top_bar_keepsake_scroll_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('top_bar_keepsake_scroll_button')));
      expect(openedKeepsake, isTrue);

      expect(find.byKey(const Key('top_bar_scholar_chest_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('top_bar_scholar_chest_button')));
      expect(chestArtifact, equals(ScholarArtifactType.stationeryFan));

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

    testWidgets('shows lock pill when entry is locked in the future and clamps text scaling <= 1.3', (tester) async {
      ScholarArtifactType? openedArtifact;
      final futureDate = DateTime.now().add(const Duration(days: 7));
      fakeAudioService.setPlaying(true);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            builder: (appContext, appChild) => MediaQuery(
              data: MediaQuery.of(appContext).copyWith(
                size: const Size(320, 640),
                textScaler: const TextScaler.linear(2.0),
              ),
              child: appChild!,
            ),
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
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('top_bar_lock_pill')), findsOneWidget);
      expect(find.text('封缄'), findsOneWidget);

      final innerContext = tester.element(find.text('封缄'));
      expect(
        MediaQuery.textScalerOf(innerContext).scale(10.0),
        lessThanOrEqualTo(13.001),
      );

      await tester.tap(find.byKey(const Key('top_bar_lock_pill')));
      expect(openedArtifact, equals(ScholarArtifactType.fishLock));
    });
  });
}
