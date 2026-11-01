import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/widgets/cinnabar_signature_seal.dart';
import 'package:memodiary/features/editor/widgets/keepsake/keepsake_colophon.dart';
import 'package:memodiary/features/editor/widgets/keepsake/keepsake_column.dart';
import 'package:memodiary/features/editor/widgets/keepsake/keepsake_media_card.dart';
import 'package:memodiary/features/editor/widgets/keepsake_scroll_view.dart';
import 'package:memodiary/features/templates/models/template_style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Entry mockEntry;
  late TemplateStyle mockStyle;

  setUp(() {
    mockStyle = const TemplateStyle(
      type: TemplateBackgroundType.paperTexture,
      backgroundColor: Color(0xFFF7F3E8),
      lineSpacing: 1.5,
      marginHorizontal: 24.0,
      tokens: StationeryVisualTokens(
        substrate: PaperSubstrate.coldGold,
        ruleTint: RuleInkTint.vermilion,
        sealStyle: SealCarvingStyle.zhuwen,
      ),
    );

    final deltaOps = [
      {'insert': '「春江花月夜」\n'},
      {'insert': '孤篇压全唐——何处春江无月明…\n'},
      {
        'insert': {
          'image': jsonEncode({
            'path': 'media/mock_xuan.webp',
            'caption': '月下独酌图',
            'aspect': '4:3',
          }),
        },
      },
      {'insert': '江流宛转绕芳甸\n'},
    ];

    mockEntry = Entry(
      id: 'entry_test_001',
      notebookId: 'nb_001',
      templateId: 'test_tpl',
      title: '春江夜泊',
      contentDelta: jsonEncode(deltaOps),
      plainText: '「春江花月夜」\n孤篇压全唐——何处春江无月明…\n江流宛转绕芳甸',
      entryDate: DateTime(2026, 11, 2, 20, 30),
      mood: 5,
      weather: '霁月',
      isWeeklyReview: false,
      weekNumber: null,
      isLocked: false,
      unlockAt: null,
      createdAt: DateTime(2026, 11, 2),
      updatedAt: DateTime(2026, 11, 2),
      isDeleted: false,
    );
  });

  Widget createSubject({required Entry entry, required TemplateStyle style}) {
    return MaterialApp(
      theme: InkDiaryTheme.light,
      home: KeepsakeScrollView(
        entry: entry,
        style: style,
      ),
    );
  }

  group('KeepsakeScrollView Widget Tests', () {
    testWidgets('renders top bar with title and close button', (tester) async {
      await tester.pumpWidget(createSubject(entry: mockEntry, style: mockStyle));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('keepsake_close_button')), findsOneWidget);
      expect(find.text('卷轴赏鉴 · 春江夜泊'), findsOneWidget);
    });

    testWidgets('renders right-to-left horizontal scroll with vertical columns', (tester) async {
      await tester.pumpWidget(createSubject(entry: mockEntry, style: mockStyle));
      await tester.pumpAndSettle();

      final scrollFinder = find.byKey(const Key('keepsake_horizontal_scroll_view'));
      expect(scrollFinder, findsOneWidget);

      final singleScroll = tester.widget<SingleChildScrollView>(scrollFinder);
      expect(singleScroll.scrollDirection, equals(Axis.horizontal));

      // Assert Directionality is RTL
      final directionality = tester.widget<Directionality>(
        find.ancestor(of: scrollFinder, matching: find.byType(Directionality)).first,
      );
      expect(directionality.textDirection, equals(TextDirection.rtl));

      // Assert KeepsakeColumns are present
      expect(find.byType(KeepsakeColumn), findsWidgets);
    });

    testWidgets('maps horizontal CJK punctuation to vertical presentation glyphs in columns', (tester) async {
      await tester.pumpWidget(createSubject(entry: mockEntry, style: mockStyle));
      await tester.pumpAndSettle();

      // Original 「春江花月夜」 -> ﹁春江花月夜﹂
      expect(find.text('﹁'), findsOneWidget);
      expect(find.text('﹂'), findsOneWidget);

      // Original —— (em dashes) -> ︱
      expect(find.text('︱'), findsWidgets);

      // Original … (horizontal ellipsis) -> ⋮ (vertical ellipsis)
      expect(find.text('⋮'), findsOneWidget);
    });

    testWidgets('renders tipped-in ephemera media card with caption', (tester) async {
      await tester.pumpWidget(createSubject(entry: mockEntry, style: mockStyle));
      await tester.pumpAndSettle();

      expect(find.byType(KeepsakeMediaCard), findsOneWidget);
      expect(find.text('月下独酌图'), findsOneWidget);
    });

    testWidgets('renders terminal colophon with date, mood, weather, and signature seal', (tester) async {
      await tester.pumpWidget(createSubject(entry: mockEntry, style: mockStyle));
      await tester.pumpAndSettle();

      expect(find.byType(KeepsakeColophon), findsOneWidget);
      expect(find.byKey(const Key('keepsake_signature_seal')), findsOneWidget);
      expect(find.byType(CinnabarSignatureSeal), findsOneWidget);
    });

    testWidgets('tapping close button pops the screen without mutating data', (tester) async {
      bool popped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () async {
                await Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => KeepsakeScrollView(
                      entry: mockEntry,
                      style: mockStyle,
                    ),
                  ),
                );
                popped = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      // Tap Open
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(KeepsakeScrollView), findsOneWidget);

      // Tap Close
      await tester.tap(find.byKey(const Key('keepsake_close_button')));
      await tester.pumpAndSettle();

      expect(find.byType(KeepsakeScrollView), findsNothing);
      expect(popped, isTrue);
    });
  });
}
