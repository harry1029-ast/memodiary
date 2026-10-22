import 'package:flutter/material.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/cinnabar_seal_badge.dart';

/// Modal bottom sheet presenting a traditional thread-bound notebook gallery (*册集*).
/// Allows switching between notebooks or creating a new volume.
class NotebookSelectorSheet extends StatefulWidget {
  final AppDatabase database;
  final String currentNotebookId;
  final ValueChanged<Notebook> onNotebookSelected;

  const NotebookSelectorSheet({
    super.key,
    required this.database,
    required this.currentNotebookId,
    required this.onNotebookSelected,
  });

  /// Displays the notebook selector bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required AppDatabase database,
    required String currentNotebookId,
    required ValueChanged<Notebook> onNotebookSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => NotebookSelectorSheet(
        database: database,
        currentNotebookId: currentNotebookId,
        onNotebookSelected: onNotebookSelected,
      ),
    );
  }

  @override
  State<NotebookSelectorSheet> createState() => _NotebookSelectorSheetState();
}

class _NotebookSelectorSheetState extends State<NotebookSelectorSheet> {
  List<Notebook> _notebooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotebooks();
  }

  Future<void> _loadNotebooks() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.database.getAllNotebooks();
      if (mounted) {
        setState(() {
          _notebooks = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCreateNotebook() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添置新卷 · 题签'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '卷名 (例如：浮生微澜、秋水烹茶)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('落款'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final id = 'nb_${DateTime.now().millisecondsSinceEpoch}';
      await widget.database.createNotebook(
        NotebooksCompanion.insert(
          id: id,
          title: name,
          defaultTemplateId: 'template_default',
        ),
      );
      await _loadNotebooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.xuanGround,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: tokens.deckleBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '册集',
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontNotoSerif,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: tokens.jiaomo,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'VOLUMES & SCROLLS',
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontNotoSerif,
                                fontSize: 10,
                                letterSpacing: 1.5,
                                color: tokens.danmo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '「纸寿千年，墨润万境。随心录下微澜日常。」',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontLiterata,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: tokens.danmo,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded),
                      tooltip: '添置新卷',
                      style: IconButton.styleFrom(
                        backgroundColor: tokens.agedFiber,
                        foregroundColor: tokens.jiaomo,
                      ),
                      onPressed: _handleCreateNotebook,
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Notebook Bookshelf Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _notebooks.isEmpty
                        ? Center(
                            child: Text(
                              '暂无册卷',
                              style: TextStyle(color: tokens.danmo),
                            ),
                          )
                        : GridView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: _notebooks.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _notebooks.length) {
                                return _buildAddNotebookCard(tokens);
                              }
                              final notebook = _notebooks[index];
                              final isSelected =
                                  notebook.id == widget.currentNotebookId;
                              return _buildNotebookCover(
                                notebook: notebook,
                                isSelected: isSelected,
                                tokens: tokens,
                                index: index,
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotebookCover({
    required Notebook notebook,
    required bool isSelected,
    required InkDiaryTokens tokens,
    required int index,
  }) {
    // Variations of classical book cover tones (Indigo, Jade, Sandalwood, Pine)
    const coverColors = [
      Color(0xFF1E2832), // Indigo cloth
      Color(0xFF2C3830), // Dark jade
      Color(0xFF382C22), // Sandalwood
      Color(0xFF2E2428), // Mulberry
    ];
    final coverBg = coverColors[index % coverColors.length];

    return GestureDetector(
      onTap: () {
        widget.onNotebookSelected(notebook);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: coverBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? tokens.cinnabar : tokens.deckleBorder.withValues(alpha: 0.3),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Traditional thread binding holes along the left edge
            Positioned(
              left: 8,
              top: 12,
              bottom: 12,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (i) {
                  return Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  );
                }),
              ),
            ),

            // Vertical white silk thread line
            Positioned(
              left: 10,
              top: 12,
              bottom: 12,
              child: Container(
                width: 1,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),

            // Traditional paper title slip (*Tiqian* 题签)
            Positioned(
              left: 28,
              top: 14,
              child: Container(
                width: 32,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: tokens.xuanPureLeaf.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Text(
                  notebook.title,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tokens.jiaomo,
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Selected checkmark or seal
            if (isSelected)
              Positioned(
                right: 8,
                bottom: 8,
                child: CinnabarSealBadge.compact(
                  text: '当卷',
                  size: 24,
                  isWashVariant: false,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNotebookCard(InkDiaryTokens tokens) {
    return GestureDetector(
      onTap: _handleCreateNotebook,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.xuanPureLeaf.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tokens.deckleBorder,
            width: 1.0,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 32, color: tokens.danmo),
            const SizedBox(height: 8),
            Text(
              '添置新卷',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: tokens.danmo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
