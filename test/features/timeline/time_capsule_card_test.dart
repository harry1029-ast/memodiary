import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/cinnabar_seal_badge.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';
import 'package:memodiary/features/timeline/widgets/time_capsule_card.dart';

TimelineEntryItem _sealedCapsule({String? title}) {
  final now = DateTime.now();
  return TimelineEntryItem(
    entry: Entry(
      id: 'capsule',
      notebookId: 'notebook_default',
      templateId: 'template_minimalist_white',
      title: title,
      contentDelta: '[]',
      plainText: 'sealed',
      entryDate: now,
      isWeeklyReview: false,
      unlockAt: now.add(const Duration(days: 361)),
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      isLocked: false,
      legacyMountsPending: false,
    ),
  );
}

/// Pumps the card inside the Timeline's date-spine gutter (68 left, 14 right)
/// on a phone [width] dp wide, at system text scale [textScale].
Future<void> pumpTimeCapsuleCard(
  WidgetTester tester, {
  required double width,
  double textScale = 1.0,
  ThemeData? theme,
  String? title,
}) async {
  tester.view.physicalSize = Size(width, 780);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? InkDiaryTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(left: 68, right: 14),
          child: TimeCapsuleCard(
            item: _sealedCapsule(title: title),
            customMargin: EdgeInsets.zero,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('TimeCapsuleCard layout', () {
    testWidgets('title row fits the 360dp reference phone', (tester) async {
      await pumpTimeCapsuleCard(tester, width: 360);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('TIME CAPSULE'), findsOneWidget);
      expect(find.byType(CinnabarSealBadge), findsOneWidget);
    });

    testWidgets('title row fits a 320dp phone in the dark theme', (tester) async {
      await pumpTimeCapsuleCard(tester, width: 320, theme: InkDiaryTheme.dark);

      expect(tester.takeException(), isNull);
    });

    testWidgets('title row fits at the largest system text scale', (tester) async {
      await pumpTimeCapsuleCard(tester, width: 360, textScale: 2.0, title: 'Letter to my 2030 Self');

      expect(tester.takeException(), isNull);
      expect(find.text('Letter to my 2030 Self'), findsOneWidget);
    });

    testWidgets('seal badge stays inside the card when the title row is squeezed', (tester) async {
      await pumpTimeCapsuleCard(tester, width: 320, textScale: 2.0);

      final card = tester.getRect(find.byType(TimeCapsuleCard));
      final badge = tester.getRect(find.byType(CinnabarSealBadge));
      expect(badge.right, lessThanOrEqualTo(card.right));
    });
  });
}
