import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/media_sandbox_service.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../models/album_studio_models.dart';
import '../../services/page_layout_catalog.dart';
import '../interactive_canvas/album_page_canvas.dart';

/// Studio bottom drawer rendering a 2-column grid of live mini-previews of the
/// current page's actual photos in candidate [PageLayoutTemplate]s.
///
/// Enforces Watchpoint 2 guard: `AlbumPageCanvas(isInteractive: false)` strictly
/// resolves `_thumb.webp` with `cacheWidth: 240` to avoid GPU memory spikes.
class LayoutPickerDrawer extends StatefulWidget {
  final AlbumPageModel page;
  final Map<String, AlbumPhoto> photoById;
  final MediaSandboxService mediaService;
  final ValueChanged<String> onSelectLayout;
  final VoidCallback onClose;

  const LayoutPickerDrawer({
    super.key,
    required this.page,
    required this.photoById,
    required this.mediaService,
    required this.onSelectLayout,
    required this.onClose,
  });

  @override
  State<LayoutPickerDrawer> createState() => _LayoutPickerDrawerState();
}

class _LayoutPickerDrawerState extends State<LayoutPickerDrawer> {
  int? _filterPhotoCount; // null = current page photo count, 0 = all templates

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final currentCount = widget.page.photoSlots.isEmpty
        ? 1
        : widget.page.photoSlots.length.clamp(
            PageLayoutCatalog.minPhotosPerPage,
            PageLayoutCatalog.maxPhotosPerPage,
          );
    final effectiveFilter = _filterPhotoCount ?? currentCount;
    final templates = effectiveFilter == 0
        ? PageLayoutCatalog.allTemplates
        : PageLayoutCatalog.templatesForPhotoCount(effectiveFilter);

    return Container(
      key: const Key('studio_layout_picker_drawer'),
      height: 330,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: tokens.xuanPureLeaf,
        border: Border(
          top: BorderSide(color: tokens.deckleBorder, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                size: 18,
                color: tokens.cinnabar,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '拼图版式库 · Collage Layouts',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tokens.jiaomo,
                  ),
                ),
              ),
              IconButton(
                key: const Key('close_layout_drawer_button'),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.expand_more, color: tokens.danmo),
                tooltip: '收起面板',
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Filter bar by photo count
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  tokens: tokens,
                  label: '本页推荐 ($currentCount 张)',
                  isSelected: _filterPhotoCount == null,
                  chipKey: const Key('layout_filter_recommended'),
                  onTap: () => setState(() => _filterPhotoCount = null),
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  tokens: tokens,
                  label: '全部版式',
                  isSelected: _filterPhotoCount == 0,
                  chipKey: const Key('layout_filter_all'),
                  onTap: () => setState(() => _filterPhotoCount = 0),
                ),
                for (var count = 1; count <= 6; count++) ...[
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    tokens: tokens,
                    label: '$count 图',
                    isSelected: _filterPhotoCount == count,
                    chipKey: Key('layout_filter_count_$count'),
                    onTap: () => setState(() => _filterPhotoCount = count),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 2-Column Live Mini-Previews Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                final isSelected =
                    widget.page.layoutTemplateId == template.id;

                return InkWell(
                  key: Key('layout_option_${template.id}'),
                  onTap: () => widget.onSelectLayout(template.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: tokens.agedFiber,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isSelected ? tokens.cinnabar : tokens.deckleBorder,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: AlbumPageCanvas(
                                  page: widget.page,
                                  overrideLayoutTemplateId: template.id,
                                  photoById: widget.photoById,
                                  mediaService: widget.mediaService,
                                  isInteractive: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? tokens.cinnabarWash
                                : tokens.xuanPureLeaf,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(6),
                            ),
                          ),
                          child: Text(
                            template.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontNotoSerif,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color:
                                  isSelected ? tokens.cinnabar : tokens.nongmo,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required InkDiaryTokens tokens,
    required String label,
    required bool isSelected,
    required Key chipKey,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      key: chipKey,
      label: Text(
        label,
        style: TextStyle(
          fontFamily: InkDiaryTheme.fontNotoSerif,
          fontSize: 11.5,
          color: isSelected ? tokens.cinnabar : tokens.danmo,
        ),
      ),
      selected: isSelected,
      selectedColor: tokens.cinnabarWash,
      backgroundColor: tokens.agedFiber,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onTap(),
    );
  }
}

