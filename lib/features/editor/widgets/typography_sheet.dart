import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/ink_switch.dart';
import '../models/typography_settings.dart';

/// Modal bottom sheet allowing users to adjust display font family, size, line spacing,
/// and classical paragraph indentation in Ink & Paper aesthetic.
class TypographySheet extends StatefulWidget {
  final TypographySettings settings;
  final ValueChanged<TypographySettings> onChanged;

  const TypographySheet({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  static Future<void> show({
    required BuildContext context,
    required TypographySettings settings,
    required ValueChanged<TypographySettings> onChanged,
  }) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.xuanGround,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) => TypographySheet(
        settings: settings,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<TypographySheet> createState() => _TypographySheetState();
}

class _TypographySheetState extends State<TypographySheet> {
  late TypographySettings _current;
  bool _indentFirstLine = true;

  @override
  void initState() {
    super.initState();
    _current = widget.settings;
  }

  void _update(TypographySettings updated) {
    setState(() {
      _current = updated;
    });
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Indicator
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.danmo.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3.5,
                            height: 18,
                            decoration: BoxDecoration(
                              color: tokens.cinnabar,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Typography Settings',
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontNotoSerif,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: tokens.jiaomo,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            ' · ',
                            style: TextStyle(color: tokens.danmo),
                          ),
                          Text(
                            '字法排印',
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontKaiti,
                              fontSize: 14,
                              color: tokens.nongmo,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '定制案头抚卷与落墨之版式规制 (100% 离线文骨字库)',
                        style: TextStyle(
                          fontSize: 11,
                          color: tokens.danmo,
                        ),
                      ),
                    ],
                  ),
                ),
                // Traditional Seal Stamp
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: tokens.cinnabarWash,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tokens.cinnabar, width: 1),
                  ),
                  child: Text(
                    '墨記\n雅藏',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tokens.cinnabar,
                      height: 1.1,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Font Family Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Font Family',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: tokens.jiaomo,
                  ),
                ),
                Text(
                  '体式字骨 · 离线字库',
                  style: TextStyle(fontSize: 11, color: tokens.danmo),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Horizontal Font Cards
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: TypographyCatalog.options.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final option = TypographyCatalog.options[index];
                  final isSelected = option.id == _current.fontId;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _update(_current.copyWith(
                        fontId: option.id,
                        fontFamily: option.fontFamily,
                      ));
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? tokens.jiaomo : tokens.ricePaper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? tokens.jiaomo : tokens.agedFiber,
                          width: 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: tokens.jiaomo.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isSelected)
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: tokens.cinnabar,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: tokens.danmo.withValues(alpha: 0.5)),
                                  ),
                                ),
                              Text(
                                'Aa',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: option.fontFamily,
                                  color: isSelected ? tokens.xuanGround : tokens.danmo,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            option.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: option.fontFamily,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? tokens.xuanGround : tokens.jiaomo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Font Size Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Font Size',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: tokens.jiaomo,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokens.cinnabarWash,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tokens.cinnabar.withValues(alpha: 0.25),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '${_current.fontSize.toInt()} 级 · 笔触大小',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tokens.cinnabar,
                    ),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: tokens.cinnabar,
                inactiveTrackColor: tokens.agedFiber,
                thumbColor: tokens.cinnabar,
                trackHeight: 3.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: _current.fontSize,
                min: 13.0,
                max: 24.0,
                divisions: 11,
                label: '${_current.fontSize.toInt()}',
                onChanged: (val) {
                  _update(_current.copyWith(fontSize: val));
                },
              ),
            ),
            const SizedBox(height: 8),

            // Line Spacing Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Line Spacing',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: tokens.jiaomo,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokens.cinnabarWash,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tokens.cinnabar.withValues(alpha: 0.25),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '${_current.lineSpacing.toStringAsFixed(2)} 倍 · 疏密得宜',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tokens.cinnabar,
                    ),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: tokens.cinnabar,
                inactiveTrackColor: tokens.agedFiber,
                thumbColor: tokens.cinnabar,
                trackHeight: 3.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: _current.lineSpacing,
                min: 1.2,
                max: 2.4,
                divisions: 12,
                label: _current.lineSpacing.toStringAsFixed(2),
                onChanged: (val) {
                  _update(_current.copyWith(lineSpacing: val));
                },
              ),
            ),
            const SizedBox(height: 10),

            // Indent Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.ricePaper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.agedFiber),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '段首留白 · 双格空缩',
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.jiaomo,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '遵循汉字经典两格缩进规度',
                        style: TextStyle(
                          fontSize: 11,
                          color: tokens.danmo,
                        ),
                      ),
                    ],
                  ),
                  InkSwitch(
                    value: _indentFirstLine,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _indentFirstLine = val;
                      });
                    },
                    semanticLabel: '段首留白双格空缩',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
