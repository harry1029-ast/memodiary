import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/documents/delta_ops_decoder.dart';
import 'package:memodiary/core/documents/media_embed_data.dart';

void main() {
  group('decodeDeltaOps', () {
    test('decodes bare op-list JSON and {"ops": [...]} map envelope', () {
      final bare = decodeDeltaOps(jsonEncode([
        {'insert': '春山夜雨\n'},
      ]));
      expect(bare, hasLength(1));
      expect((bare!.first as Map)['insert'], equals('春山夜雨\n'));

      final enveloped = decodeDeltaOps(jsonEncode({
        'ops': [
          {'insert': '秋水共长天一色\n'},
        ],
      }));
      expect(enveloped, hasLength(1));
      expect((enveloped!.first as Map)['insert'], equals('秋水共长天一色\n'));
    });

    test('returns null for empty, whitespace, empty-ops, or malformed JSON', () {
      expect(decodeDeltaOps(''), isNull);
      expect(decodeDeltaOps('   '), isNull);
      expect(decodeDeltaOps('[]'), isNull);
      expect(decodeDeltaOps('{"ops": []}'), isNull);
      expect(decodeDeltaOps('{"ops": "invalid"}'), isNull);
      expect(decodeDeltaOps('{not valid json'), isNull);
    });
  });

  group('MediaEmbedData', () {
    test('normalizes raw strings, JSON strings, and maps', () {
      expect(
        MediaEmbedData.fromRaw('media/photo.webp'),
        equals(const MediaEmbedData(path: 'media/photo.webp')),
      );

      final fromJson = MediaEmbedData.fromRaw(jsonEncode({
        'path': 'media/xuan.webp',
        'caption': '月下独酌图',
        'aspect': '4:3',
      }));
      expect(fromJson.path, equals('media/xuan.webp'));
      expect(fromJson.caption, equals('月下独酌图'));
      expect(fromJson.aspectRatio, equals(MediaAspectRatio.standard43));
      expect(fromJson.explicitAspectRatio, closeTo(4.0 / 3.0, 0.0001));

      final fromMap = MediaEmbedData.fromRaw({
        'path': 'media/video.mp4',
        'caption': '山岚',
        'aspect': '1:1',
      });
      expect(fromMap.path, equals('media/video.mp4'));
      expect(fromMap.caption, equals('山岚'));
      expect(fromMap.aspectRatio, equals(MediaAspectRatio.square11));
      expect(fromMap.explicitAspectRatio, equals(1.0));
    });

    test('falls back safely on null or malformed JSON brace strings', () {
      expect(MediaEmbedData.fromRaw(null), equals(const MediaEmbedData(path: '')));
      expect(
        MediaEmbedData.fromRaw('{corrupt'),
        equals(const MediaEmbedData(path: '{corrupt')),
      );
      expect(
        MediaEmbedData.fromRaw('{corrupt}'),
        equals(const MediaEmbedData(path: '{corrupt}')),
      );
    });

    test('thumbnailPath derives _thumb.webp only when isVideo is true and path ends with .mp4', () {
      const mp4 = MediaEmbedData(path: 'media/clip.mp4');
      expect(mp4.thumbnailPath(isVideo: true), equals('media/clip_thumb.webp'));
      expect(mp4.thumbnailPath(), equals('media/clip.mp4'));

      const webp = MediaEmbedData(path: 'media/photo.webp');
      expect(webp.thumbnailPath(isVideo: true), equals('media/photo.webp'));
      expect(webp.thumbnailPath(), equals('media/photo.webp'));
    });
  });
}
