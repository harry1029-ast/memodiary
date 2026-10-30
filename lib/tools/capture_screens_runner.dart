// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../core/database/app_database.dart';
import '../core/services/media_sandbox_service.dart';
import '../core/theme/ink_diary_theme.dart';
import '../features/albums/data/album_repository.dart';
import '../features/albums/screens/album_book_overview_screen.dart';
import '../features/albums/screens/album_collections_screen.dart';
import '../features/analytics/screens/analytics_dashboard_screen.dart';
import '../features/editor/screens/entry_editor_screen.dart';
import '../features/recycle_bin/screens/recycle_bin_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/templates/screens/custom_template_editor_screen.dart';
import '../features/timeline/screens/entry_detail_screen.dart';
import '../features/timeline/screens/timeline_screen.dart';
import '../features/weekly_review/screens/weekly_debrief_detail_screen.dart';
import '../features/weekly_review/screens/weekly_review_screen.dart';

class ScreenSpec {
  final String slug;
  final String title;
  final bool fullPage;
  final Widget Function(AppDatabase db, MediaSandboxService media, AlbumRepository repo, Entry entry1, Entry debrief, AlbumCollection col) builder;

  const ScreenSpec({
    required this.slug,
    required this.title,
    this.fullPage = true,
    required this.builder,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase.memory();
  final mediaService = MediaSandboxService();
  final repo = AlbumRepository(database: db, mediaService: mediaService);

  final now = DateTime(2026, 10, 26, 14, 30);

  // 1. Standard Entry
  final entry1 = await db.into(db.entries).insertReturning(
        EntriesCompanion.insert(
          id: 'entry_sample_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('秋山行记 · 霜叶初红'),
          contentDelta: jsonEncode([
            {
              'insert':
                  '今日携友登秋山，见层林尽染，霜叶初红。\n于古寺山亭小憩，煮雪水烹新茶，读陶公归去来兮辞。\n秋风微凉，心境澄澈而宁寂。\n'
            }
          ]),
          plainText:
              '今日携友登秋山，见层林尽染，霜叶初红。于古寺山亭小憩，煮雪水烹新茶，读陶公归去来兮辞。秋风微凉，心境澄澈而宁寂。',
          entryDate: now,
          mood: const Value(5),
          weather: const Value('sunny'),
        ),
      );

  // 2. Sealed Time Capsule Entry
  await db.into(db.entries).insert(
        EntriesCompanion.insert(
          id: 'entry_sample_2',
          notebookId: 'notebook_default',
          templateId: 'template_retro_kraft',
          title: const Value('时光胶囊 · 寄三年后'),
          contentDelta: jsonEncode([
            {'insert': '封存一段心事，待来年春暖花开再启。\n'}
          ]),
          plainText: '封存一段心事，待来年春暖花开再启。',
          entryDate: now.subtract(const Duration(days: 2)),
          mood: const Value(4),
          weather: const Value('cloudy'),
          unlockAt: Value(now.add(const Duration(days: 365))),
        ),
      );

  // 3. Weekly Debrief Entry
  final debrief = await db.into(db.entries).insertReturning(
        EntriesCompanion.insert(
          id: 'debrief_sample_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('第43周 · 周末心绪与复盘'),
          contentDelta: jsonEncode([
            {
              'insert':
                  '本周专注完成了新功能开发，心流状态极佳。\n周末阅读与品茗，感受时光缓流。\n下周待续静心修远。\n'
            }
          ]),
          plainText:
              '本周专注完成了新功能开发，心流状态极佳。周末阅读与品茗，感受时光缓流。下周待续静心修远。',
          entryDate: now,
          mood: const Value(5),
          weather: const Value('sunny'),
          isWeeklyReview: const Value(true),
          weekNumber: const Value(43),
        ),
      );

  // 4. Soft-deleted Entry for Recycle Bin
  await db.into(db.entries).insert(
        EntriesCompanion.insert(
          id: 'deleted_sample_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('未完草稿 · 浮萍小札'),
          contentDelta: jsonEncode([
            {'insert': '随手记录的一些杂乱念头...\n'}
          ]),
          plainText: '随手记录的一些杂乱念头...',
          entryDate: now.subtract(const Duration(days: 5)),
          isDeleted: const Value(true),
        ),
      );

  // 5. Album Collection
  final col = await repo.createCollection(
    id: 'col_sample_1',
    title: '江南春行纪 · 水墨姑苏',
    description: '绿杨烟外晓寒轻，红杏枝头春意闹',
    destinationTag: '苏州',
    routeSummary: '拙政园 → 平江路 → 狮子林',
  );

  runApp(
    CaptureRunnerApp(
      database: db,
      mediaService: mediaService,
      repository: repo,
      entry1: entry1,
      debrief: debrief,
      collection: col,
    ),
  );
}

class CaptureRunnerApp extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final AlbumRepository repository;
  final Entry entry1;
  final Entry debrief;
  final AlbumCollection collection;

  const CaptureRunnerApp({
    super.key,
    required this.database,
    required this.mediaService,
    required this.repository,
    required this.entry1,
    required this.debrief,
    required this.collection,
  });

  @override
  State<CaptureRunnerApp> createState() => _CaptureRunnerAppState();
}

class _CaptureRunnerAppState extends State<CaptureRunnerApp> {
  final GlobalKey _boundaryKey = GlobalKey();
  Widget? _currentWidget;
  double _containerHeight = 892;
  String _currentStatus = 'Preparing capture sequence...';

