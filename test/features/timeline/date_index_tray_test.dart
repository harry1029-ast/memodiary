import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/timeline/models/timeline_filter_state.dart';
import 'package:memodiary/features/timeline/widgets/chronicle_desk_palette.dart';
import 'package:memodiary/features/timeline/widgets/date_index_tray.dart';

void main() {
  group('DateIndexTray Widget Tests', () {
    testWidgets('renders default state with 全部, lunar stem-branch years, sort toggle, 12 months with dots, and collapsed 三旬', (tester) async {
      int? tappedYear = -1;
      int? tappedMonth;
      var sortToggled = false;

      final summary = TimelineDateFacetSummary(
        years: const [2026, 2025, 2024],
        activeMonths: const {4, 11},
        totalActiveEntries: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.dark,
          home: Scaffold(
            body: DateIndexTray(
              filters: const TimelineFilterState(),
              facetSummary: summary,
              xunExpandFactor: 0.0,
              onSelectYear: (year) => tappedYear = year,
              onSelectMonth: (month) => tappedMonth = month,
              onSelectXun: (_) {},
              onToggleSort: () => sortToggled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Row 1: 全部 + stem-branch years + sort toggle
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('2026 丙午'), findsOneWidget);
      expect(find.text('2025 乙巳'), findsOneWidget);
      expect(find.text('2024 甲辰'), findsOneWidget);
      expect(find.text('最新'), findsOneWidget);
      expect(find.text('↓'), findsOneWidget);

      // Row 2: 1月..12月 with active dots on 4 and 11
      expect(find.text('1月'), findsOneWidget);
      expect(find.text('11月'), findsOneWidget);
      expect(find.byKey(const Key('timeline_month_dot_11')), findsOneWidget);
      expect(find.byKey(const Key('timeline_month_dot_1')), findsNothing);

      // Row 3: 三旬 collapsed by default
      expect(find.text('上旬'), findsNothing);
      expect(find.text('中旬'), findsNothing);
      expect(find.text('下旬'), findsNothing);

      // Verify 44x44 minimum tap targets on Row 1 and Row 2 controls
      for (final keyName in const [
        'timeline_year_chip_all',
        'timeline_year_chip_2025',
        'timeline_sort_toggle_button',
        'timeline_month_chip_11',
      ]) {
        final size = tester.getSize(find.byKey(Key(keyName)));
        expect(size.width, greaterThanOrEqualTo(44.0), reason: keyName);
        expect(size.height, greaterThanOrEqualTo(44.0), reason: keyName);
      }

      // Tap interactions
      await tester.tap(find.byKey(const Key('timeline_year_chip_2025')));
      expect(tappedYear, equals(2025));

      await tester.tap(find.byKey(const Key('timeline_month_chip_11')));
      expect(tappedMonth, equals(11));

      await tester.tap(find.byKey(const Key('timeline_sort_toggle_button')));
      expect(sortToggled, isTrue);
    });

    testWidgets('expands 三旬 with >=44x44 tap targets and renders cleanly on 320px at 2.0x text scale', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      TimelineXun? tappedXun;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: MaterialApp(
            theme: InkDiaryTheme.light,
            home: Scaffold(
              body: DateIndexTray(
                filters: const TimelineFilterState(
                  year: 2026,
                  month: 11,
                  xun: TimelineXun.zhong,
                  sortOrder: TimelineSortOrder.oldestFirst,
                ),
                facetSummary: const TimelineDateFacetSummary(
                  years: [2026],
                  activeMonths: {11},
                  totalActiveEntries: 2,
                ),
                xunExpandFactor: 1.0,
                onSelectYear: (_) {},
                onSelectMonth: (_) {},
                onSelectXun: (xun) => tappedXun = xun,
                onToggleSort: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(ChronicleDeskPalette.light.deskSurroundTop, const Color(0xFFDFD3C0));
      expect(ChronicleDeskPalette.light.deskSurroundBottom, const Color(0xFFDFD3C0));

      expect(find.text('最早'), findsOneWidget);
      expect(find.text('↑'), findsOneWidget);
      expect(find.text('上旬'), findsOneWidget);
      expect(find.text('1–10日'), findsOneWidget);
      expect(find.text('中旬'), findsOneWidget);
      expect(find.text('11–20日'), findsOneWidget);
      expect(find.text('下旬'), findsOneWidget);
      expect(find.text('21日–月底'), findsOneWidget);

      for (final xunName in const ['shang', 'zhong', 'xia']) {
        final size = tester.getSize(find.byKey(Key('timeline_xun_chip_$xunName')));
        expect(size.width, greaterThanOrEqualTo(44.0), reason: xunName);
        expect(size.height, greaterThanOrEqualTo(44.0), reason: xunName);
      }

      await tester.tap(find.byKey(const Key('timeline_xun_chip_xia')));
      expect(tappedXun, equals(TimelineXun.xia));
    });

    testWidgets('preserves lunar range formatting when useLunarDates is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: DateIndexTray(
              filters: const TimelineFilterState(
                year: 2026,
                month: 11,
                xun: TimelineXun.zhong,
              ),
              facetSummary: const TimelineDateFacetSummary(
                years: [2026],
                activeMonths: {11},
                totalActiveEntries: 2,
              ),
              xunExpandFactor: 1.0,
              useLunarDates: true,
              onSelectYear: (_) {},
              onSelectMonth: (_) {},
              onSelectXun: (_) {},
              onToggleSort: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('初一–初十'), findsOneWidget);
      expect(find.text('十一–二十'), findsOneWidget);
      expect(find.text('廿一–晦日'), findsOneWidget);
    });

    testWidgets('active year chip uses wash fill without opaque boxShadow obscuring text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.dark,
          home: Scaffold(
            body: DateIndexTray(
              filters: const TimelineFilterState(),
              facetSummary: const TimelineDateFacetSummary(
                years: [2026],
                activeMonths: {},
                totalActiveEntries: 1,
              ),
              xunExpandFactor: 0.0,
              onSelectYear: (_) {},
              onSelectMonth: (_) {},
              onSelectXun: (_) {},
              onToggleSort: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final activeContainer = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const Key('timeline_year_chip_all')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration! as BoxDecoration).border != null,
          ),
        ),
      );
      final decoration = activeContainer.decoration! as BoxDecoration;
      expect(
        decoration.color,
        ChronicleDeskPalette.dark.cinnabar.withValues(alpha: 0.20),
      );
      expect(decoration.boxShadow ?? const [], isEmpty);
    });
  });
}
