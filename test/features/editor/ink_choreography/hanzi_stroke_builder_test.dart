import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/ink_choreography/hanzi_stroke_builder.dart';
import 'package:memodiary/features/editor/ink_choreography/stroke_binary_format.dart';

String _line(String char, List<List<List<int>>> medians) =>
    jsonEncode({'character': char, 'strokes': <String>[], 'medians': medians});

ByteData _bytes(Uint8List list) => ByteData.sublistView(list);

void main() {
  const curatedFixture = <String, List<List<List<int>>>>{
    'A': [
      [
        [50, 15],
        [18, 85],
      ],
    ],
  };

  final fixtureLines = <String>[
    // Traditional entry listed before the lower code point on purpose.
    _line('龍', [
      [
        [512, 900],
        [512, 400],
        [800, 200],
      ],
    ]),
    _line('一', [
      [
        [100, 500],
        [500, 500], // collinear midpoint is simplified away
        [924, 500],
      ],
    ]),
    _line('卜', [
      [
        [2000, 1000], // clamps to x 100, y 0
        [-10, -50], // clamps to x 0, y 93 (y 950 / 1024 * 100)
      ],
      [
        [512, 900],
        [512, 900], // consecutive duplicate dropped
        [512, 400],
      ],
    ]),
  ];

  late HanziStrokeBinary table;

  setUp(() {
    final bytes = buildHanziStrokeTable(
      graphicsLines: fixtureLines,
      curated: curatedFixture,
    );
    table = HanziStrokeBinary.parse(_bytes(bytes));
  });

  test('normalizes 1024 y-up medians into the 0..100 top-left box', () {
    expect(table.lookup('一'.runes.first), [
      [
        [10, 39],
        [90, 39],
      ],
    ]);
  });

  test('keeps bends and clamps out-of-box points', () {
    expect(table.lookup('龍'.runes.first), [
      [
        [50, 0],
        [50, 49],
        [78, 68],
      ],
    ]);
    expect(table.lookup('卜'.runes.first), [
      [
        [100, 0],
        [0, 93],
      ],
      [
        [50, 0],
        [50, 49],
      ],
    ]);
  });

  test('merges curated entries and reports the entry count', () {
    expect(table.count, 4);
    expect(table.lookup(0x41), curatedFixture['A']);
    expect(table.lookup(0x42), isNull);
  });

  test('is deterministic regardless of input order', () {
    final first = buildHanziStrokeTable(
      graphicsLines: fixtureLines,
      curated: curatedFixture,
    );
    final second = buildHanziStrokeTable(
      graphicsLines: fixtureLines.reversed.toList(),
      curated: curatedFixture,
    );
    expect(second, first);
  });

  test('caps simplified strokes at 32 points', () {
    final zigzag = [
      for (var step = 0; step < 200; step++) [step * 5, step.isEven ? 100 : 800],
    ];
    final bytes = buildHanziStrokeTable(
      graphicsLines: [
        _line('Ｚ', [zigzag]),
      ],
      curated: const {},
    );
    final stroke =
        HanziStrokeBinary.parse(_bytes(bytes)).lookup(0xFF3A)!.single;
    expect(stroke.length, lessThanOrEqualTo(32));
    expect(stroke.length, greaterThan(2));
  });

  test('rejects bad magic, bad version and an unsorted index', () {
    final good = buildHanziStrokeTable(
      graphicsLines: fixtureLines,
      curated: curatedFixture,
    );

    final badMagic = Uint8List.fromList(good)..[0] = 0x58;
    expect(
      () => HanziStrokeBinary.parse(_bytes(badMagic)),
      throwsFormatException,
    );

    final badVersion = Uint8List.fromList(good)..[4] = 9;
    expect(
      () => HanziStrokeBinary.parse(_bytes(badVersion)),
      throwsFormatException,
    );

    // Swap the first two index code points (offset 8 and 16).
    final unsorted = Uint8List.fromList(good);
    final view = ByteData.sublistView(unsorted);
    final firstCodePoint = view.getUint32(8, Endian.little);
    view.setUint32(8, view.getUint32(16, Endian.little), Endian.little);
    view.setUint32(16, firstCodePoint, Endian.little);
    expect(
      () => HanziStrokeBinary.parse(_bytes(unsorted)),
      throwsFormatException,
    );

    expect(
      () => HanziStrokeBinary.parse(_bytes(Uint8List(3))),
      throwsFormatException,
    );
  });
}
