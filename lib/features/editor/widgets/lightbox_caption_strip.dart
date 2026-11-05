import 'package:flutter/material.dart';

/// Bottom caption strip of the `FullscreenMediaLightbox`: the single place a
/// diarist reads and edits an item's caption.
///
/// Read-only when [onSave] is null. Owns its editing state so the open
/// lightbox route rebuilds itself without relying on the caller's `setState`.
class LightboxCaptionStrip extends StatefulWidget {
  final String caption;
  final ValueChanged<String>? onSave;

  const LightboxCaptionStrip({super.key, required this.caption, this.onSave});

  @override
  State<LightboxCaptionStrip> createState() => _LightboxCaptionStripState();
}

class _LightboxCaptionStripState extends State<LightboxCaptionStrip> {
  static const double _minTapTarget = 44.0;

  TextEditingController? _editController;

  bool get _isEditing => _editController != null;

  @override
  void dispose() {
    _editController?.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _editController = TextEditingController(text: widget.caption));
  }

  void _save() {
    final controller = _editController;
    if (controller == null) return;
    widget.onSave?.call(controller.text.trim());
    setState(() => _editController = null);
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.caption.trim();
    final isEditable = widget.onSave != null;
    if (caption.isEmpty && !isEditable) return const SizedBox.shrink();

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 0.8),
        ),
        child: _isEditing ? _buildEditor() : _buildReader(caption, isEditable),
      ),
    );
  }

  Widget _buildReader(String caption, bool isEditable) {
    final captionText = Text(
      caption.isNotEmpty ? caption : '添注随笔 · Add caption',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: caption.isNotEmpty ? Colors.white : Colors.white60,
        fontSize: 14,
        height: 1.4,
        letterSpacing: 0.3,
        fontStyle: caption.isNotEmpty ? FontStyle.normal : FontStyle.italic,
      ),
    );
    if (!isEditable) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: captionText);
    }
    return Row(
      children: [
        Expanded(child: captionText),
        IconButton(
          key: const Key('lightbox_caption_edit_button'),
          icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
          tooltip: '编辑题注 · Edit caption',
          constraints: const BoxConstraints(minWidth: _minTapTarget, minHeight: _minTapTarget),
          onPressed: _startEditing,
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('lightbox_caption_input'),
            controller: _editController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: Colors.white,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: '写下当下的心境与留白...',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _save(),
          ),
        ),
        IconButton(
          key: const Key('lightbox_caption_save_button'),
          icon: const Icon(Icons.check, size: 20, color: Colors.white),
          tooltip: '保存题注 · Save caption',
          constraints: const BoxConstraints(minWidth: _minTapTarget, minHeight: _minTapTarget),
          onPressed: _save,
        ),
      ],
    );
  }
}
