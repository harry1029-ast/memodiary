import 'dart:math';
import '../models/thought_spark.dart';

/// Provides zero-cost curated daily reflective writing prompts ("Thought Sparks")
class ThoughtSparkService {
  static const List<ThoughtSpark> sparks = [
    ThoughtSpark(
      id: 'spark_1',
      promptZh: '今天最让你心动或者难忘的一瞬间是什么？',
      promptEn: 'What was the most memorable or heartwarming moment of your day?',
      category: 'reflection',
    ),
    ThoughtSpark(
      id: 'spark_2',
      promptZh: '记录下一件让你觉得微小却真切的幸福。',
      promptEn: 'Record one tiny yet genuine moment of joy today.',
      category: 'gratitude',
    ),
    ThoughtSpark(
      id: 'spark_3',
      promptZh: '今天你遇到了什么挑战？你是如何调整心态去面对它的？',
      promptEn: 'What challenge did you face today, and how did you navigate it?',
      category: 'growth',
    ),
    ThoughtSpark(
      id: 'spark_4',
      promptZh: '闭上眼睛，今天空气里的气味、耳边的声音带给你什么感受？',
      promptEn: 'Close your eyes: what scents and sounds defined your environment today?',
      category: 'sensory',
    ),
    ThoughtSpark(
      id: 'spark_5',
      promptZh: '如果给今天的自己说一句话，你想说什么？',
      promptEn: 'If you could whisper one supportive sentence to yourself today, what would it be?',
      category: 'self-compassion',
    ),
    ThoughtSpark(
      id: 'spark_6',
      promptZh: '今天哪顿饭或哪杯饮品让你感到由衷的治愈？',
      promptEn: 'Which meal or beverage brought you genuine comfort today?',
      category: 'daily',
    ),
  ];

  int _currentIndex = 0;

  ThoughtSpark getRandomSpark() {
    final rand = Random();
    return sparks[rand.nextInt(sparks.length)];
  }

  ThoughtSpark nextSpark() {
    _currentIndex = (_currentIndex + 1) % sparks.length;
    return sparks[_currentIndex];
  }
}

