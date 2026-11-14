import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/documents/entry_content_decoder.dart';
import 'package:memodiary/core/documents/entry_vertical_packer.dart';
import 'package:memodiary/core/documents/media_embed_data.dart';
import 'package:memodiary/core/documents/vertical_typography_mapper.dart';

void main() {
  group('EntryVerticalPacker', () {
    test('emits unsplit title column and skips blank/whitespace-only paragraphs', () {
      final columns = EntryVerticalPacker.pack(
        entryTitle: '  春江花月夜长题  ',
        maxTokensPerColumn: 3,
        blocks: const [
          EntryTextBlock(runs: []),
          EntryTextBlock(runs: [EntryInlineRun(text: '   \t  ')]),
          EntryTextBlock(runs: [EntryInlineRun(text: '明月')]),
        ],
      );

      expect(columns, hasLength(2));
      final titleCol = columns[0] as VerticalTextColumn;
      expect(titleCol.isTitle, isTrue);
      expect(titleCol.isHeader, isFalse);
      expect(titleCol.isQuote, isFalse);
      expect(titleCol.tokens, hasLength(7)); // Unsplit even though maxTokensPerColumn == 3

      final bodyCol = columns[1] as VerticalTextColumn;
      expect(bodyCol.isTitle, isFalse);
      expect(
        bodyCol.tokens,
        equals(const [VerticalGlyphToken('明'), VerticalGlyphToken('月')]),
      );
    });

    test('flattens mixed inline runs in one paragraph without mid-sentence column breaks', () {
      final blocks = EntryContentDecoder.decodeOps(
        ops: const [
          {'insert': '素笺'},
          {'insert': '朱笔', 'attributes': {'bold': true, 'color': '#8E271E'}},
          {'insert': '{夹注:「注」}续写'},
          {'insert': '\n', 'attributes': {'header': 2}},
        ],
      );

      final columns = EntryVerticalPacker.pack(
        blocks: blocks,
        maxTokensPerColumn: 10,
      );

      // 2 ('素','笺') + 2 ('朱','笔') + 2 (pair('﹁','﹂'), pair('注','')) + 2 ('续','写') = 8 tokens -> 1 column!
      expect(columns, hasLength(1));
      final column = columns.single as VerticalTextColumn;
      expect(column.isHeader, isTrue);
      expect(column.isQuote, isFalse);
      expect(column.tokens, equals(const [
        VerticalGlyphToken('素'),
        VerticalGlyphToken('笺'),
        VerticalGlyphToken('朱'),
        VerticalGlyphToken('笔'),
        VerticalInterlinearPairToken(rightChar: '﹁', leftChar: '﹂'),
        VerticalInterlinearPairToken(rightChar: '注', leftChar: ''),
        VerticalGlyphToken('续'),
        VerticalGlyphToken('写'),
      ]));
      expect(column.styledTokens[2].colorHex, equals('#8E271E'));
      expect(column.styledTokens[0].colorHex, isNull);
    });

    test('propagates quote, todo/checked state, explicit newline breaks, and normalized media columns', () {
      final blocks = <EntryContentBlock>[
        const EntryTextBlock(
          kind: EntryBlockKind.blockquote,
          runs: [EntryInlineRun(text: '风急\n天高')],
        ),
        const EntryTextBlock(
          kind: EntryBlockKind.checkedList,
          runs: [EntryInlineRun(text: '墨香')],
        ),
        const EntryTextBlock(
          kind: EntryBlockKind.uncheckedList,
          runs: [EntryInlineRun(text: '待书')],
        ),
        const EntryMediaBlock(
          isVideo: true,
          media: MediaEmbedData(
            path: 'media/clip.mp4',
            caption: '竹影',
            aspect: '4:3',
          ),
        ),
      ];

      final columns = EntryVerticalPacker.pack(
        blocks: blocks,
        maxTokensPerColumn: 2,
      );

      expect(columns, hasLength(5));

      final quoteCol1 = columns[0] as VerticalTextColumn;
      expect(quoteCol1.isQuote, isTrue);
      expect(quoteCol1.tokens, equals(const [VerticalGlyphToken('风'), VerticalGlyphToken('急')]));

      final quoteCol2 = columns[1] as VerticalTextColumn;
      expect(quoteCol2.isQuote, isTrue);
      expect(quoteCol2.tokens, equals(const [VerticalGlyphToken('天'), VerticalGlyphToken('高')]));

      final checkedCol = columns[2] as VerticalTextColumn;
      expect(checkedCol.styledTokens.every((styled) => styled.isTodo && styled.isChecked), isTrue);

      final uncheckedCol = columns[3] as VerticalTextColumn;
      expect(uncheckedCol.styledTokens.every((styled) => styled.isTodo && !styled.isChecked), isTrue);

      final mediaCol = columns[4] as VerticalMediaColumn;
      expect(mediaCol.isVideo, isTrue);
      expect(mediaCol.media.path, equals('media/clip.mp4'));
      expect(mediaCol.media.caption, equals('竹影'));
      expect(mediaCol.media.aspectRatio, equals(MediaAspectRatio.standard43));
    });

    test('slices long paragraphs across columns by maxTokensPerColumn and marks H1/H3 headers', () {
      final blocks = EntryContentDecoder.decodeOps(
        ops: const [
          {'insert': '春江潮水连海平海上明月共潮生'},
          {'insert': '\n', 'attributes': {'header': 1}},
          {'insert': '小结'},
          {'insert': '\n', 'attributes': {'header': 3}},
        ],
      );

      final columns = EntryVerticalPacker.pack(
        blocks: blocks,
        maxTokensPerColumn: 6,
      );

      // 14 chars -> 6 + 6 + 2 = 3 columns for H1, plus 1 column for H3
      expect(columns, hasLength(4));
      for (int index = 0; index < 3; index++) {
        final col = columns[index] as VerticalTextColumn;
        expect(col.isHeader, isTrue);
      }
      expect((columns[0] as VerticalTextColumn).tokens, hasLength(6));
      expect((columns[1] as VerticalTextColumn).tokens, hasLength(6));
      expect((columns[2] as VerticalTextColumn).tokens, hasLength(2));
      expect((columns[3] as VerticalTextColumn).isHeader, isTrue);
      expect((columns[3] as VerticalTextColumn).tokens, hasLength(2));

      expect(
        () => EntryVerticalPacker.pack(blocks: const [], maxTokensPerColumn: 0),
        throwsArgumentError,
      );
    });
  });
}
