import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/services/dictation_service.dart';
import '../controllers/editor_chrome_controller.dart';
import 'dictation_bar.dart';
import 'keyboard_accessory_row.dart';
import 'writing_dock.dart';

/// The panels below the Scholar's Desk, shown and hidden by the
/// [EditorChromeController]: the dictation bar while dictating, then the
/// keyboard accessory row while the software keyboard is open (whether or not
/// the dock is hidden; its toggle sets whether the dock returns), else the
/// Writing Dock (when hidden, nothing: its restore tab floats on the desk).
class EditorWritingPanels extends StatelessWidget {
  final EditorChromeController chrome;
  final QuillController controller;
  final QuillController Function() onEnsureTextController;
  final DictationService dictationService;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onShuffleSpark;
  final Color paperColor;
  final Color inkColor;
  final bool isPaperDark;

  const EditorWritingPanels({
    super.key,
    required this.chrome,
    required this.controller,
    required this.onEnsureTextController,
    required this.dictationService,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onShuffleSpark,
    required this.paperColor,
    required this.inkColor,
    required this.isPaperDark,
  });

  void _toggleDictation() {
    if (!chrome.isDictating) onEnsureTextController();
    chrome.toggleDictation();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = paperColor.withValues(alpha: 0.95);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (chrome.isDictating)
          DictationBar(
            controller: controller,
            dictationService: dictationService,
            onClose: chrome.stopDictation,
          ),
        if (chrome.isKeyboardVisible)
          KeyboardAccessoryRow(
            controller: controller,
            onEnsureTextController: onEnsureTextController,
            onToggleDictation: _toggleDictation,
            isWritingDockVisible: chrome.isWritingDockVisible,
            onToggleWritingDock: () => chrome.setWritingDockVisible(!chrome.isWritingDockVisible),
            isDictating: chrome.isDictating,
            backgroundColor: backgroundColor,
            inkColor: inkColor,
            isPaperDark: isPaperDark,
          )
        else if (chrome.isWritingDockVisible)
          WritingDock(
            onHide: () => chrome.setWritingDockVisible(false),
            controller: controller,
            onEnsureTextController: onEnsureTextController,
            onPickImage: onPickImage,
            onPickVideo: onPickVideo,
            onToggleDictation: _toggleDictation,
            onShuffleSpark: onShuffleSpark,
            isDictating: chrome.isDictating,
            backgroundColor: backgroundColor,
            inkColor: inkColor,
            isPaperDark: isPaperDark,
          )
      ],
    );
  }
}
