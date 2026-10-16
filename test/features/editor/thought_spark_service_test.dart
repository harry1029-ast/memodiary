import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/services/thought_spark_service.dart';

void main() {
  group('ThoughtSparkService Tests', () {
    test('contains curated bilingual prompts', () {
      final service = ThoughtSparkService();
      expect(ThoughtSparkService.sparks.isNotEmpty, isTrue);

      final spark = service.getRandomSpark();
      expect(spark.promptZh.isNotEmpty, isTrue);
      expect(spark.promptEn.isNotEmpty, isTrue);
      expect(spark.localizedPrompt, equals(spark.promptZh));
    });

    test('nextSpark cycles predictably through all prompts', () {
      final service = ThoughtSparkService();
      final total = ThoughtSparkService.sparks.length;

      final seen = <String>{};
      for (int i = 0; i < total; i++) {
        final spark = service.nextSpark();
        seen.add(spark.id);
      }

      expect(seen.length, total);
    });
  });
}

