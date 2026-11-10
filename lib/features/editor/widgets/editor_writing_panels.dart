import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/services/dictation_service.dart';
import '../controllers/editor_chrome_controller.dart';
import 'dictation_bar.dart';
import 'writing_dock.dart';
import 'writing_dock_collapse_tabs.dart';

/// The panels below the Scholar's Desk: the dictation bar while dictating and
/// the Writing Dock, shown and hidden by the [EditorChromeController].
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (chrome.isDictating)
          DictationBar(
            controller: controller,
            dictationService: dictationService,
            onClose: chrome.stopDictation,
          ),
        if (chrome.isWritingDockVisible)
          WritingDock(
            onHide: () => chrome.setWritingDockVisible(false),
            controller: controller,
            onEnsureTextController: onEnsureTextController,
            onPickImage: onPickImage,
            onPickVideo: onPickVideo,
            onToggleDictation: _toggleDictation,
            onShuffleSpark: onShuffleSpark,
            isDictating: chrome.isDictating,
            backgroundColor: paperColor.withValues(alpha: 0.95),
            inkColor: inkColor,
            isPaperDark: isPaperDark,
          )
        else
          WritingDockRestoreTab(onRestore: () => chrome.setWritingDockVisible(true)),
      ],
    );
  }
}
