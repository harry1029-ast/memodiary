import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Speech recognizer double: [initialize] succeeds, `listen` starts listening
/// and keeps its result listener for the test to drive, `stop` and `cancel`
/// end listening and report the status.
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
