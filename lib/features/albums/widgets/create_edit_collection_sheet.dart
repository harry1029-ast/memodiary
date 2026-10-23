import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/ink_diary_theme.dart';

/// Typed value object returned when [CreateEditCollectionSheet] is submitted.
class CollectionFormResult {
  final String title;
  final String? description;
  final String? destinationTag;
  final String? routeSummary;
  final DateTime? startDate;
  final DateTime? endDate;

  const CollectionFormResult({
    required this.title,
    this.description,
    this.destinationTag,
    this.routeSummary,
    this.startDate,
    this.endDate,
  });
}

/// Modal bottom sheet form for creating or editing an [AlbumCollection].
class CreateEditCollectionSheet extends StatefulWidget {
  final AlbumCollection? initialCollection;

  const CreateEditCollectionSheet({
    super.key,
    this.initialCollection,
  });

  /// Shows the modal sheet and returns a [CollectionFormResult] if submitted.
  static Future<CollectionFormResult?> show(
    BuildContext context, {
    AlbumCollection? initialCollection,
  }) {
    return showModalBottomSheet<CollectionFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => CreateEditCollectionSheet(
        initialCollection: initialCollection,
      ),
    );
  }

  @override
  State<CreateEditCollectionSheet> createState() =>
      _CreateEditCollectionSheetState();
}

class _CreateEditCollectionSheetState extends State<CreateEditCollectionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _destinationController;
  late final TextEditingController _routeController;
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _isEditing => widget.initialCollection != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCollection;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController =
        TextEditingController(text: initial?.description ?? '');
    _destinationController =
        TextEditingController(text: initial?.destinationTag ?? '');
    _routeController =
        TextEditingController(text: initial?.routeSummary ?? '');
    _startDate = initial?.startDate;
    _endDate = initial?.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _destinationController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange = (_startDate != null && _endDate != null)
        ? DateTimeRange(
            start: _startDate!,
            end: _endDate!.isBefore(_startDate!) ? _startDate! : _endDate!,
          )
        : null;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: initialRange,
      helpText: '选择旅途起止日期',
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final destination = _destinationController.text.trim();
    final route = _routeController.text.trim();

    Navigator.of(context).pop(
      CollectionFormResult(
        title: title,
        description: description.isEmpty ? null : description,
        destinationTag: destination.isEmpty ? null : destination,
        routeSummary: route.isEmpty ? null : route,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final fmt = DateFormat('yyyy.MM.dd');
    final hasDates = _startDate != null || _endDate != null;
    final dateText = (_startDate != null && _endDate != null)
        ? '${fmt.format(_startDate!)} – ${fmt.format(_endDate!)}'
        : (_startDate != null ? fmt.format(_startDate!) : '点击选择行程起止日期');

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? '编辑旅行影集' : '新建旅行影集',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: tokens.jiaomo,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: tokens.danmo),
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 1. Title
              TextFormField(
                key: const Key('album_form_title'),
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '影集标题 *',
                  hintText: '如：江南春行纪、川西雪山行',
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return '请输入影集标题';
                  }
                  if (trimmed.length > 100) {
                    return '标题长度不能超过 100 个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 2. Destination Tag (Seal)
              TextFormField(
                key: const Key('album_form_destination'),
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: '地域印章（选填）',
                  hintText: '如：江南、关西、川西（最多 8 字）',
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.length > 8) {
                    return '地域印章请控制在 8 个字符以内';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 3. Route Summary
              TextFormField(
                key: const Key('album_form_route'),
                controller: _routeController,
                decoration: const InputDecoration(
                  labelText: '旅途路线（选填）',
                  hintText: '如：杭州 → 乌镇 → 苏州',
                  helperText: '留空则根据照片地点自动生成',
                ),
              ),
              const SizedBox(height: 12),

              // 4. Description / Prologue
              TextFormField(
                key: const Key('album_form_description'),
                controller: _descriptionController,
                maxLines: 3,
                minLines: 2,
                decoration: const InputDecoration(
                  labelText: '卷首语 / 旅途序言（选填）',
                  hintText: '山河沿路，笔底留痕…',
                ),
              ),
              const SizedBox(height: 12),

              // 5. Travel Date Range
              InkWell(
                key: const Key('album_form_date_range'),
                borderRadius: BorderRadius.circular(8),
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.deckleBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range_outlined,
                        size: 20,
                        color: tokens.danmo,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dateText,
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 14,
                            color: hasDates ? tokens.jiaomo : tokens.qingmo,
                          ),
                        ),
                      ),
                      if (hasDates)
                        Semantics(
                          label: '清除行程日期',
                          button: true,
                          child: InkWell(
                            onTap: _clearDateRange,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.clear,
                                size: 16,
                                color: tokens.danmo,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              FilledButton(
                key: const Key('album_form_submit'),
                onPressed: _handleSubmit,
                child: Text(_isEditing ? '保存修改' : '创建影集'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

