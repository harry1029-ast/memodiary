import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../core/services/dictation_service.dart';

/// Floating dictation bar streaming native recognized speech directly into Quill editor
class DictationBar extends StatefulWidget {
  final QuillController controller;
  final DictationService dictationService;
  final VoidCallback onClose;

  const DictationBar({
    super.key,
    required this.controller,
    required this.dictationService,
    required this.onClose,
  });

  @override
  State<DictationBar> createState() => _DictationBarState();
}

class _DictationBarState extends State<DictationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String _interimText = '';
  int _lastCommittedLength = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _startListening();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startListening() {
    widget.dictationService.startDictation(
      onResult: (text, isFinal) {
        if (!mounted) return;

        setState(() {
          _interimText = text;
        });

        if (isFinal && text.isNotEmpty) {
          _commitText(text);
        }
      },
    );
  }

  void _commitText(String text) {
    // If text has already been partially committed, commit remainder
    final newWords = text.substring(_lastCommittedLength).trim();
    if (newWords.isNotEmpty) {
      final index = widget.controller.selection.baseOffset.clamp(
        0,
        widget.controller.document.length - 1,
      );
      final space = (index > 0) ? ' ' : '';
      widget.controller.replaceText(index, 0, '$space$newWords', null);
      widget.controller.updateSelection(
        TextSelection.collapsed(offset: index + space.length + newWords.length),
        ChangeSource.local,
      );
    }
    _lastCommittedLength = text.length;
  }

  void _handleDone() {
    if (_interimText.isNotEmpty && _lastCommittedLength < _interimText.length) {
      _commitText(_interimText);
    }
    widget.dictationService.stopDictation();
    widget.onClose();
  }

  void _handleCancel() {
    widget.dictationService.cancelDictation();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.deepPurple.shade100, width: 1.5),
      ),
      child: Row(
        children: [
          // Animated Pulse Mic Icon
          ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.15).animate(
              CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.mic, size: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),

          // Interim Text or Prompt
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Listening to voice...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Text(
                  _interimText.isEmpty ? 'Speak naturally...' : _interimText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: _interimText.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Done Button
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            onPressed: _handleDone,
            tooltip: 'Insert & Finish',
          ),

          // Cancel Button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 24),
            onPressed: _handleCancel,
            tooltip: 'Cancel Dictation',
          ),
        ],
      ),
    );
  }
}

