import 'package:flutter/material.dart';
import '../models/thought_spark.dart';
import '../services/thought_spark_service.dart';

/// Dismissible micro-prompt banner providing inspirational reflection cues
class ThoughtSparkBanner extends StatefulWidget {
  final ThoughtSparkService sparkService;
  final ValueChanged<String> onInsertPrompt;
  final VoidCallback onDismiss;

  const ThoughtSparkBanner({
    super.key,
    required this.sparkService,
    required this.onInsertPrompt,
    required this.onDismiss,
  });

  @override
  State<ThoughtSparkBanner> createState() => _ThoughtSparkBannerState();
}

class _ThoughtSparkBannerState extends State<ThoughtSparkBanner> {
  late ThoughtSpark _spark;

  @override
  void initState() {
    super.initState();
    _spark = widget.sparkService.getRandomSpark();
  }

  void _shuffle() {
    setState(() {
      _spark = widget.sparkService.nextSpark();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Warm amber tint
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 20, color: Color(0xFFF57F17)),
              const SizedBox(width: 8),
              const Text(
                'Thought Spark · 灵感火花',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF57F17),
                ),
              ),
              const Spacer(),
              // Shuffle button
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.refresh, color: Colors.grey),
                tooltip: 'Next prompt',
                onPressed: _shuffle,
              ),
              const SizedBox(width: 12),
              // Dismiss button
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.grey),
                tooltip: 'Dismiss',
                onPressed: widget.onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _spark.localizedPrompt,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF3E2723),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                foregroundColor: const Color(0xFFE65100),
              ),
              icon: const Icon(Icons.add_comment_outlined, size: 16),
              label: const Text('Use Prompt', style: TextStyle(fontSize: 12)),
              onPressed: () => widget.onInsertPrompt(_spark.localizedPrompt),
            ),
          ),
        ],
      ),
    );
  }
}