  late final List<ScreenSpec> _specs;

  @override
  void initState() {
    super.initState();
    _specs = [
      ScreenSpec(
        slug: '01_timeline_feed',
        title: 'Timeline Feed',
        builder: (db, media, repo, e1, deb, col) => TimelineScreen(
          database: db,
          mediaService: media,
        ),
      ),
      ScreenSpec(
        slug: '02_entry_detail',
        title: 'Diary Reader View',
        builder: (db, media, repo, e1, deb, col) => EntryDetailScreen(
          database: db,
          mediaService: media,
          entry: e1,
        ),
      ),
      ScreenSpec(
        slug: '03_entry_editor',
        title: 'Write Diary - Ink Diary',
        builder: (db, media, repo, e1, deb, col) => EntryEditorScreen(
          database: db,
          mediaSandboxService: media,
          entryId: e1.id,
        ),
      ),
      ScreenSpec(
        slug: '04_weekly_review',
        title: 'Weekly Review',
        builder: (db, media, repo, e1, deb, col) => WeeklyReviewScreen(
          database: db,
          mediaService: media,
          initialYear: 2026,
          initialWeekNumber: 43,
        ),
      ),
      ScreenSpec(
        slug: '05_weekly_debrief',
        title: 'Weekly Debrief Detail',
        builder: (db, media, repo, e1, deb, col) => WeeklyDebriefDetailScreen(
          database: db,
          mediaService: media,
          debriefEntry: deb,
          weekEntries: [e1],
          year: 2026,
          weekNumber: 43,
        ),
      ),
      ScreenSpec(
        slug: '06_album_collections',
        title: 'Travel Memory Album Collections',
        builder: (db, media, repo, e1, deb, col) => AlbumCollectionsScreen(
          database: db,
          mediaService: media,
          repository: repo,
        ),
      ),
      ScreenSpec(
        slug: '07_album_book_overview',
        title: 'Photobook Studio Overview',
        builder: (db, media, repo, e1, deb, col) => AlbumBookOverviewScreen(
          collection: col,
          photos: const [],
          repository: repo,
          mediaService: media,
        ),
      ),
      ScreenSpec(
        slug: '08_analytics_dashboard',
        title: 'Writing Analytics & Heatmap',
        builder: (db, media, repo, e1, deb, col) => AnalyticsDashboardScreen(
          database: db,
          referenceDate: DateTime(2026, 10, 26),
        ),
      ),
      ScreenSpec(
        slug: '09_search_screen',
        title: 'Offline Search & Event Filters',
        builder: (db, media, repo, e1, deb, col) => SearchScreen(
          database: db,
          mediaService: media,
          referenceNow: DateTime(2026, 10, 26),
        ),
      ),
      ScreenSpec(
        slug: '10_custom_template_editor',
        title: 'Custom Template Canvas Editor',
        builder: (db, media, repo, e1, deb, col) => CustomTemplateEditorScreen(
          database: db,
        ),
      ),
      ScreenSpec(
        slug: '11_recycle_bin',
        title: 'Recycle Bin',
        builder: (db, media, repo, e1, deb, col) => RecycleBinScreen(
          database: db,
          mediaService: media,
        ),
      ),
      ScreenSpec(
        slug: '12_settings_privacy',
        title: 'Settings & Storage Optimizer',
        builder: (db, media, repo, e1, deb, col) => SettingsScreen(
          database: db,
          mediaService: media,
        ),
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runCaptureLoop();
    });
  }

