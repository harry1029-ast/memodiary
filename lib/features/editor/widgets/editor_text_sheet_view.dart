import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../templates/services/stationery_layout_calculator.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/stationery_sheet_configs.dart';
import 'editor_quill_styles_builder.dart';
import 'integer_snapped_letterhead.dart';
import 'journal_letterhead.dart';
import 'sandboxed_image_embed_builder.dart';
import 'sandboxed_video_embed_builder.dart';

/// Renders an OpeningSheet (4-row JournalLetterhead + 10-row editor) or ContinuationSheet
/// (running colophon + 14-row editor) constrained and clipped strictly inside the Paper Heart.
class EditorTextSheetView extends StatelessWidget {
  final TextStationerySheet sheet;
  final int sheetIndex;
  final StationeryLayoutMetrics metrics;
  final double activeRowHeight;
  final double horizontalLeft;
  final double horizontalRight;
  final StationerySheetThemeConfig themeConfig;
  final StationeryLetterheadConfig letterheadConfig;
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
    required this.themeConfig,
    required this.letterheadConfig,
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: metrics.innerFrameRect.top,
          left: 0,
          right: 0,
          height: metrics.innerFrameRect.height,
          child: ClipRect(
            key: const Key('editor_paper_heart_viewport_clip'),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IntegerSnappedLetterhead(
                    key: letterheadConfig.letterheadKey,
                    lineStridePx: activeRowHeight,
                    minRows: kJournalLetterheadReservedRows,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: horizontalLeft,
                        right: horizontalRight,
                      ),
                      child: JournalLetterhead(
                        entryDate: letterheadConfig.entryDate,
                        mood: letterheadConfig.mood,
                        weather: letterheadConfig.weather,
                        titleController: letterheadConfig.titleController,
                        onDateChanged: letterheadConfig.onDateChanged,
                        onMoodChanged: letterheadConfig.onMoodChanged,
                        onWeatherChanged: letterheadConfig.onWeatherChanged,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: horizontalLeft,
                      right: horizontalRight,
                    ),
                    child: _buildTextEditor(
                      placeholder: '提笔落墨，且将心事付素笺... Write your heart out today...',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinuationSheet() {
    final rawTitle = letterheadConfig.titleController.text.trim();
    final displayTitle = rawTitle.isNotEmpty ? rawTitle : '无题';
    final colophonText = '《$displayTitle》 · 第 ${sheetIndex + 1} 页';
    final hasMarginRoom = metrics.innerFrameRect.top >= 26.0;
    final colophonTop = math.max(0.0, metrics.innerFrameRect.top - 26.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: colophonTop,
          left: 0,
          right: 0,
          height: 24.0,
          child: Padding(
            padding: EdgeInsets.only(left: horizontalLeft, right: horizontalRight),
            child: Align(
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
                  color: themeConfig.inkColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: metrics.innerFrameRect.top,
          left: 0,
          right: 0,
          height: metrics.innerFrameRect.height,
          child: ClipRect(
            key: const Key('editor_paper_heart_viewport_clip'),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(top: hasMarginRoom ? 0.0 : 8.0),
              child: Padding(
                padding: EdgeInsets.only(
                  left: horizontalLeft,
                  right: horizontalRight,
                ),
                child: _buildTextEditor(
                  placeholder: '续写素笺... Continue writing...',
                ),
              ),
            ),
          ),
        ),
      ],
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
            typography: themeConfig.typography,
            inkColor: themeConfig.inkColor,
            isPaperDark: themeConfig.isPaperDark,
            lineStridePx: activeRowHeight,
            backgroundType: themeConfig.templateStyle.type,
          ),
        ),
      ),
    );
  }
}
