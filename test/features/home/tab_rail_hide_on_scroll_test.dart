import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/albums/data/album_repository.dart';
import 'package:memodiary/features/settings/screens/settings_screen.dart';
import '../../helpers/home_shell_test_harness.dart';

void main() {
  final harness = HomeShellHarness.register();

  const viewSize = Size(400, 800);
  final tabRail = HomeShellHarness.tabRail;
  final timelineList = find.byType(CustomScrollView);
  final albumList = find.byType(ListView);

  Future<void> openAlbumsTab(WidgetTester tester) => harness.selectTab(tester, HomeShellHarness.albumsTab);

  Future<void> scrollBy(WidgetTester tester, Finder list, double dy) async {
    await tester.drag(list, Offset(0, dy));
    await tester.pumpAndSettle();
  }

  /// The rail is shown while its top edge is inside the view, and hidden once
  /// it has slid fully below the bottom edge.
  void expectRailShown(WidgetTester tester, bool shown) {
    final top = tester.getRect(tabRail).top;
    expect(top < viewSize.height, shown, reason: 'rail top at $top');
  }

  group('Tab Rail hide on scroll', () {
    testWidgets('scrolling the timeline forward hides the rail; scrolling back reveals it', (tester) async {
      await harness.seedEntries(12);
      await harness.pumpApp(tester);
      expectRailShown(tester, true);

      await scrollBy(tester, timelineList, -300);
      expectRailShown(tester, false);

      await scrollBy(tester, timelineList, 100);
      expectRailShown(tester, true);
    });

    testWidgets('scrolling the 相册 list forward hides the rail; scrolling back reveals it', (tester) async {
      await harness.seedAlbums(12);
      await harness.pumpApp(tester);
      await openAlbumsTab(tester);

      await scrollBy(tester, albumList, -300);
      expectRailShown(tester, false);

      await scrollBy(tester, albumList, 100);
      expectRailShown(tester, true);
      await harness.unmountApp(tester);
    });

    testWidgets('switching tabs while the rail is hidden reveals it', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await harness.seedAlbums(12);
      await harness.pumpApp(tester);
      await openAlbumsTab(tester);
      await scrollBy(tester, albumList, -300);
      expectRailShown(tester, false);

      // Android Back on 相册 switches to 日记: the one tab switch that can
      // happen while the rail is out of reach.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CustomScrollView), findsOneWidget);
      expectRailShown(tester, true);
      await harness.unmountApp(tester);
    });

    testWidgets('a list too short to scroll never hides the rail', (tester) async {
      await harness.seedAlbums(1);
      await harness.pumpApp(tester);
      await openAlbumsTab(tester);

      await scrollBy(tester, albumList, -300);
      expectRailShown(tester, true);
      await harness.unmountApp(tester);
    });

    testWidgets('a list that shrinks below scrollable while the rail is hidden reveals it', (tester) async {
      final albumIds = await harness.seedAlbums(12);
      await harness.pumpApp(tester);
      await openAlbumsTab(tester);
      await scrollBy(tester, albumList, -300);
      expectRailShown(tester, false);

      final repository = AlbumRepository(database: harness.db, mediaService: harness.mediaService);
      for (final id in albumIds.skip(1)) {
        await repository.deleteCollection(id);
      }
      await tester.pumpAndSettle();
      expectRailShown(tester, true);
      await harness.unmountApp(tester);
    });

    testWidgets('with reduced motion on, the rail stays shown', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await harness.seedEntries(12);
      await harness.pumpApp(tester);

      await scrollBy(tester, timelineList, -300);
      expectRailShown(tester, true);
    });

    testWidgets('horizontal Date Index Tray scrolls never toggle the rail', (tester) async {
      await harness.seedEntries(12);
      await harness.pumpApp(tester);
      final monthChips = find.ancestor(
        of: find.byKey(const Key('timeline_month_chip_6')),
        matching: find.byType(SingleChildScrollView),
      );

      await tester.drag(monthChips, const Offset(-200, 0));
      await tester.pumpAndSettle();
      expectRailShown(tester, true);

      await scrollBy(tester, timelineList, -300);
      await tester.drag(monthChips, const Offset(200, 0));
      await tester.pumpAndSettle();
      expectRailShown(tester, false);
    });

    testWidgets('scrolls inside a pushed screen never toggle the rail', (tester) async {
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const Key('timeline_settings_button')));
      await tester.pumpAndSettle();
      final settings = find.byType(SettingsScreen);
      expect(tabRail, findsNothing);
      await tester.drag(
        find.descendant(of: settings, matching: find.byType(ListView)).first,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      Navigator.of(tester.element(settings)).pop();
      await tester.pumpAndSettle();
      expectRailShown(tester, true);
    });
  });
}
