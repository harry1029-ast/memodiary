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
import 'mount_marker_embed_builder.dart';

/// Renders an OpeningSheet (4-row JournalLetterhead above its body rows) or a
/// ContinuationSheet (running colophon above its rows) clipped strictly inside
/// the Paper Heart.
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
        _buildPaperHeart(
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
                    rowHeight: activeRowHeight,
                    data: letterheadConfig.data,
                    titleController: letterheadConfig.titleController,
                    onDateChanged: letterheadConfig.onDateChanged,
                    onMoodChanged: letterheadConfig.onMoodChanged,
                    onWeatherChanged: letterheadConfig.onWeatherChanged,
                  ),
                ),
              ),
              _buildTappableBodyArea(
                minHeight: math.max(
                  0.0,
                  metrics.innerFrameRect.height -
                      kJournalLetterheadReservedRows * activeRowHeight,
                ),
                child: _buildTextEditor(
                  placeholder: '提笔落墨，且将心事付素笺... Write your heart out today...',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinuationSheet() {
    final rawTitle = letterheadConfig.titleController.text.trim();
    final displayTitle = rawTitle.isNotEmpty ? rawTitle : '无题';
    final colophonText = '《$displayTitle》 · 第 ${sheetIndex + 1} 页';
    // The colophon stays in the Heaven margin, so the text rows start on the
    // first ruled row and every row the Paper Heart shows is a row it holds.
    final colophonTop = math.max(0.0, metrics.innerFrameRect.top - 26.0);
    final colophonHeight = math.min(24.0, metrics.innerFrameRect.top - colophonTop);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: colophonTop,
          left: 0,
          right: 0,
          height: colophonHeight,
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
        _buildPaperHeart(
          child: _buildTappableBodyArea(
            minHeight: metrics.innerFrameRect.height,
            child: _buildTextEditor(
              placeholder: '续写素笺... Continue writing...',
            ),
          ),
        ),
      ],
    );
  }

  void _focusAtEndOfSheet() {
    final endOffset = math.max(0, sheet.document.length - 1);
    sheet.focusNode.requestFocus();
    sheet.controller.updateSelection(
      TextSelection.collapsed(offset: endOffset),
      ChangeSource.local,
    );
  }

  Widget _buildTappableBodyArea({
    required double minHeight,
    required Widget child,
  }) {
    return TextFieldTapRegion(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focusAtEndOfSheet,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: double.infinity,
            minHeight: minHeight,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: horizontalLeft,
              right: horizontalRight,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// The Paper Heart, clipping the sheet's rows. A sheet holds exactly the
  /// rows ruled here ([SheetRowCapacity]), and its content never scrolls: even
  /// while Auto-Spill waits for IME composition to finish, a drag cannot
  /// move the letterhead or the text off the ruling.
  Widget _buildPaperHeart({required Widget child}) {
    return Positioned(
      top: metrics.innerFrameRect.top,
      left: 0,
      right: 0,
      height: metrics.innerFrameRect.height,
      child: ClipRect(
        key: const Key('editor_paper_heart_viewport_clip'),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTextEditor({required String placeholder}) {
    return Focus(
      onKeyEvent: (focusNode, keyEvent) {
        if (keyEvent is KeyDownEvent &&
            keyEvent.logicalKey == LogicalKeyboardKey.backspace) {
          if (sheet.handleLeadingBackspace()) {
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: QuillEditor(
        controller: sheet.controller,
        focusNode: sheet.focusNode,
        scrollController: ScrollController(),
        config: QuillEditorConfig(
          editorKey: sheet.editorKey,
          placeholder: placeholder,
          expands: false,
          scrollable: false,
          embedBuilders: [
            const MountMarkerEmbedBuilder(),
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
