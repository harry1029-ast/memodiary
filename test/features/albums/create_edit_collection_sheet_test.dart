import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/albums/widgets/create_edit_collection_sheet.dart';
import 'album_test_harness.dart';

void main() {
  group('CreateEditCollectionSheet Widget Tests', () {
    testWidgets('validates empty title, >100 char title, and >8 char destinationTag', (tester) async {
      CollectionFormResult? capturedResult;

      await pumpAlbumScreen(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                key: const Key('open_sheet_btn'),
                onPressed: () async {
                  capturedResult = await CreateEditCollectionSheet.show(context);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_sheet_btn')));
      await tester.pumpAndSettle();

      // 1. Submit with empty title
      await tester.tap(find.byKey(const Key('album_form_submit')));
      await tester.pump();
      expect(find.text('请输入影集标题'), findsOneWidget);
      expect(capturedResult, isNull);

      // 2. Submit with >100 character title
      final longTitle = List.filled(101, '景').join();
      await tester.enterText(find.byKey(const Key('album_form_title')), longTitle);
      await tester.tap(find.byKey(const Key('album_form_submit')));
      await tester.pump();
      expect(find.text('标题长度不能超过 100 个字符'), findsOneWidget);

      // 3. Submit with >8 character destinationTag
      await tester.enterText(find.byKey(const Key('album_form_title')), '江南春行纪');
      await tester.enterText(
        find.byKey(const Key('album_form_destination')),
        '一二三四五六七八九',
      );
      await tester.tap(find.byKey(const Key('album_form_submit')));
      await tester.pump();
      expect(find.text('地域印章请控制在 8 个字符以内'), findsOneWidget);
      expect(capturedResult, isNull);

      // 4. Valid submission returns CollectionFormResult
      await tester.enterText(find.byKey(const Key('album_form_destination')), '江南');
      await tester.enterText(
        find.byKey(const Key('album_form_route')),
        '杭州 → 乌镇 → 苏州',
      );
      await tester.enterText(
        find.byKey(const Key('album_form_description')),
        '山河沿路，笔底留痕',
      );
      await tester.tap(find.byKey(const Key('album_form_submit')));
      await tester.pumpAndSettle();

      expect(capturedResult, isNotNull);
      expect(capturedResult!.title, '江南春行纪');
      expect(capturedResult!.destinationTag, '江南');
      expect(capturedResult!.routeSummary, '杭州 → 乌镇 → 苏州');
      expect(capturedResult!.description, '山河沿路，笔底留痕');
    });

    testWidgets('pre-fills existing collection fields in edit mode', (tester) async {
      CollectionFormResult? capturedResult;
      final existing = AlbumCollection(
        id: 'col_existing',
        title: '京都枫叶季',
        description: '古刹红叶与苔庭',
        destinationTag: '关西',
        routeSummary: '京都 → 岚山 → 宇治',
        coverImagePath: null,
        startDate: DateTime(2026, 11, 10),
        endDate: DateTime(2026, 11, 16),
        layoutPreset: 'classic_photobook',
        themeId: 'shanshui_ink',
        sortIndex: 0,
        createdAt: DateTime(2026, 11, 10),
        updatedAt: DateTime(2026, 11, 10),
      );

      await pumpAlbumScreen(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                key: const Key('edit_sheet_btn'),
                onPressed: () async {
                  capturedResult = await CreateEditCollectionSheet.show(
                    context,
                    initialCollection: existing,
                  );
                },
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('edit_sheet_btn')));
      await tester.pumpAndSettle();

      expect(find.text('编辑旅行影集'), findsOneWidget);
      expect(find.text('京都枫叶季'), findsOneWidget);
      expect(find.text('关西'), findsOneWidget);
      expect(find.text('京都 → 岚山 → 宇治'), findsOneWidget);
      expect(find.text('2026.11.10 – 2026.11.16'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('album_form_title')),
        '京都深秋行纪',
      );
      await tester.tap(find.byKey(const Key('album_form_submit')));
      await tester.pumpAndSettle();

      expect(capturedResult, isNotNull);
      expect(capturedResult!.title, '京都深秋行纪');
      expect(capturedResult!.destinationTag, '关西');
      expect(capturedResult!.startDate, DateTime(2026, 11, 10));
      expect(capturedResult!.endDate, DateTime(2026, 11, 16));
    });
  });
}

