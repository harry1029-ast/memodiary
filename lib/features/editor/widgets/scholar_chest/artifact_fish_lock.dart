import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/ink_diary_theme.dart';

/// Stationery artifact representing the ancient brass carp padlock (古法鱼锁).
/// Controls the diary Time Capsule (岁月锦囊) lock and sealing dates.
class ArtifactFishLock extends StatelessWidget {
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  const ArtifactFishLock({
    super.key,
    this.isSelected = false,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '古法鱼锁: 设定岁月锦囊时光胶囊封缄之期',
      selected: isSelected,
      child: GestureDetector(
        key: const Key('chest_artifact_fish_lock'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6B1A1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF8B262A),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.35 : 0.2),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Brass fish padlock graphic
              SizedBox(
                height: 42,
                width: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Brass Shackle
                    Positioned(
                      top: 4,
                      child: Container(
                        width: 22,
                        height: 18,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 2.2,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        ),
                      ),
                    ),
                    // Fish-shaped lock body
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: 48,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC49838),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE8C872), width: 1.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isLocked ? Icons.lock : Icons.lock_open,
                            size: 11,
                            color: const Color(0xFF2C1E0A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Plaque
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A17),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                ),
                child: Text(
                  '古法鱼锁',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontKaiti,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE6C875),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// In-chest sub-panel for the Brass Fish Lock artifact
class FishLockSubPanel extends StatelessWidget {
  final DateTime? unlockAt;
  final ValueChanged<DateTime?> onLockChanged;

  const FishLockSubPanel({
    super.key,
    this.unlockAt,
    required this.onLockChanged,
  });

  bool get isLocked => unlockAt != null && unlockAt!.isAfter(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '岁月锦囊 · 封缄之期',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
            if (isLocked)
              TextButton.icon(
                key: const Key('chest_lock_clear_button'),
                style: TextButton.styleFrom(
                  foregroundColor: tokens.cinnabar,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.lock_open, size: 14),
                label: const Text('解除封缄', style: TextStyle(fontSize: 12)),
                onPressed: () => onLockChanged(null),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Current lock status banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isLocked ? tokens.cinnabar.withValues(alpha: 0.08) : tokens.ricePaper,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLocked ? tokens.cinnabar.withValues(alpha: 0.4) : tokens.agedFiber,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isLocked ? Icons.lock : Icons.lock_outline,
                size: 16,
                color: isLocked ? tokens.cinnabar : tokens.danmo,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isLocked
                      ? '已封缄至 ${DateFormat('yyyy年M月d日').format(unlockAt!)} 解封'
                      : '当前未封缄 · 随笔随览',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontKaiti,
                    fontSize: 12,
                    color: isLocked ? tokens.cinnabar : tokens.danmo,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Quick Presets
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              key: const Key('chest_lock_preset_1month'),
              label: const Text('封缄一月 (+30天)'),
              backgroundColor: tokens.ricePaper,
              labelStyle: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 12,
                color: tokens.jiaomo,
              ),
              onPressed: () {
                onLockChanged(now.add(const Duration(days: 30)));
              },
            ),
            ActionChip(
              key: const Key('chest_lock_preset_newyear'),
              label: const Text('封至元旦'),
              backgroundColor: tokens.ricePaper,
              labelStyle: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 12,
                color: tokens.jiaomo,
              ),
              onPressed: () {
                final nextYear = DateTime(now.year + 1, 1, 1);
                onLockChanged(nextYear);
              },
            ),
            ActionChip(
              key: const Key('chest_lock_preset_1year'),
              label: const Text('封缄一年 (+365天)'),
              backgroundColor: tokens.ricePaper,
              labelStyle: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 12,
                color: tokens.jiaomo,
              ),
              onPressed: () {
                onLockChanged(now.add(const Duration(days: 365)));
              },
            ),
            ActionChip(
              key: const Key('chest_lock_preset_custom'),
              avatar: Icon(Icons.calendar_month, size: 14, color: tokens.cinnabar),
              label: const Text('自选吉日'),
              backgroundColor: tokens.ricePaper,
              labelStyle: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 12,
                color: tokens.cinnabar,
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now.add(const Duration(days: 7)),
                  firstDate: now.add(const Duration(days: 1)),
                  lastDate: now.add(const Duration(days: 365 * 10)),
                );
                if (picked != null) {
                  onLockChanged(picked);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
