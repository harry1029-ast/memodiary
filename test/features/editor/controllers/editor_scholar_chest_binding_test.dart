import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/controllers/editor_scholar_chest_binding.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/editor/services/editor_pagination_coordinator.dart';
import 'package:memodiary/features/editor/services/editor_settings_service.dart';
import 'package:memodiary/features/editor/widgets/scholar_chest/scholar_chest_drawer.dart';
import 'package:memodiary/features/editor/widgets/scholar_chest/trial_rice_grid_painter.dart';

import '../../../helpers/mock_secure_storage.dart';

void main() {
  late AppDatabase db;
  late AudioSanctumService audio;
  late EditorScholarChestBinding binding;

  const vermilion = Color(0xFFB83B2E);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    audio = AudioSanctumService(enablePlatformAudio: false);
    binding = EditorScholarChestBinding(
      database: db,
      entryId: 'entry-1',
      audioSanctumService: audio,
      settings: EditorSettingsService(storage: MockSecureStorage()),
    );
  });

  tearDown(() async {
    binding.dispose();
    audio.dispose();
    await db.close();
  });

  Color trialGridInk(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is TrialRiceGridPainter),
    );
    return (paint.painter! as TrialRiceGridPainter).inkColor;
  }

  testWidgets('the Trial Rice-Grid writes in the typography text colour, as the sheet does', (tester) async {
    final template = await tester.runAsync(
      () async => (await db.templatesDao.getAllTemplates()).firstWhere((t) => t.id == 'template_minimalist_white'),
    );
    final coordinator = EditorPaginationCoordinator(
      typography: TypographySettings.fromTemplate(template!).copyWith(textColor: vermilion),
      templateStyle: TemplateStyle.fromTemplate(template),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => binding.open(
                context,
                template: template,
                coordinator: coordinator,
                unlockAt: null,
                isCenterAligned: false,
                initialArtifact: ScholarArtifactType.twinBrushes,
                onTemplateChanged: (_) {},
                onTypographyChanged: (_) {},
                onUnlockAtChanged: (_) {},
                onToggleAlignment: () {},
              ),
              child: const Text('Open Chest'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Chest'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(trialGridInk(tester), vermilion);
    await tester.pumpWidget(const SizedBox());
  });
}
