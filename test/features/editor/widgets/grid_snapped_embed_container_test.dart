import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/models/media_embed_data.dart';
import 'package:memodiary/features/editor/widgets/grid_snapped_embed_container.dart';

void main() {
  group('MediaEmbedData Serialization Tests', () {
    test('parses legacy plain path string', () {
      final data = MediaEmbedData.fromRaw('media/legacy_photo.webp');
      expect(data.path, equals('media/legacy_photo.webp'));
      expect(data.caption, isEmpty);
      expect(data.aspect, equals('auto'));
      expect(data.toEmbedValue(), equals('media/legacy_photo.webp'));
    });

    test('parses and round-trips structured JSON embed payload', () {
      final original = const MediaEmbedData(
        path: 'media/tagged_photo.webp',
        caption: '秋山行旅',
        aspect: '4:3',
      );
      final jsonStr = original.toEmbedValue();
      expect(jsonStr, contains('media/tagged_photo.webp'));
      expect(jsonStr, contains('秋山行旅'));
      expect(jsonStr, contains('4:3'));

      final parsed = MediaEmbedData.fromRaw(jsonStr);
      expect(parsed.path, equals(original.path));
      expect(parsed.caption, equals(original.caption));
      expect(parsed.aspect, equals('4:3'));
      expect(parsed.explicitAspectRatio, equals(4.0 / 3.0));
    });
  });

  group('GridSnappedEmbedContainer Layout & Interaction Tests', () {
    testWidgets('enforces exact N * rowHeight total outer height across typography changes', (tester) async {
      // Content width = 360, aspect = 16:9 (1.7778), rawHeight = 360 / (16/9) = 202.5.
      // rowHeight = 28.0. N = max(3, ceil((202.5 + 24) / 28)) = ceil(226.5 / 28) = 9 rows.
      // totalHeight = 9 * 28.0 = 252.0.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: GridSnappedEmbedContainer(
                  rowHeight: 28.0,
                  aspect: 'auto',
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(const Key('grid_snapped_media_card'));
      expect(cardFinder, findsOneWidget);
      final cardSize = tester.getSize(cardFinder);
      expect(cardSize.height, equals(252.0));
      expect(cardSize.height % 28.0, equals(0.0));

      // Re-pump with rowHeight = 24.0 (font size / line spacing changed in typography)
      // N = max(3, ceil((202.5 + 24) / 24)) = ceil(226.5 / 24) = 10 rows.
      // totalHeight = 10 * 24.0 = 240.0.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: GridSnappedEmbedContainer(
                  rowHeight: 24.0,
                  aspect: 'auto',
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final recomputedSize = tester.getSize(cardFinder);
      expect(recomputedSize.height, equals(240.0));
      expect(recomputedSize.height % 24.0, equals(0.0));
    });

    testWidgets('tapping card toggles contextual floating action bar and triggers actions', (tester) async {
      String? changedCaption;
      String? changedAspect;
      bool removed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: GridSnappedEmbedContainer(
                  rowHeight: 28.0,
                  aspect: 'auto',
                  caption: '原初题跋',
                  onCaptionChanged: (val) => changedCaption = val,
                  onAspectChanged: (val) => changedAspect = val,
                  onRemove: () => removed = true,
                  child: const ColoredBox(color: Colors.amber),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially action bar is hidden
      expect(find.byKey(const Key('media_card_action_bar')), findsNothing);
      expect(find.text('原初题跋'), findsOneWidget);

      // Tap card to activate action bar
      await tester.tap(find.byKey(const Key('grid_snapped_media_card')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_card_action_bar')), findsOneWidget);

      // 1. Test aspect cycling
      final aspectBtn = find.byKey(const Key('media_card_aspect_button'));
      expect(aspectBtn, findsOneWidget);
      await tester.tap(aspectBtn);
      await tester.pumpAndSettle();
      expect(changedAspect, equals('4:3'));

      // 2. Test caption dialog
      final captionBtn = find.byKey(const Key('media_card_caption_button'));
      expect(captionBtn, findsOneWidget);
      await tester.tap(captionBtn);
      await tester.pumpAndSettle();

      expect(find.text('题跋批注 · Caption'), findsOneWidget);
      final captionInput = find.byKey(const Key('media_card_caption_input'));
      expect(captionInput, findsOneWidget);
      await tester.enterText(captionInput, '新赋题跋 · 晴川暮雪');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('media_card_caption_save_button')));
      await tester.pumpAndSettle();
      expect(changedCaption, equals('新赋题跋 · 晴川暮雪'));

      // 3. Test remove action
      final removeBtn = find.byKey(const Key('media_card_remove_button'));
      expect(removeBtn, findsOneWidget);
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();
      expect(removed, isTrue);
    });

    testWidgets('read-only mode does not toggle action bar on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: GridSnappedEmbedContainer(
                  rowHeight: 28.0,
                  readOnly: true,
                  child: ColoredBox(color: Colors.green),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('grid_snapped_media_card')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_card_action_bar')), findsNothing);
    });
  });
}

