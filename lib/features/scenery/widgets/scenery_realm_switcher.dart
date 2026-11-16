import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../models/shanshui_atmosphere.dart';
import '../services/scenery_settings_service.dart';

/// Interactive **Scenery Realm** (`画卷境域`) pill badge displayed on both the
/// expanded `Shanshui Scenery Card` window and the `44dp` collapsed bamboo bar.
class SceneryRealmBadge extends StatelessWidget {
  final ShanshuiAtmosphereState atmosphere;
  final InkDiaryTokens tokens;
  final bool isCollapsed;
  final VoidCallback onTap;

  const SceneryRealmBadge({
    super.key,
    required this.atmosphere,
    required this.tokens,
    required this.onTap,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '切换画卷境域: ${atmosphere.realmBadgeZh}',
      child: InkWell(
        key: const Key('scenery_realm_badge'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: isCollapsed ? const Color(0x8C000000) : const Color(0x991E1A17),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: atmosphere.isJournalInferred
                  ? tokens.cinnabar.withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showInferredDot =
                  atmosphere.isJournalInferred && constraints.maxWidth >= 24;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showInferredDot) ...[
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
                      style: const TextStyle(
                        color: Color(0xFFF7F4EB),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

const List<({
  SceneryRealmPreference preference,
  String keyName,
  String title,
  String subtitle,
})> _realmOptionConfigs = [
  (
    preference: SceneryRealmPreference.auto,
    keyName: 'scenery_realm_option_auto',
    title: 'Auto (随文入境)',
    subtitle: '根据近24小时日记内容自适应意境',
  ),
  (
    preference: SceneryRealmPreference.nature,
    keyName: 'scenery_realm_option_nature',
    title: 'Nature (林泉)',
    subtitle: '水墨山水 · 烟波浩渺',
  ),
  (
    preference: SceneryRealmPreference.indoor,
    keyName: 'scenery_realm_option_indoor',
    title: 'Indoor (雅室)',
    subtitle: '书房茶室 · 烹茶伴读',
  ),
  (
    preference: SceneryRealmPreference.outdoor,
    keyName: 'scenery_realm_option_outdoor',
    title: 'Outdoor (市井)',
    subtitle: '古镇街市 · 烟火人间',
  ),
];

/// Presents the 1-tap modal bottom sheet allowing the diarist to switch between
/// `Auto (随文入境)`, `Nature (林泉)`, `Indoor (雅室)`, and `Outdoor (市井)`.
Future<void> showSceneryRealmSwitcherSheet({
  required BuildContext context,
  required InkDiaryTokens tokens,
  required ScenerySettingsService settingsService,
  required ValueChanged<SceneryRealmPreference> onSelected,
}) async {
  final currentPref = await settingsService.getRealmPreference();
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
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
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
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: tokens.danmo,
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  Text(
                    '随文入境根据近作自动切换，亦可手动锁定画卷境域',
                    style: TextStyle(fontSize: 11, color: tokens.danmo),
                  ),
                  const SizedBox(height: 12),
                  ..._realmOptionConfigs.map(
                    (option) => _RealmOptionTile(
                      key: Key(option.keyName),
                      tokens: tokens,
                      preference: option.preference,
                      title: option.title,
                      subtitle: option.subtitle,
                      isSelected: currentPref == option.preference,
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await settingsService.setRealmPreference(
                          option.preference,
                        );
                        onSelected(option.preference);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _RealmOptionTile extends StatelessWidget {
  final InkDiaryTokens tokens;
  final SceneryRealmPreference preference;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RealmOptionTile({
    super.key,
    required this.tokens,
    required this.preference,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '选择 $title',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tokens.agedFiber,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            preference.icon,
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
        onTap: onTap,
      ),
    );
  }
}
