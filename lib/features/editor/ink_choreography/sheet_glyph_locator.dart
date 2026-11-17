import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' show EditorState;

import 'ink_choreography_timeline.dart';
import 'ink_slot.dart';

/// Finds where a character of a Stationery Sheet stands, from the editor's
/// own caret geometry (SPEC-020 §4), in the coordinates of the ink layer.
///
/// Call it once the editor has laid the text out (while painting, or after
/// the frame): it reads render objects.
class SheetGlyphLocator {
  /// The sheet's live editor, or null while it is not mounted.
  final EditorState? editorState;

  /// The overlay's mask-and-ink layer, which fills the sheet card.
  final RenderObject? inkLayer;

  /// The top of the first ruled body row, in the ink layer: the Paper
  /// Heart's top, below the Journal Letterhead on the opening sheet.
  final double bodyTop;

  /// The height of one ruled row.
  final double lineStride;

  /// The body text style, for measuring a glyph that ends its line.
  final TextStyle textStyle;

  const SheetGlyphLocator({
    required this.editorState,
    required this.inkLayer,
    required this.bodyTop,
    required this.lineStride,
    required this.textStyle,
  });

  /// The glyph of [character] at document [offset], or null while the
  /// editor or the ink layer is not laid out.
  InkGlyphGeometry? locate(int offset, String character) {
    final editorState = this.editorState;
    final inkLayer = this.inkLayer;
    if (editorState == null || !editorState.mounted) return null;
    if (inkLayer is! RenderBox || !inkLayer.attached || !inkLayer.hasSize) return null;
    final editor = editorState.renderEditor;
    if (!editor.attached || !editor.hasSize) return null;
    if (offset < 0 || offset + character.length >= editor.document.length) return null;

    final caret = editor.getLocalRectForCaret(TextPosition(offset: offset));
    final next = editor.getLocalRectForCaret(TextPosition(offset: offset + character.length));
    final isOnOneLine = (next.top - caret.top).abs() <= 0.5 && next.left > caret.left;
    final advance = isOnOneLine ? next.left - caret.left : _measure(character);
    if (advance <= 0) return null;

    final origin = inkLayer.globalToLocal(editor.localToGlobal(caret.topLeft));
    final lineCenter = origin.dy + caret.height / 2;
    final row = math.max(0, ((lineCenter - bodyTop) / lineStride).floor());
    final rowTop = bodyTop + row * lineStride;
    // A heading's line is taller than one ruled row: cover all of it.
    final isTallLine = caret.height > lineStride + 0.5;
    final top = isTallLine ? math.min(rowTop, origin.dy) : rowTop;
    final bottom = isTallLine ? math.max(rowTop + lineStride, origin.dy + caret.height) : rowTop + lineStride;

    // Letter spacing (grid papers) trails the glyph: it is masked, not inked.
    final letterSpacing = textStyle.letterSpacing ?? 0.0;
    final inkAdvance = advance - letterSpacing > advance * 0.3 ? advance - letterSpacing : advance;
    return InkGlyphGeometry(
      maskRect: Rect.fromLTRB(origin.dx, top, origin.dx + advance, bottom),
      glyphBox: InkChoreographyTimeline.glyphBox(
        left: origin.dx,
        advance: inkAdvance,
        lineCenterY: lineCenter,
        emSize: textStyle.fontSize ?? lineStride,
      ),
    );
  }

  double _measure(String character) {
    final painter = TextPainter(
      text: TextSpan(text: character, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}
