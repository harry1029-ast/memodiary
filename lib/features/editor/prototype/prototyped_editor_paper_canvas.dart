import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../models/stationery_sheet_configs.dart';
import '../services/editor_pagination_coordinator.dart';
import 'breathing_stride_canvas.dart';
import 'paper_framing_prototype_models.dart';
import 'prototype_variant_switcher.dart';
import 'screen_adaptive_canvas.dart';
import 'tactile_stationery_card_canvas.dart';

/// Container that mounts the active Paper Framing prototype variant
/// alongside the interactive floating [PrototypeVariantSwitcher].
class PrototypedEditorPaperCanvas extends StatefulWidget {
  final StationerySheetThemeConfig themeConfig;
  final StationeryLetterheadConfig letterheadConfig;
  final MediaSandboxService mediaSandboxService;
  final VoidCallback onSaveDraft;
  final EditorPaginationCoordinator coordinator;
  final PageController pageController;
  final int currentSheetIndex;
  final int totalSheets;
  final VoidCallback? onPreviousSheet;
  final VoidCallback? onNextSheet;
  final ValueChanged<int>? onPageChanged;
  final void Function(int sheetIndex)? onDeleteEphemera;
  final void Function(int sheetIndex)? onSpillBack;

  const PrototypedEditorPaperCanvas({
    super.key,
    required this.themeConfig,
    required this.letterheadConfig,
    required this.mediaSandboxService,
    required this.onSaveDraft,
    required this.coordinator,
    required this.pageController,
    this.currentSheetIndex = 0,
    this.totalSheets = 1,
    this.onPreviousSheet,
    this.onNextSheet,
    this.onPageChanged,
    this.onDeleteEphemera,
    this.onSpillBack,
  });

  @override
  State<PrototypedEditorPaperCanvas> createState() => _PrototypedEditorPaperCanvasState();
}

class _PrototypedEditorPaperCanvasState extends State<PrototypedEditorPaperCanvas> {
  PaperFramingVariant _currentVariant = PaperFramingVariant.variantA;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _buildActiveCanvas(),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 12.0,
          child: Center(
            child: PrototypeVariantSwitcher(
              currentVariant: _currentVariant,
              onVariantChanged: (newVariant) {
                setState(() => _currentVariant = newVariant);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCanvas() {
    switch (_currentVariant) {
      case PaperFramingVariant.variantA:
        return TactileStationeryCardCanvas(
          themeConfig: widget.themeConfig,
          letterheadConfig: widget.letterheadConfig,
          mediaSandboxService: widget.mediaSandboxService,
          onSaveDraft: widget.onSaveDraft,
          coordinator: widget.coordinator,
          pageController: widget.pageController,
          currentSheetIndex: widget.currentSheetIndex,
          totalSheets: widget.totalSheets,
          onPreviousSheet: widget.onPreviousSheet,
          onNextSheet: widget.onNextSheet,
          onPageChanged: widget.onPageChanged,
          onDeleteEphemera: widget.onDeleteEphemera,
          onSpillBack: widget.onSpillBack,
        );
      case PaperFramingVariant.variantB:
        return BreathingStrideCanvas(
          themeConfig: widget.themeConfig,
          letterheadConfig: widget.letterheadConfig,
          mediaSandboxService: widget.mediaSandboxService,
          onSaveDraft: widget.onSaveDraft,
          coordinator: widget.coordinator,
          pageController: widget.pageController,
          currentSheetIndex: widget.currentSheetIndex,
          totalSheets: widget.totalSheets,
          onPreviousSheet: widget.onPreviousSheet,
          onNextSheet: widget.onNextSheet,
          onPageChanged: widget.onPageChanged,
          onDeleteEphemera: widget.onDeleteEphemera,
          onSpillBack: widget.onSpillBack,
        );
      case PaperFramingVariant.variantC:
        return ScreenAdaptiveCanvas(
          themeConfig: widget.themeConfig,
          letterheadConfig: widget.letterheadConfig,
          mediaSandboxService: widget.mediaSandboxService,
          onSaveDraft: widget.onSaveDraft,
          coordinator: widget.coordinator,
          pageController: widget.pageController,
          currentSheetIndex: widget.currentSheetIndex,
          totalSheets: widget.totalSheets,
          onPreviousSheet: widget.onPreviousSheet,
          onNextSheet: widget.onNextSheet,
          onPageChanged: widget.onPageChanged,
          onDeleteEphemera: widget.onDeleteEphemera,
          onSpillBack: widget.onSpillBack,
        );
    }
  }
}
