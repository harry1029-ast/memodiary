import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../templates/models/template_style.dart';
import '../../templates/services/stationery_layout_calculator.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/typography_settings.dart';
import 'editor_quill_styles_builder.dart';
import 'integer_snapped_letterhead.dart';
import 'journal_letterhead.dart';
import 'sandboxed_image_embed_builder.dart';
import 'sandboxed_video_embed_builder.dart';

/// Renders an OpeningSheet (JournalLetterhead + 10-row editor) or ContinuationSheet
/// (running colophon + 14-row editor) inside the Paper Heart.
class EditorTextSheetView extends StatelessWidget {
  final TextStationerySheet sheet;
  final int sheetIndex;
  final StationeryLayoutMetrics metrics;
  final double activeRowHeight;
  final double horizontalLeft;
  final double horizontalRight;
  final TemplateStyle templateStyle;
  final TypographySettings typography;
  final Color inkColor;
  final bool isPaperDark;
  final GlobalKey letterheadKey;
  final DateTime entryDate;
  final int? mood;
  final String? weather;
  final TextEditingController titleController;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int?> onMoodChanged;
  final ValueChanged<String?> onWeatherChanged;
  final MediaSandboxService mediaSandboxService;
  final VoidCallback onSaveDraft;
  final void Function(int sheetIndex)? onSpillBack;

  const EditorTextSheetView({
    super.key,
    required this.sheet,
    required this.sheetIndex,
    required this.metrics,
    required this.activeRowHeight,
    required this.horizontalLeft,
    required this.horizontalRight,
    required this.templateStyle,
    required this.typography,
    required this.inkColor,
    required this.isPaperDark,
    required this.letterheadKey,
    required this.entryDate,
    required this.mood,
    required this.weather,
    required this.titleController,
    required this.onDateChanged,
    required this.onMoodChanged,
    required this.onWeatherChanged,
    required this.mediaSandboxService,
    required this.onSaveDraft,
    this.onSpillBack,
  });

  @override
  Widget build(BuildContext context) {
    if (sheet is OpeningSheet) {
      return _buildOpeningSheet();
    }
    return _buildContinuationSheet();
  }

  Widget _buildOpeningSheet() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(top: metrics.heavenMarginPx),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. In-Paper Journal Letterhead wrapped inside IntegerSnappedLetterhead
          IntegerSnappedLetterhead(
            key: letterheadKey,
            lineStridePx: activeRowHeight,
            child: Container(
              padding: EdgeInsets.only(
                left: horizontalLeft,
                right: horizontalRight,
                top: 8.0,
                bottom: 8.0,
              ),
              child: JournalLetterhead(
                entryDate: entryDate,
                mood: mood,
                weather: weather,
                titleController: titleController,
                onDateChanged: onDateChanged,
                onMoodChanged: onMoodChanged,
                onWeatherChanged: onWeatherChanged,
              ),
            ),
          ),

          // 2. 10 ruled lines QuillEditor inside Paper Heart
          Padding(
            padding: EdgeInsets.only(
              left: horizontalLeft,
              right: horizontalRight,
              bottom: 40.0,
            ),
            child: _buildTextEditor(
              placeholder: '提笔落墨，且将心事付素笺... Write your heart out today...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinuationSheet() {
    final rawTitle = titleController.text.trim();
    final displayTitle = rawTitle.isNotEmpty ? rawTitle : '无题';
    final colophonText = '《$displayTitle》 · 第 ${sheetIndex + 1} 页';

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(top: math.max(0.0, metrics.heavenMarginPx - 26.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Running colophon header
          Container(
            height: 24.0,
            padding: EdgeInsets.only(left: horizontalLeft, right: horizontalRight),
            alignment: Alignment.centerLeft,
            child: Text(
              colophonText,
              key: const Key('editor_continuation_colophon_header'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 11.0,
                letterSpacing: 1.2,
                color: inkColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 2.0),

          // 14 ruled lines QuillEditor inside Paper Heart
          Padding(
            padding: EdgeInsets.only(
              left: horizontalLeft,
              right: horizontalRight,
              bottom: 40.0,
            ),
            child: _buildTextEditor(
              placeholder: '续写素笺... Continue writing...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextEditor({required String placeholder}) {
    return Focus(
      onKeyEvent: (focusNode, keyEvent) {
        if (keyEvent is KeyDownEvent &&
            keyEvent.logicalKey == LogicalKeyboardKey.backspace) {
          if (sheet.controller.selection.isCollapsed &&
              sheet.controller.selection.baseOffset == 0) {
            if (sheet.sheetIndex > 0) {
              onSpillBack?.call(sheet.sheetIndex);
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: QuillEditor(
        controller: sheet.controller,
        focusNode: sheet.focusNode,
        scrollController: ScrollController(),
        config: QuillEditorConfig(
          placeholder: placeholder,
          expands: false,
          scrollable: false,
          embedBuilders: [
            SandboxedImageEmbedBuilder(
              mediaSandboxService: mediaSandboxService,
              onImageRemoved: onSaveDraft,
              onEmbedMutated: (mutatedBlock) => onSaveDraft(),
              rowHeight: activeRowHeight,
            ),
            SandboxedVideoEmbedBuilder(
              mediaSandboxService: mediaSandboxService,
              onVideoRemoved: onSaveDraft,
              onEmbedMutated: (mutatedBlock) => onSaveDraft(),
              rowHeight: activeRowHeight,
            ),
          ],
          customStyles: EditorQuillStylesBuilder.build(
            typography: typography,
            inkColor: inkColor,
            isPaperDark: isPaperDark,
            lineStridePx: activeRowHeight,
            backgroundType: templateStyle.type,
          ),
        ),
      ),
    );
  }
}

