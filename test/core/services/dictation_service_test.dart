import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/services/dictation_service.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class FakeSpeechToText extends Fake implements SpeechToText {
  bool isAvailableVal = true;
  bool isListeningVal = false;
  SpeechResultListener? resultListener;
  SpeechStatusListener? _statusListener;

  @override
  bool get isAvailable => isAvailableVal;

  @override
  bool get isListening => isListeningVal;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    _statusListener = onStatus;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #listen) {
      isListeningVal = true;
      resultListener = invocation.namedArguments[#onResult] as SpeechResultListener?;
      return Future.value(true);
    }
    if (invocation.memberName == #stop) {
      isListeningVal = false;
      _statusListener?.call('done');
      return Future.value(true);
    }
    if (invocation.memberName == #cancel) {
      isListeningVal = false;
      _statusListener?.call('notListening');
      return Future.value(true);
    }
    return super.noSuchMethod(invocation);
  }
}

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

