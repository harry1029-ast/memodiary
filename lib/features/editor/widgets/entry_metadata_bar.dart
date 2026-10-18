import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Metadata controls for date backdating, mood, weather, and Time Capsule unlock
class EntryMetadataBar extends StatelessWidget {
  final DateTime entryDate;
  final int? mood;
  final String? weather;
  final DateTime? unlockAt;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int?> onMoodChanged;
  final ValueChanged<String?> onWeatherChanged;
  final ValueChanged<DateTime?> onUnlockAtChanged;

  const EntryMetadataBar({
    super.key,
    required this.entryDate,
    required this.mood,
    required this.weather,
    required this.unlockAt,
    required this.onDateChanged,
    required this.onMoodChanged,
    required this.onWeatherChanged,
    required this.onUnlockAtChanged,
  });

  static const List<Map<String, dynamic>> moodOptions = [
    {'value': 1, 'emoji': '😢', 'label': 'Down'},
    {'value': 2, 'emoji': '🙁', 'label': 'Tired'},
    {'value': 3, 'emoji': '😐', 'label': 'Calm'},
    {'value': 4, 'emoji': '🙂', 'label': 'Happy'},
    {'value': 5, 'emoji': '😄', 'label': 'Great'},
  ];

  static const List<Map<String, dynamic>> weatherOptions = [
    {'value': 'sunny', 'icon': Icons.wb_sunny_outlined, 'label': 'Sunny'},
    {'value': 'cloudy', 'icon': Icons.cloud_outlined, 'label': 'Cloudy'},
    {'value': 'rainy', 'icon': Icons.water_drop_outlined, 'label': 'Rainy'},
    {'value': 'windy', 'icon': Icons.air_outlined, 'label': 'Windy'},
    {'value': 'snowy', 'icon': Icons.ac_unit_outlined, 'label': 'Snowy'},
  ];

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: entryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(entryDate),
    );

    if (pickedTime != null) {
      onDateChanged(DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ));
    } else {
      onDateChanged(DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        entryDate.hour,
        entryDate.minute,
      ));
    }
  }

  void _showMoodPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Mood', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: moodOptions.map((opt) {
                  final isSelected = mood == opt['value'];
                  return GestureDetector(
                    onTap: () {
                      onMoodChanged(opt['value'] as int);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.amber.shade100 : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.amber.shade700, width: 2) : null,
                      ),
                      child: Text(opt['emoji'] as String, style: const TextStyle(fontSize: 32)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeatherPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Weather', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: weatherOptions.map((opt) {
                  final isSelected = weather == opt['value'];
                  return GestureDetector(
                    onTap: () {
                      onWeatherChanged(opt['value'] as String);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade100 : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.blue.shade700, width: 2) : null,
                      ),
                      child: Icon(opt['icon'] as IconData, size: 28, color: Colors.blueGrey),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTimeCapsule(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      helpText: 'Select Time Capsule Unlock Date',
      initialDate: unlockAt ?? now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(2050),
    );

    if (pickedDate != null) {
      HapticFeedback.lightImpact();
      onUnlockAtChanged(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final formattedDate = dateFormat.format(entryDate);

    final currentMoodOpt = moodOptions.cast<Map<String, dynamic>?>().firstWhere(
          (m) => m?['value'] == mood,
          orElse: () => null,
        );

    final currentWeatherOpt = weatherOptions.cast<Map<String, dynamic>?>().firstWhere(
          (w) => w?['value'] == weather,
          orElse: () => null,
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Date & Time Chip
          ActionChip(
            avatar: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(formattedDate, style: const TextStyle(fontSize: 12)),
            onPressed: () => _pickDate(context),
            backgroundColor: Colors.grey.shade100,
          ),
          const SizedBox(width: 8),

          // Mood Chip
          ActionChip(
            avatar: Text(
              currentMoodOpt != null ? (currentMoodOpt['emoji'] as String) : '🙂',
              style: const TextStyle(fontSize: 14),
            ),
            label: Text(
              currentMoodOpt != null ? (currentMoodOpt['label'] as String) : 'Mood',
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => _showMoodPicker(context),
            backgroundColor: Colors.grey.shade100,
          ),
          const SizedBox(width: 8),

          // Weather Chip
          ActionChip(
            avatar: Icon(
              currentWeatherOpt != null ? (currentWeatherOpt['icon'] as IconData) : Icons.wb_sunny_outlined,
              size: 16,
              color: Colors.blueGrey,
            ),
            label: Text(
              currentWeatherOpt != null ? (currentWeatherOpt['label'] as String) : 'Weather',
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => _showWeatherPicker(context),
            backgroundColor: Colors.grey.shade100,
          ),
          const SizedBox(width: 8),

          // Time Capsule Chip
          ActionChip(
            avatar: Icon(
              unlockAt != null ? Icons.lock_clock : Icons.hourglass_empty,
              size: 16,
              color: unlockAt != null ? Colors.purple : Colors.grey,
            ),
            label: Text(
              unlockAt != null ? 'Unlocks ${DateFormat('MM-dd').format(unlockAt!)}' : 'Time Capsule',
              style: TextStyle(
                fontSize: 12,
                color: unlockAt != null ? Colors.purple : Colors.black87,
              ),
            ),
            onPressed: () => _pickTimeCapsule(context),
            backgroundColor: unlockAt != null ? Colors.purple.shade50 : Colors.grey.shade100,
          ),
        ],
      ),
    );
  }
}

