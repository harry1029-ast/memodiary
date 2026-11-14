import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/documents/entry_content_decoder.dart';
import 'package:memodiary/core/documents/media_embed_data.dart';

void main() {
  group('EntryContentDecoder', () {
    test('decodes bare op-list, {"ops": [...]} envelope, pre-decoded ops, and plainText fallback', () {
      final bare = EntryContentDecoder.decode(
        contentDeltaJson: jsonEncode([
          {'insert': '　　夜雨剪春韭。\n'},
        ]),
        fallbackPlainText: 'ignored',
      );
      expect(bare, equals([
        const EntryTextBlock(
          kind: EntryBlockKind.paragraph,
          runs: [EntryInlineRun(text: '　　夜雨剪春韭。')],
        ),
      ]));

      final enveloped = EntryContentDecoder.decode(
        contentDeltaJson: jsonEncode({
          'ops': [
            {'insert': '新炊间黄粱。\n'},
          ],
        }),
        fallbackPlainText: 'ignored',
      );
      expect(enveloped, equals([
        const EntryTextBlock(
          kind: EntryBlockKind.paragraph,
          runs: [EntryInlineRun(text: '新炊间黄粱。')],
        ),
      ]));

      final directOps = EntryContentDecoder.decodeOps(
        ops: const [
          {'insert': '主称会面难。\n'},
        ],
        fallbackPlainText: 'ignored',
      );
      expect(directOps, equals([
        const EntryTextBlock(
          kind: EntryBlockKind.paragraph,
          runs: [EntryInlineRun(text: '主称会面难。')],
        ),
      ]));

      final fallback = EntryContentDecoder.decode(
        contentDeltaJson: '{not-json',
        fallbackPlainText: '　　第一行   \n\n第二行{夹注:小注}',
      );
      expect(fallback, equals([
        const EntryTextBlock(
          kind: EntryBlockKind.paragraph,
          runs: [EntryInlineRun(text: '　　第一行')],
        ),
        const EntryTextBlock(
          kind: EntryBlockKind.paragraph,
          runs: [],
        ),
        const EntryTextBlock(
          kind: EntryBlockKind.paragraph,
          runs: [
            EntryInlineRun(text: '第二行'),
            EntryInlineRun(text: '小注', isInterlinearNote: true),
          ],
        ),
      ]));

      expect(
        EntryContentDecoder.decode(contentDeltaJson: '[]', fallbackPlainText: '   '),
        isEmpty,
      );
    });

    test('fallback plainText strips only one document-terminating newline while retaining blank lines', () {
      final deltaBlocks = EntryContentDecoder.decodeOps(
        ops: const [
          {'insert': 'hello\n'},
        ],
      );
      final singleLineFallback = EntryContentDecoder.decode(
        contentDeltaJson: '{corrupt',
        fallbackPlainText: 'hello\n',
      );
      expect(singleLineFallback, equals(deltaBlocks));
      expect(singleLineFallback, hasLength(1));

      final blankMiddleFallback = EntryContentDecoder.decode(
        contentDeltaJson: '',
        fallbackPlainText: 'first\n\nsecond\n',
      );
      expect(blankMiddleFallback, equals(const [
        EntryTextBlock(runs: [EntryInlineRun(text: 'first')]),
        EntryTextBlock(runs: []),
        EntryTextBlock(runs: [EntryInlineRun(text: 'second')]),
      ]));

      final trailingBlankFallback = EntryContentDecoder.decode(
        contentDeltaJson: '',
        fallbackPlainText: 'hello\n\n',
      );
      expect(trailingBlankFallback, equals(const [
        EntryTextBlock(runs: [EntryInlineRun(text: 'hello')]),
        EntryTextBlock(runs: []),
      ]));
    });

    test('binds trailing-newline block attributes and resets ordered list counters', () {
      final blocks = EntryContentDecoder.decodeOps(
        ops: const [
          {'insert': 'Title 1'},
          {'insert': '\n', 'attributes': {'header': 1}},
          {'insert': 'Title 2'},
          {'insert': '\n', 'attributes': {'header': 2}},
          {'insert': 'Title 3'},
          {'insert': '\n', 'attributes': {'header': 3}},
          {'insert': 'Quoted line'},
          {'insert': '\n', 'attributes': {'blockquote': true}},
          {'insert': 'Bullet item'},
          {'insert': '\n', 'attributes': {'list': 'bullet'}},
          {'insert': 'First ordered'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': 'Second ordered'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': 'Done task'},
          {'insert': '\n', 'attributes': {'list': 'checked'}},
          {'insert': 'Open task'},
          {'insert': '\n', 'attributes': {'list': 'unchecked'}},
          {'insert': 'Restarted ordered'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
        ],
      );

      expect(blocks, hasLength(10));
      expect((blocks[0] as EntryTextBlock).kind, equals(EntryBlockKind.header1));
      expect((blocks[1] as EntryTextBlock).kind, equals(EntryBlockKind.header2));
      expect((blocks[2] as EntryTextBlock).kind, equals(EntryBlockKind.header3));
      expect((blocks[3] as EntryTextBlock).kind, equals(EntryBlockKind.blockquote));
      expect((blocks[4] as EntryTextBlock).kind, equals(EntryBlockKind.bulletList));
      expect((blocks[5] as EntryTextBlock).kind, equals(EntryBlockKind.orderedList));
      expect((blocks[5] as EntryTextBlock).orderedIndex, equals(1));
      expect((blocks[6] as EntryTextBlock).kind, equals(EntryBlockKind.orderedList));
      expect((blocks[6] as EntryTextBlock).orderedIndex, equals(2));
      expect((blocks[7] as EntryTextBlock).kind, equals(EntryBlockKind.checkedList));
      expect((blocks[7] as EntryTextBlock).orderedIndex, isNull);
      expect((blocks[8] as EntryTextBlock).kind, equals(EntryBlockKind.uncheckedList));
      expect((blocks[9] as EntryTextBlock).kind, equals(EntryBlockKind.orderedList));
      expect((blocks[9] as EntryTextBlock).orderedIndex, equals(1));
    });

    test('preserves inline attributes and splits {夹注:...} runs cleanly', () {
      final blocks = EntryContentDecoder.decodeOps(
        ops: const [
          {'insert': '素笺'},
          {
            'insert': '朱笔',
            'attributes': {
              'bold': true,
              'italic': true,
              'underline': true,
              'strike': true,
              'color': '#8E271E',
            },
          },
          {'insert': '{夹注:月照花林}续写\n\n'},
        ],
      );

      expect(blocks, hasLength(2));
      final first = blocks[0] as EntryTextBlock;
      expect(first.runs, equals([
        const EntryInlineRun(text: '素笺'),
        const EntryInlineRun(
          text: '朱笔',
          isBold: true,
          isItalic: true,
          isUnderline: true,
          isStrike: true,
          colorHex: '#8E271E',
        ),
        const EntryInlineRun(text: '月照花林', isInterlinearNote: true),
        const EntryInlineRun(text: '续写'),
      ]));
      final blank = blocks[1] as EntryTextBlock;
      expect(blank.runs, isEmpty);
      expect(blank.isBlank, isTrue);
    });

    test('normalizes image/video embeds and ignores mount markers and control embeds', () {
      final blocks = EntryContentDecoder.decodeOps(
        ops: [
          {'insert': '一二'},
          {'insert': {'mount': 'att-1'}},
          {'insert': '三\n'},
          {'insert': '第一条'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': '待续'},
          {
            'insert': {
              'image': jsonEncode({
                'path': 'media/pic.webp',
                'caption': '西湖晴岚',
                'aspect': '4:3',
              }),
            },
          },
          {
            'insert': {
              'video': {
                'path': 'media/clip.mp4',
                'caption': '雨声',
                'aspect': '1:1',
              },
            },
          },
          {'insert': {'divider': true}},
          {'insert': '归零序'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
        ],
      );

      expect(blocks, equals([
        const EntryTextBlock(
          kind: EntryBlockKind.paragraph,
          runs: [
            EntryInlineRun(text: '一二'),
            EntryInlineRun(text: '三'),
          ],
        ),
        const EntryTextBlock(
          kind: EntryBlockKind.orderedList,
          orderedIndex: 1,
          runs: [EntryInlineRun(text: '第一条')],
        ),
        const EntryTextBlock(
          kind: EntryBlockKind.paragraph,
          runs: [EntryInlineRun(text: '待续')],
        ),
        const EntryMediaBlock(
          isVideo: false,
          media: MediaEmbedData(
            path: 'media/pic.webp',
            caption: '西湖晴岚',
            aspect: '4:3',
          ),
        ),
        const EntryMediaBlock(
          isVideo: true,
          media: MediaEmbedData(
            path: 'media/clip.mp4',
            caption: '雨声',
            aspect: '1:1',
          ),
        ),
        const EntryTextBlock(
          kind: EntryBlockKind.orderedList,
          orderedIndex: 1,
          runs: [EntryInlineRun(text: '归零序')],
        ),
      ]));
    });
  });
}
