import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';

/// Shows a diarist confirmation dialog for deleting a user-defined custom template.
Future<bool?> showTemplateDeleteDialog(
  BuildContext context,
  Template template,
) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('删除自定义信纸'),
      content: Text(
        '确定删除「${template.name}」？使用该信纸的日记将自动恢复为默认信纸，正文内容不会丢失。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('取消'),
        ),
        FilledButton.tonal(
          key: const Key('confirm_delete_custom_template_button'),
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(
            foregroundColor: Colors.red.shade700,
          ),
          child: const Text('删除'),
        ),
      ],
    ),
  );
}
