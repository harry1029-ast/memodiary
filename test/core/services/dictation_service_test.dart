import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/services/dictation_service.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../helpers/fake_speech_to_text.dart';

void main() {
  late FakeSpeechToText fakeSpeech;
  late DictationService service;

  setUp(() {
    fakeSpeech = FakeSpeechToText();
    service = DictationService(speech: fakeSpeech);
  });

  tearDown(() {
    service.dispose();
  });

  group('DictationService Tests', () {
    test('initializes and starts continuous dictation', () async {
      String? emittedWords;
      bool? emittedFinal;

      await service.startDictation(
        onResult: (words, isFinal) {
          emittedWords = words;
          emittedFinal = isFinal;
        },
      );

      expect(service.isContinuousActive, isTrue);
      expect(fakeSpeech.isListening, isTrue);

      // Simulate recognized words callback from native engine
      final dummyWords = [
        const SpeechRecognitionWords('Today was a good day', null, 0.95),
      ];
      final fakeResult = SpeechRecognitionResult(dummyWords, 0);
      fakeSpeech.resultListener?.call(fakeResult);

      expect(emittedWords, 'Today was a good day');
      expect(emittedFinal, isFalse);
    });

    test('stopping dictation terminates continuous mode', () async {
      await service.startDictation(onResult: (_, __) {});
      expect(service.isContinuousActive, isTrue);

      await service.stopDictation();
      expect(service.isContinuousActive, isFalse);
      expect(fakeSpeech.isListening, isFalse);
    });

    test('cancelling dictation terminates continuous mode', () async {
      await service.startDictation(onResult: (_, __) {});
      expect(service.isContinuousActive, isTrue);

      await service.cancelDictation();
      expect(service.isContinuousActive, isFalse);
      expect(fakeSpeech.isListening, isFalse);
    });
  });
}

