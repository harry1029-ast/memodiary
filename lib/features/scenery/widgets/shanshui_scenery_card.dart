import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../models/shanshui_atmosphere.dart';
import '../services/scenery_settings_service.dart';
import 'shanshui_scenery_painting.dart';
import 'thought_spark_dock.dart';

/// Primary composite timeline header card.
/// Features a living 16:9 water-ink landscape with an embedded [ThoughtSparkDock],
/// collapsible into a slender ~42px Xuan status strip for minimalists.
class ShanshuiSceneryCard extends StatefulWidget {
  final ShanshuiAtmosphereState atmosphere;
  final String activePrompt;
  final VoidCallback onRefreshPrompt;
  final ValueChanged<String> onWritePrompt;
  final VoidCallback onOpenContemplation;
  final ScenerySettingsService? settingsService;
  final bool? enableAmbientAnimation;
  final bool isVisible;

  const ShanshuiSceneryCard({
    super.key,
    required this.atmosphere,
    required this.activePrompt,
    required this.onRefreshPrompt,
    required this.onWritePrompt,
    required this.onOpenContemplation,
    this.settingsService,
    this.enableAmbientAnimation,
    this.isVisible = true,
  });

  @override
  State<ShanshuiSceneryCard> createState() => _ShanshuiSceneryCardState();
}

class _ShanshuiSceneryCardState extends State<ShanshuiSceneryCard> {
  late final ScenerySettingsService _settingsService;
  bool _isCollapsed = false;
  bool _isThoughtSparkHidden = false;

  @override
  void initState() {
    super.initState();
    _settingsService = widget.settingsService ?? ScenerySettingsService();
    _loadCollapsedPreference();
    _loadThoughtSparkPreference();
  }

  Future<void> _loadCollapsedPreference() async {
    final collapsed = await _settingsService.getIsCollapsed();
    if (mounted && collapsed != _isCollapsed) {
      setState(() => _isCollapsed = collapsed);
    }
  }

  Future<void> _loadThoughtSparkPreference() async {
    final hidden = await _settingsService.getIsThoughtSparkHidden();
    if (mounted && hidden != _isThoughtSparkHidden) {
      setState(() => _isThoughtSparkHidden = hidden);
    }
  }

  Future<void> _toggleCollapsed(bool collapsed) async {
    setState(() => _isCollapsed = collapsed);
    await _settingsService.setIsCollapsed(collapsed);
  }

  Future<void> _toggleThoughtSparkHidden(bool isHidden) async {
    setState(() => _isThoughtSparkHidden = isHidden);
    await _settingsService.setIsThoughtSparkHidden(isHidden);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<InkDiaryTokens>() ?? InkDiaryTokens.light;

    if (_isCollapsed) {
      return _buildCollapsedStrip(tokens);
    }

    return _buildExpandedCard(tokens);
  }

  Widget _buildCollapsedStrip(InkDiaryTokens tokens) {
    return Container(
      key: const Key('scenery_card_collapsed'),
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.agedFiber.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.deckleBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Seasonal seal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: tokens.cinnabar,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              widget.atmosphere.season.sealBadgeZh,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Weather/time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: tokens.xuanGround,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: tokens.deckleBorder),
            ),
            child: Text(
              widget.atmosphere.timeWeatherBadgeZh,
              style: TextStyle(
                color: tokens.nongmo,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Prompt snippet
          Expanded(
            child: Text(
              widget.activePrompt,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontLiterata,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: tokens.danmo,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Expand chevron button
          Semantics(
            label: '展开山水画卷',
            button: true,
            child: InkWell(
              key: const Key('scenery_expand_button'),
              onTap: () => _toggleCollapsed(false),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: tokens.danmo,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCard(InkDiaryTokens tokens) {
    return Container(
      key: const Key('scenery_card_expanded'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight = constraints.maxWidth <= 500
                ? constraints.maxWidth * 9.0 / 16.0
                : (constraints.maxWidth * 9.0 / 16.0).clamp(180.0, 240.0);
            return SizedBox(
              width: double.infinity,
              height: cardHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Shanshui canvas painting
                  ShanshuiSceneryPainting(
                    atmosphere: widget.atmosphere,
                    aspectRatio: constraints.maxWidth / cardHeight,
                    fullPoem: false,
                    showCalligraphy: false,
                    enableAmbientAnimation: widget.enableAmbientAnimation,
                    isVisible: widget.isVisible,
                  ),

                  // 2. Upper scenery tap target (opens Contemplation View)
                  Positioned.fill(
                    bottom: 54, // Don't block ThoughtSparkDock
                    child: Semantics(
                      button: true,
                      label: '进入沉浸山水画卷',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const Key('scenery_canvas_tap_target'),
                          onTap: widget.onOpenContemplation,
                        ),
                      ),
                    ),
                  ),

                  // 3. Top header overlay strip
                  Positioned(
                    top: 8,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Collapse chevron & time/weather badge
                        Row(
                          children: [
                            Semantics(
                              label: '折叠山水画卷',
                              button: true,
                              child: InkWell(
                                key: const Key('scenery_collapse_button'),
                                onTap: () => _toggleCollapsed(true),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0x991E1A17),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    size: 16,
                                    color: Color(0xFFF7F4EB),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0x991E1A17),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: Text(
                                widget.atmosphere.timeWeatherBadgeZh,
                                style: const TextStyle(
                                  color: Color(0xFFF7F4EB),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Seasonal title & seal stamp (User Story 21)
                        Row(
                          children: [
                            Text(
                              widget.atmosphere.season.nameZh,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF7F4EB),
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Color(0x99000000),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: tokens.cinnabar,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.atmosphere.season.sealBadgeZh,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. Embedded Thought Spark Dock or Mini Reveal Tab
                  if (!_isThoughtSparkHidden)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ThoughtSparkDock(
                        prompt: widget.activePrompt,
                        onRefreshPrompt: widget.onRefreshPrompt,
                        onWritePrompt: widget.onWritePrompt,
                        onHideDock: () => _toggleThoughtSparkHidden(true),
                      ),
                    )
                  else
                    Positioned(
                      bottom: 6,
                      right: 10,
                      child: Semantics(
                        label: '展开灵感火花',
                        button: true,
                        child: InkWell(
                          key: const Key('thought_spark_reveal_button'),
                          onTap: () => _toggleThoughtSparkHidden(false),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xB31E1A17),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: tokens.cinnabar,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  '灵感火花 ⌃',
                                  style: TextStyle(
                                    color: Color(0xFFF7F4EB),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
