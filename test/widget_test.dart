import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/intro/screens/book_intro_screen.dart';
import 'package:memodiary/main.dart';

void main() {
  testWidgets('MemoDiaryApp smoke test renders TimelineScreen when showIntroOnLaunch is false', (WidgetTester tester) async {
    final db = AppDatabase.memory();
    final media = MediaSandboxService();

    await tester.pumpWidget(MemoDiaryApp(
      database: db,
      mediaService: media,
      showIntroOnLaunch: false,
    ));
    await tester.pumpAndSettle();

    expect(find.text('MemoDiary'), findsOneWidget);
    expect(find.text('No Diary Entries Yet'), findsOneWidget);

    await db.close();
  });

  testWidgets('MemoDiaryApp smoke test renders BookIntroScreen when showIntroOnLaunch is true', (WidgetTester tester) async {
    final db = AppDatabase.memory();
    final media = MediaSandboxService();

    await tester.pumpWidget(MemoDiaryApp(
      database: db,
      mediaService: media,
      showIntroOnLaunch: true,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(BookIntroScreen), findsOneWidget);

    await db.close();
  });
}
