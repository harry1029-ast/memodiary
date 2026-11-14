import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/services/stationery_delta_synthesizer.dart';

void main() {
  group('StationeryDeltaSynthesizer.decode', () {
    test('decodes bare op-list and {"ops": [...]} envelope', () {
      final bare = StationeryDeltaSynthesizer.decode(
        jsonEncode([
          {'insert': '松烟墨痕\n'},
        ]),
      );
      expect(bare.toJson(), equals([{'insert': '松烟墨痕\n'}]));

      final enveloped = StationeryDeltaSynthesizer.decode(
        jsonEncode({
          'ops': [
            {'insert': '朱丝栏影\n'},
          ],
        }),
      );
      expect(enveloped.toJson(), equals([{'insert': '朱丝栏影\n'}]));
    });

    test('falls back to fallbackPlainText when delta is empty-ops, malformed, or blank', () {
      final fromEmptyOps = StationeryDeltaSynthesizer.decode(
        '[]',
        fallbackPlainText: '回退正文',
      );
      expect(fromEmptyOps.toJson(), equals([{'insert': '回退正文\n'}]));

      final fromMalformed = StationeryDeltaSynthesizer.decode(
        '{bad-json',
        fallbackPlainText: '残卷补白\n',
      );
      expect(fromMalformed.toJson(), equals([{'insert': '残卷补白\n'}]));

      final empty = StationeryDeltaSynthesizer.decode('', fallbackPlainText: '  ');
      expect(empty.toJson(), equals([{'insert': '\n'}]));
    });
  });
}