  Future<void> _runCaptureLoop() async {
    final outputDir = Directory('.stitch/current_build');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    print('\n============================================================');
    print('  STARTING AUTOMATED SCREEN CAPTURE FOR CURRENT APK BUILD  ');
    print('============================================================\n');

    for (int i = 0; i < _specs.length; i++) {
      final spec = _specs[i];
      print('[$i/${_specs.length}] Mounting: ${spec.title} (${spec.slug})...');

      setState(() {
        _containerHeight = 892;
        _currentStatus = 'Rendering ${spec.title}...';
        _currentWidget = spec.builder(
          widget.database,
          widget.mediaService,
          widget.repository,
          widget.entry1,
          widget.debrief,
          widget.collection,
        );
      });

      // Allow 800ms for database streams, animations, and font layout to fully settle
      await Future.delayed(const Duration(milliseconds: 800));

      if (spec.fullPage) {
        final scrollPositions =
            _findAllScrollPositions(_boundaryKey.currentContext);
        if (scrollPositions.isNotEmpty) {
          double maxAdditional = 0;
          for (final pos in scrollPositions) {
            if (pos.maxScrollExtent > maxAdditional) {
              maxAdditional = pos.maxScrollExtent;
            }
          }
          if (maxAdditional > 20) {
            final expandedHeight =
                (892 + maxAdditional).clamp(892.0, 3200.0);
            print(
                '  ↳ Detected scroll content (+$maxAdditional px). Expanding height to ${expandedHeight.toInt()}px...');
            setState(() {
              _containerHeight = expandedHeight;
            });
            await Future.delayed(const Duration(milliseconds: 400));
          }
        }
      }

      try {
        final boundary = _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final file = File('${outputDir.path}/${spec.slug}.png');
            await file.writeAsBytes(byteData.buffer.asUint8List());
            final sizeKb = (file.lengthSync() / 1024).toStringAsFixed(1);
            print('  ✔ CAPTURED: ${file.path} ($sizeKb KB)');
          } else {
            print('  ✖ ERROR: ByteData null for ${spec.slug}');
          }
        } else {
          print('  ✖ ERROR: RenderRepaintBoundary null for ${spec.slug}');
        }
      } catch (e, stack) {
        print('  ✖ EXCEPTION capturing ${spec.slug}: $e\n$stack');
      }
    }

    print('\n============================================================');
    print('  ALL CURRENT SCREENS CAPTURED TO .stitch/current_build/  ');
    print('============================================================\n');

    exit(0);
  }

  List<ScrollPosition> _findAllScrollPositions(BuildContext? root) {
    if (root == null) return [];
    final List<ScrollPosition> positions = [];
    void search(Element element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final state = element.state as ScrollableState;
        try {
          if (state.position.hasContentDimensions) {
            positions.add(state.position);
          }
        } catch (_) {}
      }
      element.visitChildren(search);
    }

    root.visitChildElements(search);
    return positions;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: InkDiaryTheme.light,
      darkTheme: InkDiaryTheme.dark,
      home: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Center(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                width: 412,
                height: _containerHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF9F2),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _currentWidget ??
                    Center(
                      child: Text(
                        _currentStatus,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
