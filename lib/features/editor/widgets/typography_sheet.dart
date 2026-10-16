import 'package:flutter/material.dart';
import '../models/typography_settings.dart';

/// Modal bottom sheet allowing users to adjust display font family, size, and line spacing.
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
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => TypographySheet(
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Typography Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Customize reader and editor appearance (100% offline fonts).',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Font Family Selector
            const Text(
              'Font Family',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: TypographyCatalog.options.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final opt = TypographyCatalog.options[index];
                  final isSelected = opt.id == _current.fontId;

                  return ChoiceChip(
                    label: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          opt.name,
                          style: TextStyle(
                            fontFamily: opt.fontFamily,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          'Aa 拾光',
                          style: TextStyle(
                            fontFamily: opt.fontFamily,
                            fontSize: 11,
                            color: isSelected ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _update(_current.copyWith(
                          fontId: opt.id,
                          fontFamily: opt.fontFamily,
                        ));
                      }
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Font Size Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Font Size',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_current.fontSize.toInt()} sp',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            Slider(
              value: _current.fontSize,
              min: 13.0,
              max: 24.0,
              divisions: 11,
              label: '${_current.fontSize.toInt()}',
              onChanged: (val) {
                _update(_current.copyWith(fontSize: val));
              },
            ),

            // Line Spacing Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Line Spacing',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  _current.lineSpacing.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            Slider(
              value: _current.lineSpacing,
              min: 1.2,
              max: 2.2,
              divisions: 10,
              label: _current.lineSpacing.toStringAsFixed(1),
              onChanged: (val) {
                _update(_current.copyWith(lineSpacing: val));
              },
            ),
          ],
        ),
      ),
    );
  }
}

