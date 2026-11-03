import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/media_sandbox_service.dart';
import '../../../editor/widgets/sandboxed_video_player.dart';
import '../../../templates/models/template_style.dart';
import 'folio_cinnabar_seal_widget.dart';
import 'folio_leaf_model.dart';
import 'folio_leaf_scaffold.dart';
import 'folio_reading_perspective.dart';
import 'folio_silk_corner_mounts_painter.dart';
import 'folio_silk_ruling_painter.dart';

/// Renders discrete integer-locked content leaves inside the Thread-Bound Folio:
/// both [FolioContentBodyLeaf] (ruled text) and [FolioTippedInEphemeraLeaf] (photo/video).
class FolioContentLeafPage extends StatelessWidget {
  final FolioLeaf leaf;
  final FolioSubstrateTheme theme;
  final MediaSandboxService? mediaService;
  final bool isTurningLeaf;
  final VoidCallback? onTurnForward;
  final VoidCallback? onTurnBackward;

  const FolioContentLeafPage({
    super.key,
    required this.leaf,
    required this.theme,
    this.mediaService,
    this.isTurningLeaf = false,
    this.onTurnForward,
    this.onTurnBackward,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = theme.isDark ? const Color(0xFFE07A6B) : const Color(0xFFB83B2E);

    return FolioLeafScaffold(
      theme: theme,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRunningHeader(),
            const SizedBox(height: 6),
            Center(
              child: SizedBox(
                width: 320,
                height: 448,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: FolioSilkRulingPainter(
                          layout: _resolveRulingLayout(),
                          ruleColor: theme.ruleColor,
                          frameColor: theme.frameColor,
                          isDark: theme.isDark,
                        ),
                      ),
                    ),
                    Positioned.fill(child: _buildLeafContent()),
                    if (leaf.isConcludingLeaf) _buildConcludingSeal(),
                  ],
                ),
              ),
            ),
            const Spacer(),
            _buildFooterColophon(accentColor),
          ],
        ),
      ),
    );
  }

  FolioRulingLayout _resolveRulingLayout() {
    if (leaf is FolioContentBodyLeaf) {
      return (leaf as FolioContentBodyLeaf).layout;
    }
    return FolioRulingLayout.faithfulHorizontal;
  }

  Widget _buildRunningHeader() {
    final title = switch (leaf) {
      FolioContentBodyLeaf bodyLeaf => bodyLeaf.title,
      FolioTippedInEphemeraLeaf ephemeraLeaf => ephemeraLeaf.title,
      _ => '',
    };
    final layoutLabel = switch (leaf) {
      FolioContentBodyLeaf bodyLeaf => switch (bodyLeaf.layout) {
          FolioRulingLayout.vermilionVertical => '朱丝栏 · 竖排',
          FolioRulingLayout.genkoVertical => '原稿用紙 · 竖排',
          FolioRulingLayout.faithfulHorizontal => '乌丝栏 · 横排',
        },
      FolioTippedInEphemeraLeaf ephemeraLeaf =>
        ephemeraLeaf.mediaType == 'video' ? '动态拓片 · 影印' : '珍藏拓影 · 插页',
      _ => '',
    };

    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '《$title》 · 第 ${leaf.leafIndex + 1} 页',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.0, letterSpacing: 1.2, fontFamily: theme.fontFamily, color: theme.inkSecondary),
            ),
          ),
          Text(layoutLabel, style: TextStyle(fontSize: 10.0, letterSpacing: 0.8, color: theme.inkSecondary.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _buildLeafContent() {
    if (leaf is FolioContentBodyLeaf) {
      final bodyLeaf = leaf as FolioContentBodyLeaf;
      return bodyLeaf.layout == FolioRulingLayout.faithfulHorizontal
          ? _buildHorizontalBody(bodyLeaf)
          : _buildVerticalBody(bodyLeaf);
    }
    if (leaf is FolioTippedInEphemeraLeaf) {
      return _buildTippedInEphemera(leaf as FolioTippedInEphemeraLeaf);
    }
    return const SizedBox.shrink();
  }

  Widget _buildHorizontalBody(FolioContentBodyLeaf bodyLeaf) {
    final rows = bodyLeaf.horizontalRows ?? const [];
    final jiazhuColor = theme.isDark ? const Color(0xFFD4AF37) : const Color(0xFFB83B2E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(14, (rowIndex) {
        final row = rowIndex < rows.length ? rows[rowIndex] : null;
        return SizedBox(
          height: 32.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: row == null || row.isEmpty
                  ? const SizedBox.shrink()
                  : Text.rich(
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      TextSpan(
                        children: row.segments.map((segment) {
                          if (segment.isJiazhuNote) {
                            return WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                decoration: BoxDecoration(
                                  color: jiazhuColor.withValues(alpha: 0.08),
                                  border: Border.all(color: jiazhuColor.withValues(alpha: 0.35), width: 0.7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  segment.text,
                                  style: TextStyle(fontSize: 10.5, height: 1.1, fontFamily: theme.fontFamily, color: segment.color ?? theme.inkPrimary),
                                ),
                              ),
                            );
                          }
                          return TextSpan(
                            text: segment.text,
                            style: TextStyle(
                              fontSize: 15.0,
                              height: 1.2,
                              letterSpacing: 1.1,
                              fontWeight: segment.isBold ? FontWeight.bold : FontWeight.normal,
                              fontStyle: segment.isItalic ? FontStyle.italic : FontStyle.normal,
                              decoration: (segment.isTodo && segment.isChecked) ? TextDecoration.lineThrough : null,
                              color: segment.color ?? ((segment.isTodo && segment.isChecked) ? theme.inkSecondary : theme.inkPrimary),
                              fontFamily: theme.fontFamily,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerticalBody(FolioContentBodyLeaf bodyLeaf) {
    final columns = bodyLeaf.verticalColumns ?? const [];
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(10, (colIndex) {
        final column = colIndex < columns.length ? columns[colIndex] : null;
        final cells = column?.cells ?? const [];
        return SizedBox(
          width: 32.0,
          height: 448.0,
          child: Column(
            children: List.generate(16, (rowIndex) {
              final cell = rowIndex < cells.length ? cells[rowIndex] : null;
              return SizedBox(
                width: 32.0,
                height: 28.0,
                child: Center(child: _buildVerticalCell(cell)),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildVerticalCell(FolioVerticalCell? cell) {
    if (cell == null || cell.mainChar.isEmpty) return const SizedBox.shrink();
    final jiazhuColor = theme.isDark ? const Color(0xFFD4AF37) : const Color(0xFFB83B2E);

    if (cell.isJiazhuPair) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 1.0),
        decoration: BoxDecoration(
          color: jiazhuColor.withValues(alpha: 0.08),
          border: Border.all(color: jiazhuColor.withValues(alpha: 0.35), width: 0.6),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(cell.secondChar, style: TextStyle(fontSize: 9.5, height: 1.0, fontFamily: theme.fontFamily, color: theme.inkPrimary.withValues(alpha: 0.88))),
            Text(cell.mainChar, style: TextStyle(fontSize: 9.5, height: 1.0, fontFamily: theme.fontFamily, color: theme.inkPrimary.withValues(alpha: 0.88))),
          ],
        ),
      );
    }
    if (cell.requiresQuarterTurnRotation) {
      return RotatedBox(
        quarterTurns: 1,
        child: Text(cell.mainChar, style: TextStyle(fontSize: 15.0, color: cell.color ?? theme.inkPrimary, fontFamily: theme.fontFamily)),
      );
    }
    if (cell.isCornerPunctuation) {
      return Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 2, right: 3),
          child: Text(cell.mainChar, style: TextStyle(fontSize: 14.0, color: cell.color ?? theme.inkPrimary, fontFamily: theme.fontFamily)),
        ),
      );
    }
    return Text(
      cell.mainChar,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 15.5,
        height: 1.0,
        fontWeight: cell.isTodo ? FontWeight.w600 : FontWeight.w400,
        color: cell.color ?? ((cell.isTodo && cell.isChecked) ? theme.inkSecondary : theme.inkPrimary),
        fontFamily: theme.fontFamily,
      ),
    );
  }

  File? _resolveFileImmediate(String rawPath) =>
      !MediaSandboxService.isStrictlyRelative(rawPath) ? File(rawPath) : null;

  Future<File> _resolveFile(String rawPath) async =>
      (MediaSandboxService.isStrictlyRelative(rawPath) && mediaService != null)
          ? await mediaService!.getFileFromRelativePath(rawPath)
          : File(rawPath);

  Widget _buildTippedInEphemera(FolioTippedInEphemeraLeaf ephemeraLeaf) {
    final silkColor = theme.isDark ? const Color(0xD0C8A055) : const Color(0xC0DFC898);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.isDark ? const Color(0xFF141619) : const Color(0xFFFDFBF7),
                    border: Border.all(color: const Color(0xFF8C7355).withValues(alpha: 0.35)),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: ClipRRect(
                    child: FutureBuilder<File>(
                      initialData: _resolveFileImmediate(ephemeraLeaf.sandboxedRelativePath),
                      future: _resolveFile(ephemeraLeaf.sandboxedRelativePath),
                      builder: (context, snapshot) {
                        final file = snapshot.data;
                        if (file != null) {
                          if (ephemeraLeaf.mediaType == 'video' && !isTurningLeaf && file.existsSync()) {
                            return SandboxedVideoPlayer(
                              videoFile: file,
                              autoPlay: false,
                            );
                          }

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                file,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(
                                    ephemeraLeaf.mediaType == 'video' ? Icons.videocam_outlined : Icons.photo_outlined,
                                    size: 40,
                                    color: theme.inkSecondary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              if (ephemeraLeaf.mediaType == 'video')
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white70, width: 1.5),
                                    ),
                                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                                  ),
                                ),
                            ],
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        }

                        return Center(
                          child: Icon(
                            ephemeraLeaf.mediaType == 'video' ? Icons.videocam_outlined : Icons.photo_outlined,
                            size: 40,
                            color: theme.inkSecondary.withValues(alpha: 0.5),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned.fill(child: CustomPaint(painter: FolioSilkCornerMountsPainter(silkColor: silkColor))),
              ],
            ),
          ),
          if (ephemeraLeaf.caption != null && ephemeraLeaf.caption!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ephemeraLeaf.caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, fontFamily: theme.fontFamily, color: theme.inkSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConcludingSeal() {
    final isHorizontal = leaf is FolioContentBodyLeaf &&
        (leaf as FolioContentBodyLeaf).layout == FolioRulingLayout.faithfulHorizontal;
    final (sealText, sealStyle) = switch (leaf) {
      FolioContentBodyLeaf b => (b.sealText ?? '心迹安放', b.sealStyle),
      FolioTippedInEphemeraLeaf e => (e.sealText ?? '心迹安放', e.sealStyle),
      _ => ('心迹安放', SealCarvingStyle.zhuwen),
    };

    return Positioned(
      left: isHorizontal ? null : 12,
      right: isHorizontal ? 12 : null,
      bottom: 12,
      child: FolioCinnabarSealWidget(
        sealText: sealText,
        theme: theme,
        sealStyle: sealStyle,
        animateOnMount: !isTurningLeaf,
      ),
    );
  }

  Widget _buildFooterColophon(Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '第 ${leaf.leafIndex + 1}/${leaf.totalLeaves} 页 · 拾光存卷',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.0, letterSpacing: 1.1, color: theme.inkSecondary),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onTurnBackward != null)
              Semantics(
                button: true,
                label: '上一页',
                child: GestureDetector(
                  onTap: onTurnBackward,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                    child: Text('◂ 上一页', style: TextStyle(fontSize: 10.5, color: theme.inkSecondary)),
                  ),
                ),
              ),
            if (onTurnForward != null)
              Semantics(
                button: true,
                label: '下一页',
                child: GestureDetector(
                  onTap: onTurnForward,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('下一页 ▸', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: accentColor)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
