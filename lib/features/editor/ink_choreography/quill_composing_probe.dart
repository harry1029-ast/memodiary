// Pinned to flutter_quill 11.6.0. The live IME composing range exists only
// on `QuillRawEditorState.composingRange`, a member of the raw editor's
// text-input mixin (`src/editor/raw_editor/raw_editor_state_text_input_client_mixin.dart`):
// `QuillController.plainTextEditingValue.composing` is always empty. 11.6.0
// exports `QuillRawEditorState` from its public library, so no
// `package:flutter_quill/src/...` import is needed here; this file is the one
// place that reaches for that member. Recheck it whenever the pin moves.
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' show EditorState, QuillRawEditorState;

/// Watches the IME composing range of one Stationery Sheet's editor.
///
/// The range is updated before Quill applies the text of the same keyboard
/// update, so [onChanged] hears a composition end before its committed text
/// reaches the document.
class QuillComposingProbe {
  /// Hears every change of the watched range, and an empty range when the
  /// probe loses its editor.
  final ValueChanged<TextRange> onChanged;

  QuillComposingProbe({required this.onChanged});

  ValueNotifier<TextRange>? _source;

  /// Watches [editorState] (null for none). Safe to call after every frame:
  /// it only rebinds when the sheet's editor state was replaced.
  void attach(EditorState? editorState) {
    final source = editorState is QuillRawEditorState ? editorState.composingRange : null;
    if (identical(source, _source)) return;
    _source?.removeListener(_report);
    _source = source;
    source?.addListener(_report);
    _report();
  }

  /// Stops watching and reports an empty range.
  void detach() => attach(null);

  void _report() => onChanged(_source?.value ?? TextRange.empty);
}
