import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/main.dart';

void main() {
  testWidgets('MemoDiaryApp smoke test renders TimelineScreen', (WidgetTester tester) async {
    final db = AppDatabase.memory();
    final media = MediaSandboxService();

    await tester.pumpWidget(MemoDiaryApp(database: db, mediaService: media));
    await tester.pumpAndSettle();

    expect(find.text('MemoDiary'), findsOneWidget);
    expect(find.text('No Diary Entries Yet'), findsOneWidget);

    await db.close();
  });
}
