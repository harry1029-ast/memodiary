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
  final ValueChanged<SceneryRealmPreference>? onRealmPreferenceChanged;

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
    this.onRealmPreferenceChanged,
  });

  @override
  State<ShanshuiSceneryCard> createState() => _ShanshuiSceneryCardState();
}

class _ShanshuiSceneryCardState extends State<ShanshuiSceneryCard> {
  late final ScenerySettingsService _settingsService;
  bool _isCollapsed = false;
  bool _isThoughtSparkHidden = false;
  ShanshuiAtmosphereState? _localAtmosphere;

  ShanshuiAtmosphereState get _effectiveAtmosphere =>
      _localAtmosphere ?? widget.atmosphere;

  @override
  void initState() {
    super.initState();
    _settingsService = widget.settingsService ?? ScenerySettingsService();
    _loadCollapsedPreference();
    _loadThoughtSparkPreference();
  }

  @override
  void didUpdateWidget(ShanshuiSceneryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.atmosphere != oldWidget.atmosphere) {
      _localAtmosphere = null;
    }
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

  Future<void> _showRealmSwitcherSheet(BuildContext context, InkDiaryTokens tokens) async {
    final currentPref = await _settingsService.getRealmPreference();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.xuanGround,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '画卷境域',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tokens.jiaomo,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: tokens.danmo),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                Text(
                  '随文入境根据近作自动切换，亦可手动锁定画卷境域',
                  style: TextStyle(fontSize: 11, color: tokens.danmo),
                ),
                const SizedBox(height: 12),
                _buildRealmOptionTile(
                  sheetContext: sheetContext,
                  tokens: tokens,
                  key: const Key('realm_option_auto'),
                  preference: SceneryRealmPreference.auto,
                  title: 'Auto (随文入境)',
                  subtitle: '根据近24小时日记内容自适应意境',
                  isSelected: currentPref == SceneryRealmPreference.auto,
                ),
                _buildRealmOptionTile(
                  sheetContext: sheetContext,
                  tokens: tokens,
                  key: const Key('realm_option_nature'),
                  preference: SceneryRealmPreference.nature,
                  title: 'Nature (林泉)',
                  subtitle: '水墨山水 · 烟波浩渺',
                  isSelected: currentPref == SceneryRealmPreference.nature,
                ),
                _buildRealmOptionTile(
                  sheetContext: sheetContext,
                  tokens: tokens,
                  key: const Key('realm_option_indoor'),
                  preference: SceneryRealmPreference.indoor,
                  title: 'Indoor (雅室)',
                  subtitle: '书房茶室 · 烹茶伴读',
                  isSelected: currentPref == SceneryRealmPreference.indoor,
                ),
                _buildRealmOptionTile(
                  sheetContext: sheetContext,
                  tokens: tokens,
                  key: const Key('realm_option_outdoor'),
                  preference: SceneryRealmPreference.outdoor,
                  title: 'Outdoor (市井)',
                  subtitle: '古镇街市 · 烟火人间',
                  isSelected: currentPref == SceneryRealmPreference.outdoor,
                ),
              ],
            ),
          ),
        ),
      );
    },
    );
  }

  Widget _buildRealmOptionTile({
    required BuildContext sheetContext,
    required InkDiaryTokens tokens,
    required Key key,
    required SceneryRealmPreference preference,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Semantics(
      button: true,
      label: '选择 $title',
      child: ListTile(
        key: key,
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tokens.agedFiber,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            preference == SceneryRealmPreference.auto
                ? Icons.auto_awesome_outlined
                : preference == SceneryRealmPreference.nature
                    ? Icons.landscape_outlined
                    : preference == SceneryRealmPreference.indoor
                        ? Icons.meeting_room_outlined
                        : Icons.storefront_outlined,
            color: isSelected ? tokens.cinnabar : tokens.danmo,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? tokens.cinnabar : tokens.jiaomo,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 10.5, color: tokens.danmo),
        ),
        trailing: isSelected
            ? Icon(Icons.check_rounded, color: tokens.cinnabar, size: 20)
            : null,
        onTap: () async {
          Navigator.of(sheetContext).pop();
          await _settingsService.setRealmPreference(preference);
          if (mounted) {
            setState(() {
              if (preference == SceneryRealmPreference.auto) {
                _localAtmosphere = widget.atmosphere.copyWith(
                  isJournalInferred: widget.atmosphere.isJournalInferred,
                );
              } else {
                final realm = switch (preference) {
                  SceneryRealmPreference.nature => ShanshuiRealm.nature,
                  SceneryRealmPreference.indoor => ShanshuiRealm.indoor,
                  SceneryRealmPreference.outdoor => ShanshuiRealm.outdoor,
                  SceneryRealmPreference.auto => ShanshuiRealm.nature,
                };
                _localAtmosphere = widget.atmosphere.copyWith(
                  realm: realm,
                  isJournalInferred: false,
                );
              }
            });
          }
          widget.onRealmPreferenceChanged?.call(preference);
        },
      ),
    );
  }

  Widget _buildRealmBadge(InkDiaryTokens tokens, {bool isCollapsed = false}) {
    final atmosphere = _effectiveAtmosphere;
    return Semantics(
      button: true,
      label: '切换画卷境域: ${atmosphere.realmBadgeZh}',
      child: InkWell(
        key: const Key('scenery_realm_badge'),
        onTap: () => _showRealmSwitcherSheet(context, tokens),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
          decoration: BoxDecoration(
            color: isCollapsed
                ? tokens.xuanGround
                : const Color(0x991E1A17),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCollapsed
                  ? (atmosphere.isJournalInferred
                      ? tokens.cinnabar.withValues(alpha: 0.6)
                      : tokens.deckleBorder)
                  : (atmosphere.isJournalInferred
                      ? tokens.cinnabar.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.15)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (atmosphere.isJournalInferred) ...[
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.cinnabar,
                  ),
                ),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  atmosphere.realmBadgeZh,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: isCollapsed ? tokens.nongmo : const Color(0xFFF7F4EB),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: tokens.cinnabar,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              _effectiveAtmosphere.sealBadgeZh,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Realm badge
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: _buildRealmBadge(tokens, isCollapsed: true),
          ),
          const SizedBox(width: 4),

          // Weather/time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: tokens.xuanGround,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: tokens.deckleBorder),
            ),
            child: Text(
              _effectiveAtmosphere.timeWeatherBadgeZh,
              style: TextStyle(
                color: tokens.nongmo,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Prompt snippet
          Expanded(
            child: Text(
              widget.activePrompt,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontLiterata,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: tokens.danmo,
              ),
            ),
          ),
          const SizedBox(width: 4),

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
                    atmosphere: _effectiveAtmosphere,
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
                        // Left: Collapse chevron & time/weather badge & realm badge
                        Expanded(
                          child: Row(
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
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0x991E1A17),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                child: Text(
                                  _effectiveAtmosphere.timeWeatherBadgeZh,
                                  style: const TextStyle(
                                    color: Color(0xFFF7F4EB),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _buildRealmBadge(tokens),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Right: Seasonal title & seal stamp
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.35),
                              child: Text(
                                _effectiveAtmosphere.titleZh,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
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
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
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
                                _effectiveAtmosphere.sealBadgeZh,
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
