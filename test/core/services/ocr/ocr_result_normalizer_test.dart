import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/services/ocr/ocr_models.dart';
import 'package:memodiary/core/services/ocr/ocr_result_normalizer.dart';
import 'package:memodiary/core/services/ocr/ocr_service.dart';

import '../../../helpers/fake_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('OcrModels (OcrLineBlock & OcrResult)', () {
    test('OcrResult.empty represents the OCR sentinel with empty text and [] JSON', () {
      expect(OcrResult.empty.plainText, isEmpty);
      expect(OcrResult.empty.lines, isEmpty);
      expect(OcrResult.empty.isEmpty, isTrue);
      expect(OcrResult.empty.toBlocksJson(), equals('[]'));
    });

    test('toBlocksJson and parseBlocksJson round-trip normalized line blocks cleanly', () {
      const original = OcrResult(
        plainText: '西湖十景\nLingyin Temple',
        lines: <OcrLineBlock>[
          OcrLineBlock(
            text: '西湖十景',
            box: <double>[0.125, 0.25, 0.5, 0.0875],
          ),
          OcrLineBlock(
            text: 'Lingyin Temple',
            box: <double>[0.125, 0.36, 0.6425, 0.09],
          ),
        ],
      );

      final encoded = original.toBlocksJson();
      final decodedLines = OcrResult.parseBlocksJson(encoded);

      expect(decodedLines, hasLength(2));
      expect(decodedLines[0], equals(original.lines[0]));
      expect(decodedLines[1], equals(original.lines[1]));
      expect(decodedLines[0].left, equals(0.125));
      expect(decodedLines[0].top, equals(0.25));
      expect(decodedLines[0].width, equals(0.5));
      expect(decodedLines[0].height, equals(0.0875));
    });

    test('parseBlocksJson gracefully returns empty list for null, empty, or malformed JSON', () {
      expect(OcrResult.parseBlocksJson(null), isEmpty);
      expect(OcrResult.parseBlocksJson(''), isEmpty);
      expect(OcrResult.parseBlocksJson('   '), isEmpty);
      expect(OcrResult.parseBlocksJson('{not-a-list}'), isEmpty);
      expect(OcrResult.parseBlocksJson('[{"text":"missing box"}]'), isEmpty);
      expect(
        OcrResult.parseBlocksJson('[{"text":"short box","box":[0.1,0.2]}]'),
        isEmpty,
      );
    });
  });

  group('OcrResultNormalizer', () {
    test('normalizes pixel boxes to 4 decimal places and joins plainText with newlines', () {
      final result = OcrResultNormalizer.normalize(
        imageWidth: 300,
        imageHeight: 600,
        rawLines: const <RawOcrLine>[
          RawOcrLine(
            text: '杭州东站',
            left: 100,
            top: 150,
            width: 100,
            height: 40,
          ),
          RawOcrLine(
            text: 'G7312 特快列车',
            left: 50,
            top: 300,
            width: 200,
            height: 50,
          ),
        ],
      );

      expect(result.plainText, equals('杭州东站\nG7312 特快列车'));
      expect(result.lines, hasLength(2));
      expect(result.lines[0].box, equals(<double>[0.3333, 0.25, 0.3333, 0.0667]));
      expect(result.lines[1].box, equals(<double>[0.1667, 0.5, 0.6667, 0.0833]));
    });

    test('clamps partially out-of-bounds pixel boxes into 0.0..1.0', () {
      final result = OcrResultNormalizer.normalize(
        imageWidth: 200,
        imageHeight: 100,
        rawLines: const <RawOcrLine>[
          RawOcrLine(
            text: 'Edge Bleed Sign',
            left: -20,
            top: -10,
            width: 120,
            height: 60,
          ),
          RawOcrLine(
            text: 'Bottom Right Stamp',
            left: 150,
            top: 80,
            width: 90,
            height: 50,
          ),
        ],
      );

      expect(result.lines, hasLength(2));
      // Visible span x: 0..100 -> [0.0, 0.5], y: 0..50 -> [0.0, 0.5]
      expect(result.lines[0].box, equals(<double>[0.0, 0.0, 0.5, 0.5]));
      // Visible span x: 150..200 -> [0.75, 0.25], y: 80..100 -> [0.8, 0.2]
      expect(result.lines[1].box, equals(<double>[0.75, 0.8, 0.25, 0.2]));
    });

    test('drops zero-area, negative, NaN, out-of-frame, and invalid-image boxes', () {
      final validFrameResult = OcrResultNormalizer.normalize(
        imageWidth: 1000,
        imageHeight: 1000,
        rawLines: const <RawOcrLine>[
          RawOcrLine(text: 'Zero Width', left: 10, top: 10, width: 0, height: 20),
          RawOcrLine(text: 'Negative Height', left: 10, top: 10, width: 50, height: -5),
          RawOcrLine(text: 'Outside Right', left: 1050, top: 10, width: 80, height: 20),
          RawOcrLine(text: 'NaN Box', left: double.nan, top: 10, width: 50, height: 20),
          RawOcrLine(text: 'Sub-pixel Sliver', left: 10, top: 10, width: 0.01, height: 20),
          RawOcrLine(text: 'Kept Line', left: 100, top: 200, width: 300, height: 40),
        ],
      );

      expect(validFrameResult.plainText, equals('Kept Line'));
      expect(validFrameResult.lines, hasLength(1));
      expect(validFrameResult.lines.single.box, equals(<double>[0.1, 0.2, 0.3, 0.04]));

      final invalidImageResult = OcrResultNormalizer.normalize(
        imageWidth: 0,
        imageHeight: 800,
        rawLines: const <RawOcrLine>[
          RawOcrLine(text: 'Ignored', left: 10, top: 10, width: 50, height: 20),
        ],
      );
      expect(invalidImageResult, equals(OcrResult.empty));
    });

    test('strips C0/C1 control characters and discards empty sanitized lines', () {
      final result = OcrResultNormalizer.normalize(
        imageWidth: 400,
        imageHeight: 400,
        rawLines: const <RawOcrLine>[
          RawOcrLine(
            text: '\x00\x07星巴克\x1B咖啡厅\x7F\r\n',
            left: 40,
            top: 80,
            width: 200,
            height: 40,
          ),
          RawOcrLine(
            text: '  \x00\x1F\x7F  ',
            left: 40,
            top: 140,
            width: 200,
            height: 40,
          ),
        ],
      );

      expect(result.plainText, equals('星巴克咖啡厅'));
      expect(result.lines, hasLength(1));
      expect(result.lines.single.text, equals('星巴克咖啡厅'));
    });

    test('normalizeChannelPayload decodes native map payloads safely', () {
      final result = OcrResultNormalizer.normalizeChannelPayload(<Object?, Object?>{
        'imageWidth': 1600,
        'imageHeight': 1200,
        'lines': <Object?>[
          <Object?, Object?>{
            'text': '西溪湿地门票',
            'left': 160,
            'top': 120.0,
            'width': 400,
            'height': 60.0,
          },
          'malformed-entry',
        ],
      });

      expect(result.plainText, equals('西溪湿地门票'));
      expect(result.lines, hasLength(1));
      expect(result.lines.single.box, equals(<double>[0.1, 0.1, 0.25, 0.05]));
      expect(OcrResultNormalizer.normalizeChannelPayload(null), equals(OcrResult.empty));
    });
  });

  group('StubOcrService & PlatformOcrService', () {
    const channel = MethodChannel(PlatformOcrService.channelName);

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('StubOcrService returns OcrResult.empty and disposes cleanly', () async {
      const stub = StubOcrService();
      final result = await stub.recognizeText('/sandbox/media/photo.webp');
      expect(result, equals(OcrResult.empty));
      await stub.dispose();
    });

    test('PlatformOcrService falls back to StubOcrService on Linux desktop by default', () async {
      var channelInvoked = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        channelInvoked = true;
        return null;
      });

      final service = PlatformOcrService();
      final result = await service.recognizeText('/sandbox/media/desktop.webp');

      expect(channelInvoked, isFalse);
      expect(result, equals(OcrResult.empty));
      await service.dispose();
    });

    test('PlatformOcrService invokes memodiary/ocr recognize with path and normalizes payload', () async {
      MethodCall? capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        capturedCall = call;
        return <String, Object?>{
          'imageWidth': 1000,
          'imageHeight': 500,
          'lines': <Object?>[
            <String, Object?>{
              'text': '灵隐寺飞来峰',
              'left': 250,
              'top': 100,
              'width': 500,
              'height': 50,
            },
          ],
        };
      });

      final service = PlatformOcrService(isSupportedPlatform: () => true);
      final result = await service.recognizeText('/sandbox/media/ticket_01.webp');

      expect(capturedCall, isNotNull);
      expect(capturedCall!.method, equals('recognize'));
      expect(capturedCall!.arguments, equals(<String, Object?>{'path': '/sandbox/media/ticket_01.webp'}));
      expect(result.plainText, equals('灵隐寺飞来峰'));
      expect(result.lines, hasLength(1));
      expect(result.lines.single.box, equals(<double>[0.25, 0.2, 0.5, 0.1]));
      await service.dispose();
    });

    test('PlatformOcrService falls back cleanly on MissingPluginException and PlatformException', () async {
      // MissingPluginException when no handler is registered
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);

      final service = PlatformOcrService(isSupportedPlatform: () => true);
      final missingResult = await service.recognizeText('/sandbox/media/missing_plugin.webp');
      expect(missingResult, equals(OcrResult.empty));

      // PlatformException when native image decoding fails
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(
          code: 'OCR_DECODE_FAILED',
          message: 'Corrupt image header',
        );
      });

      final failedResult = await service.recognizeText('/sandbox/media/corrupt.webp');
      expect(failedResult, equals(OcrResult.empty));

      await service.dispose();
      final afterDisposeResult = await service.recognizeText('/sandbox/media/after_dispose.webp');
      expect(afterDisposeResult, equals(OcrResult.empty));
    });
  });

  group('FakeOcrService', () {
    test('supports scripted exact and suffix path results, error injection, delay, and call tracking', () async {
      const ticketResult = OcrResult(
        plainText: '二等座 ¥73.0',
        lines: <OcrLineBlock>[
          OcrLineBlock(text: '二等座 ¥73.0', box: <double>[0.1, 0.4, 0.5, 0.08]),
        ],
      );

      final fake = FakeOcrService(
        resultsByPath: <String, OcrResult>{
          'media/ticket.webp': ticketResult,
        },
        delay: const Duration(milliseconds: 5),
      );
      fake.setError('media/corrupt.webp', StateError('Decode failed'));

      final matched = await fake.recognizeText('/tmp/memodiary_sandbox/media/ticket.webp');
      expect(matched, equals(ticketResult));

      final unscripted = await fake.recognizeText('/tmp/memodiary_sandbox/media/scenery.webp');
      expect(unscripted, equals(OcrResult.empty));

      await expectLater(
        () => fake.recognizeText('/tmp/memodiary_sandbox/media/corrupt.webp'),
        throwsA(isA<StateError>()),
      );

      expect(fake.callCount, equals(3));
      expect(
        fake.recognizedPaths,
        equals(<String>[
          '/tmp/memodiary_sandbox/media/ticket.webp',
          '/tmp/memodiary_sandbox/media/scenery.webp',
          '/tmp/memodiary_sandbox/media/corrupt.webp',
        ]),
      );

      var customInvocations = 0;
      final customFake = FakeOcrService(
        onRecognize: (String absolutePath) async {
          customInvocations++;
          return OcrResult(
            plainText: 'custom:$absolutePath',
            lines: const <OcrLineBlock>[],
          );
        },
      );
      final customResult = await customFake.recognizeText('/a.webp');
      expect(customInvocations, equals(1));
      expect(customResult.plainText, equals('custom:/a.webp'));

      await fake.dispose();
      expect(fake.isDisposed, isTrue);
    });
  });
}
