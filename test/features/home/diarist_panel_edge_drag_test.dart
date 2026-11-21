import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/intro/screens/book_intro_screen.dart';
import 'package:memodiary/features/intro/widgets/bottom_seal_slider.dart';
import '../../helpers/home_shell_test_harness.dart';

void main() {
  final harness = HomeShellHarness.register();
  final panel = HomeShellHarness.panel;

  /// 400dp wide, so the open panel is 340dp; a 24dp status bar insets the
  /// band's top.
  Future<void> pumpApp(
    WidgetTester tester, {
    bool showIntroOnLaunch = false,
    Size size = const Size(400, 800),
  }) =>
      harness.pumpApp(tester, showIntroOnLaunch: showIntroOnLaunch, size: size, topPadding: 24);

  group('Left-edge drag band', () {
    testWidgets('a slow edge drag inside the band opens the panel past halfway', (tester) async {
      await pumpApp(tester);

      await tester.timedDragFrom(const Offset(4, 120), const Offset(220, 0), const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(panel, findsOneWidget);
      expect(tester.getTopLeft(panel).dx, 0);
    });

    testWidgets('the panel follows the finger mid-drag; a short slow drag settles closed', (tester) async {
      await pumpApp(tester);

      final gesture = await tester.startGesture(const Offset(4, 120));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump(const Duration(milliseconds: 100));
      }
      // 100dp of a 340dp panel is showing.
      expect(tester.getTopLeft(panel).dx, closeTo(100 - 340, 0.5));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
    });

    testWidgets('a quick short fling from the band opens the panel', (tester) async {
      await pumpApp(tester);

      await tester.flingFrom(const Offset(4, 200), const Offset(80, 0), 1200);
      await tester.pumpAndSettle();

      expect(panel, findsOneWidget);
      expect(tester.getTopLeft(panel).dx, 0);
    });

    testWidgets('an edge drag below the band does not open the panel', (tester) async {
      await pumpApp(tester);

      // The band runs from the 24dp safe-area top to 224dp.
      await tester.timedDragFrom(const Offset(4, 240), const Offset(260, 0), const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      await tester.flingFrom(const Offset(4, 500), const Offset(200, 0), 1500);
      await tester.pumpAndSettle();

      expect(panel, findsNothing);
    });

    testWidgets('a tap on the avatar button under the band still opens the panel', (tester) async {
      await pumpApp(tester);

      final avatar = tester.getRect(find.byKey(const Key('timeline_avatar_button')));
      expect(avatar.left, lessThan(20), reason: 'the avatar overlaps the band strip');
      await tester.tapAt(Offset(avatar.left + 2, avatar.center.dy));
      await tester.pumpAndSettle();

      expect(panel, findsOneWidget);
    });
  });

  group('Silk ribbon tab', () {
    final ribbon = find.byKey(const Key('diarist_panel_ribbon_tab'));

    testWidgets('marks the band on the left edge of both tabs', (tester) async {
      await pumpApp(tester);

      // Band: 24dp status bar down to 224dp.
      final onDiary = tester.getRect(ribbon);
      expect(onDiary.left, 0);
      expect(onDiary.top, greaterThanOrEqualTo(24));
      expect(onDiary.bottom, lessThanOrEqualTo(224));

      await harness.selectTab(tester, HomeShellHarness.albumsTab);
      expect(tester.getRect(ribbon), onDiary);

      await harness.unmountApp(tester);
    });

    testWidgets('tapping the ribbon opens the panel', (tester) async {
      await pumpApp(tester);

      await tester.tap(ribbon);
      await tester.pumpAndSettle();

      expect(panel, findsOneWidget);
      expect(tester.getTopLeft(panel).dx, 0);
    });

    testWidgets('slides out with the panel edge and is gone once the panel is open', (tester) async {
      await pumpApp(tester);

      final gesture = await tester.startGesture(tester.getCenter(ribbon));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump(const Duration(milliseconds: 100));
      }
      // The panel is partly out; the ribbon rides its right edge.
      final panelRight = tester.getTopRight(panel).dx;
      expect(panelRight, greaterThan(50));
      expect(tester.getRect(ribbon).left, closeTo(panelRight, 0.5));

      await gesture.up();
      await tester.pumpAndSettle();
      await harness.openPanel(tester);
      expect(ribbon, findsNothing);
    });
  });

  group('Android Back-gesture exclusion', () {
    const channel = MethodChannel('memodiary/gesture_exclusion');
    late List<MethodCall> calls;

    setUp(() {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    const bandArgs = <String, Object?>{'left': 0.0, 'top': 24.0, 'width': 20.0, 'height': 200.0};

    testWidgets('the visible shell excludes a left-edge band of 200dp below the safe-area top', (tester) async {
      await pumpApp(tester);

      expect(calls, isNotEmpty);
      expect(calls.last.method, 'setRect');
      expect(calls.last.arguments, bandArgs);
    });

    testWidgets('a pushed screen clears the band; popping back to the shell sets it again', (tester) async {
      await pumpApp(tester);
      calls.clear();

      await tester.tap(HomeShellHarness.centreButton);
      await tester.pumpAndSettle();
      expect(find.byType(EntryEditorScreen), findsOneWidget);
      expect(calls.map((c) => c.method), ['clear']);

      calls.clear();
      Navigator.of(tester.element(find.byType(EntryEditorScreen))).pop();
      await tester.pumpAndSettle();
      expect(calls.map((c) => c.method), ['setRect']);
      expect(calls.single.arguments, bandArgs);
    });

    testWidgets('返回封面 clears the band; entering from the cover sets it', (tester) async {
      await pumpApp(tester, showIntroOnLaunch: true, size: const Size(800, 1600));
      expect(calls, isEmpty, reason: 'the cover reserves nothing');

      await tester.tap(find.byType(BottomSealSlider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.tap(find.text('私人日记'));
      await tester.pumpAndSettle();
      expect(calls.map((c) => c.method), ['setRect']);
      expect(calls.single.arguments, bandArgs);

      calls.clear();
      await tester.tap(find.byKey(const Key('timeline_avatar_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('diarist_panel_return_to_cover_row')));
      await tester.pumpAndSettle();
      expect(find.byType(BookIntroScreen), findsOneWidget);
      expect(calls.map((c) => c.method), ['clear']);
    });

    testWidgets('on iOS nothing is sent', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await pumpApp(tester);
        await tester.tap(HomeShellHarness.centreButton);
        await tester.pumpAndSettle();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }

      expect(calls, isEmpty);
    });
  });
}
