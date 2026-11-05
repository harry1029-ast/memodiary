import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/media_sandbox_service.dart';
import '../../../editor/widgets/sandboxed_video_player.dart';
import '../../../scenery/models/shanshui_atmosphere.dart';
import '../../../templates/models/template_style.dart';
import 'folio_body_calligraphy_view.dart';
import 'folio_cinnabar_seal_widget.dart';
import 'folio_ephemera_overlay_layer.dart';
import 'folio_leaf_model.dart';
import 'folio_leaf_scaffold.dart';
import 'folio_reading_perspective.dart';
import 'folio_silk_corner_mounts_painter.dart';
import 'folio_silk_ruling_painter.dart';

/// Renders discrete integer-locked content leaves inside the Thread-Bound Folio:
/// both [FolioContentBodyLeaf] (ruled text with Ephemera Overlay) and [FolioTippedInEphemeraLeaf].
class FolioContentLeafPage extends StatefulWidget {
  final FolioLeaf leaf;
  final FolioSubstrateTheme theme;
  final MediaSandboxService? mediaService;
  final ShanshuiRealm atmosphereRealm;
  final bool isTurningLeaf;
  final VoidCallback? onTurnForward;
  final VoidCallback? onTurnBackward;
  final void Function(String photoId, double? xRatio, double? yRatio)? onOverlayPositionChanged;

  const FolioContentLeafPage({
    super.key,
    required this.leaf,
    required this.theme,
    this.mediaService,
    this.atmosphereRealm = ShanshuiRealm.nature,
    this.isTurningLeaf = false,
    this.onTurnForward,
    this.onTurnBackward,
    this.onOverlayPositionChanged,
  });

  @override
  State<FolioContentLeafPage> createState() => _FolioContentLeafPageState();
}

class _FolioContentLeafPageState extends State<FolioContentLeafPage> {
  bool _isPolaroidHidden = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.theme.isDark ? const Color(0xFFE07A6B) : const Color(0xFFB83B2E);
    final leaf = widget.leaf;

    return FolioLeafScaffold(
      theme: widget.theme,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRunningHeader(accentColor),
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
                          ruleColor: widget.theme.ruleColor,
                          frameColor: widget.theme.frameColor,
                          isDark: widget.theme.isDark,
                        ),
                      ),
                    ),
                    Positioned.fill(child: _buildLeafContent()),
                    if (leaf.isConcludingLeaf) _buildConcludingSeal(),
                    if (leaf is FolioContentBodyLeaf && leaf.photos.isNotEmpty)
                      FolioEphemeraOverlayLayer(
                        photos: leaf.photos,
                        layout: leaf.layout,
                        mediaService: widget.mediaService,
                        atmosphereRealm: widget.atmosphereRealm,
                        isHidden: _isPolaroidHidden,
                        onHide: () => setState(() => _isPolaroidHidden = true),
                        onPositionChanged: widget.onOverlayPositionChanged,
                      ),
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
    if (widget.leaf is FolioContentBodyLeaf) {
      return (widget.leaf as FolioContentBodyLeaf).layout;
    }
    return FolioRulingLayout.faithfulHorizontal;
  }

  Widget _buildRunningHeader(Color accentColor) {
    final leaf = widget.leaf;
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

    final hasPhotos = leaf is FolioContentBodyLeaf && leaf.photos.isNotEmpty;

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
              style: TextStyle(
                fontSize: 11.0,
                letterSpacing: 1.2,
                fontFamily: widget.theme.fontFamily,
                color: widget.theme.inkSecondary,
              ),
            ),
          ),
          if (hasPhotos)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  key: const Key('folio_ephemera_restore_pill'),
                  onTap: () => setState(() => _isPolaroidHidden = !_isPolaroidHidden),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _isPolaroidHidden
                          ? accentColor.withValues(alpha: 0.14)
                          : Colors.black.withValues(alpha: 0.05),
                      border: Border.all(
                        color: _isPolaroidHidden
                            ? accentColor.withValues(alpha: 0.55)
                            : widget.theme.inkSecondary.withValues(alpha: 0.35),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _isPolaroidHidden ? '📌 展开微笺' : '👁️ 隐藏微笺',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: _isPolaroidHidden ? accentColor : widget.theme.inkSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              layoutLabel,
              style: TextStyle(
                fontSize: 10.0,
                letterSpacing: 0.8,
                color: widget.theme.inkSecondary.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeafContent() {
    if (widget.leaf is FolioContentBodyLeaf) {
      return FolioBodyCalligraphyView(
        bodyLeaf: widget.leaf as FolioContentBodyLeaf,
        theme: widget.theme,
      );
    }
    if (widget.leaf is FolioTippedInEphemeraLeaf) {
      return _buildTippedInEphemera(widget.leaf as FolioTippedInEphemeraLeaf);
    }
    return const SizedBox.shrink();
  }

  File? _resolveFileImmediate(String rawPath) =>
      !MediaSandboxService.isStrictlyRelative(rawPath) ? File(rawPath) : null;

  Future<File> _resolveFile(String rawPath) async =>
      (MediaSandboxService.isStrictlyRelative(rawPath) && widget.mediaService != null)
          ? await widget.mediaService!.getFileFromRelativePath(rawPath)
          : File(rawPath);

  Widget _buildTippedInEphemera(FolioTippedInEphemeraLeaf ephemeraLeaf) {
    final silkColor = widget.theme.isDark ? const Color(0xD0C8A055) : const Color(0xC0DFC898);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: widget.theme.isDark ? const Color(0xFF141619) : const Color(0xFFFDFBF7),
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
                          if (ephemeraLeaf.mediaType == 'video' && !widget.isTurningLeaf && file.existsSync()) {
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
                                    color: widget.theme.inkSecondary.withValues(alpha: 0.5),
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
                            color: widget.theme.inkSecondary.withValues(alpha: 0.5),
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
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                fontFamily: widget.theme.fontFamily,
                color: widget.theme.inkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConcludingSeal() {
    final leaf = widget.leaf;
    final isHorizontal = leaf is FolioContentBodyLeaf &&
        leaf.layout == FolioRulingLayout.faithfulHorizontal;
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
        theme: widget.theme,
        sealStyle: sealStyle,
        animateOnMount: !widget.isTurningLeaf,
      ),
    );
  }

  Widget _buildFooterColophon(Color accentColor) {
    final leaf = widget.leaf;
    final hasPhotos = leaf is FolioContentBodyLeaf && leaf.photos.isNotEmpty;
    final footerNotice = hasPhotos ? '第 ${leaf.leafIndex + 1}/${leaf.totalLeaves} 页 · 可自由拖拽微笺位置' : '第 ${leaf.leafIndex + 1}/${leaf.totalLeaves} 页 · 拾光存卷';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            footerNotice,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.0, letterSpacing: 1.1, color: widget.theme.inkSecondary),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onTurnBackward != null)
              Semantics(
                button: true,
                label: '上一页',
                child: GestureDetector(
                  onTap: widget.onTurnBackward,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                    child: Text('◂ 上一页', style: TextStyle(fontSize: 10.5, color: widget.theme.inkSecondary)),
                  ),
                ),
              ),
            if (widget.onTurnForward != null)
              Semantics(
                button: true,
                label: '下一页',
                child: GestureDetector(
                  onTap: widget.onTurnForward,
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
