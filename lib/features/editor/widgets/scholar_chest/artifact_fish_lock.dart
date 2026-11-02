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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6B1A1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD4AF37)
                  : const Color(0xFF8B262A),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isSelected ? 0.35 : 0.2,
                ),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                bottom: 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: (isSelected || isLocked) ? 1.0 : 0.0,
                  ),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  builder: (context, turnProgress, _) {
                    return CustomPaint(
                      painter: BrassFishLockPainter(
                        turnProgress: turnProgress,
                        isLocked: isLocked,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 4,
                right: 4,
                bottom: 2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1A17),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF8C7148),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '古法鱼锁',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontKaiti,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE6C875),
                      ),
                    ),
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

/// Renders the sculpted Antique Brass Carp Padlock (古法黄铜鱼锁) and turning key with red silk tassel.
class BrassFishLockPainter extends CustomPainter {
  final double turnProgress;
  final bool isLocked;

  BrassFishLockPainter({
    required this.turnProgress,
    required this.isLocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final canvasWidth = size.width;
    final canvasHeight = size.height;

    final brassPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF2D58B), Color(0xFFC4963C), Color(0xFF7B571A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight));

    // 1. Horizontal Brass Shackle Bolt (古法横开锁梁)
    canvas.save();
    canvas.translate(isLocked ? 0.0 : -4.0 * turnProgress, 0);
    final shacklePath = Path()
      ..moveTo(canvasWidth * 0.20, canvasHeight * 0.28)
      ..lineTo(canvasWidth * 0.82, canvasHeight * 0.28)
      ..lineTo(canvasWidth * 0.82, canvasHeight * 0.44);
    canvas.drawPath(
      shacklePath,
      Paint()
        ..color = const Color(0xFFD6AF5B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    // 2. Sculpted Auspicious Carp Body (古铜鱼锁)
    final fishPath = Path()
      ..moveTo(canvasWidth * 0.12, canvasHeight * 0.55)
      ..quadraticBezierTo(
        canvasWidth * 0.26, canvasHeight * 0.34,
        canvasWidth * 0.54, canvasHeight * 0.38,
      )
      ..quadraticBezierTo(
        canvasWidth * 0.72, canvasHeight * 0.40,
        canvasWidth * 0.84, canvasHeight * 0.30,
      )
      ..lineTo(canvasWidth * 0.80, canvasHeight * 0.55)
      ..lineTo(canvasWidth * 0.84, canvasHeight * 0.78)
      ..quadraticBezierTo(
        canvasWidth * 0.72, canvasHeight * 0.68,
        canvasWidth * 0.54, canvasHeight * 0.72,
      )
      ..quadraticBezierTo(
        canvasWidth * 0.26, canvasHeight * 0.75,
        canvasWidth * 0.12, canvasHeight * 0.55,
      )
      ..close();
    canvas.drawPath(fishPath, brassPaint);
    canvas.drawPath(
      fishPath,
      Paint()
        ..color = const Color(0xFF4A320D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // Vigilant Fish Eye ("鱼目终夜不瞑")
    canvas.drawCircle(
      Offset(canvasWidth * 0.24, canvasHeight * 0.52),
      3.0,
      Paint()..color = const Color(0xFF2A1A08),
    );
    canvas.drawCircle(
      Offset(canvasWidth * 0.24, canvasHeight * 0.52),
      1.1,
      Paint()..color = const Color(0xFFF6DE9C),
    );

    // 3. Brass Key & Crimson Tassel (rotates on lock / selection)
    final keyPivot = Offset(canvasWidth * 0.56, canvasHeight * 0.56);
    canvas.save();
    canvas.translate(keyPivot.dx, keyPivot.dy);
    canvas.rotate(0.36 * turnProgress);
    canvas.translate(-keyPivot.dx, -keyPivot.dy);

    canvas.drawCircle(
      keyPivot,
      3.8,
      Paint()..color = const Color(0xFF3E280B),
    );
    canvas.drawLine(
      keyPivot,
      Offset(canvasWidth * 0.84, canvasHeight * 0.74),
      Paint()
        ..color = const Color(0xFFE7C46E)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    // Red silk tassel
    canvas.drawLine(
      Offset(canvasWidth * 0.84, canvasHeight * 0.74),
      Offset(canvasWidth * 0.88, canvasHeight * 0.88),
      Paint()
        ..color = const Color(0xFFC82820)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BrassFishLockPainter oldDelegate) =>
      oldDelegate.turnProgress != turnProgress ||
      oldDelegate.isLocked != isLocked;
}

/// In-chest sub-panel for the Fish Lock Time Capsule controls
class FishLockSubPanel extends StatelessWidget {
  final DateTime? unlockAt;
  final ValueChanged<DateTime?> onLockChanged;

  const FishLockSubPanel({
    super.key,
    required this.unlockAt,
    required this.onLockChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = unlockAt != null && unlockAt!.isAfter(DateTime.now());
    final dateFormat = DateFormat('yyyy年MM月dd日');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isLocked ? Icons.lock : Icons.lock_open_outlined,
                  size: 16,
                  color: const Color(0xFFC04851),
                ),
                const SizedBox(width: 6),
                Text(
                  '岁月锦囊 · 封缄之期',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C1E0A),
                  ),
                ),
              ],
            ),
            if (isLocked)
              TextButton.icon(
                key: const Key('chest_lock_clear_button'),
                icon: const Icon(Icons.lock_open, size: 14),
                label: const Text('解除封缄', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC04851),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                onPressed: () => onLockChanged(null),
              ),
          ],
        ),
        const SizedBox(height: 6),

        Text(
          isLocked
              ? '已封缄至 ${dateFormat.format(unlockAt!)} 解封'
              : '当前未封缄 · 随笔随览',
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontKaiti,
            fontSize: 12,
            color: isLocked ? const Color(0xFFC04851) : const Color(0xFF7A6B5D),
          ),
        ),
        const SizedBox(height: 10),

        // Lock preset chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildLockPresetChip(
              key: const Key('chest_lock_preset_1month'),
              label: '一月后 · 待春发',
              duration: const Duration(days: 30),
            ),
            ActionChip(
              key: const Key('chest_lock_preset_newyear'),
              label: const Text('封至元旦', style: TextStyle(fontSize: 11.5)),
              backgroundColor: const Color(0xFFF7F3E8),
              onPressed: () {
                final now = DateTime.now();
                onLockChanged(DateTime(now.year + 1, 1, 1));
              },
            ),
            _buildLockPresetChip(
              key: const Key('chest_lock_preset_1year'),
              label: '翌年今日 · 见旧墨',
              duration: const Duration(days: 365),
            ),
            ActionChip(
              key: const Key('chest_lock_preset_custom'),
              avatar: const Icon(Icons.event_outlined, size: 14),
              label: const Text('自择良辰', style: TextStyle(fontSize: 11.5)),
              backgroundColor: const Color(0xFFF7F3E8),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now.add(const Duration(days: 30)),
                  firstDate: now.add(const Duration(days: 1)),
                  lastDate: now.add(const Duration(days: 3650)),
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

  Widget _buildLockPresetChip({
    required Key key,
    required String label,
    required Duration duration,
  }) {
    return ActionChip(
      key: key,
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      backgroundColor: const Color(0xFFF7F3E8),
      onPressed: () {
        onLockChanged(DateTime.now().add(duration));
      },
    );
  }
}
