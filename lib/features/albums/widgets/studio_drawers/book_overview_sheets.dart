import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../services/album_studio_controller.dart';
import '../../services/page_layout_catalog.dart';

/// Shows the `+ Add` bottom sheet for [AlbumBookOverviewScreen], allowing the
/// diarist to append a blank page or import additional photos into the session.
void showBookOverviewAddSheet({
  required BuildContext context,
  required AlbumStudioController controller,
  VoidCallback? onImportMorePhotos,
}) {
  final tokens = context.inkTokens;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: tokens.xuanPureLeaf,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('overview_add_blank_page'),
                leading: Icon(
                  Icons.note_add_outlined,
                  size: 22,
                  color: tokens.cinnabar,
                ),
                title: Text(
                  '添加空白页',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontWeight: FontWeight.w600,
                    color: tokens.jiaomo,
                  ),
                ),
                subtitle: Text(
                  '在画册末尾添加一页空白页，自由排版照片和贴纸',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 12,
                    color: tokens.danmo,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  controller.addBlankPage();
                },
              ),
              if (onImportMorePhotos != null)
                ListTile(
                  key: const Key('overview_import_photos'),
                  leading: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 22,
                    color: tokens.nongmo,
                  ),
                  title: Text(
                    '导入更多照片',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontWeight: FontWeight.w600,
                      color: tokens.jiaomo,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onImportMorePhotos();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows the `Arrange` bottom sheet for reordering or removing pages in
/// [AlbumBookOverviewScreen], listening reactively to [controller].
void showBookOverviewArrangeSheet({
  required BuildContext context,
  required AlbumStudioController controller,
}) {
  final tokens = context.inkTokens;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: tokens.xuanPureLeaf,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) {
      return ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final pages = controller.pages;
          return SizedBox(
            key: const Key('book_overview_arrange_sheet'),
            height: MediaQuery.of(context).size.height * 0.65,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.swap_vert, color: tokens.cinnabar, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '调整页面顺序',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: tokens.jiaomo,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: tokens.danmo,
                        ),
                        tooltip: '关闭',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: pages.length,
                      onReorderItem: (oldIndex, newIndex) {
                        controller.reorderPages(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        final layoutName =
                            PageLayoutCatalog.getById(page.layoutTemplateId)
                                .name;
                        return ListTile(
                          key: ValueKey('arrange_page_${page.id}'),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: tokens.agedFiber,
                            child: Text(
                              '${page.pageNumber}',
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontNotoSerif,
                                fontSize: 12,
                                color: tokens.jiaomo,
                              ),
                            ),
                          ),
                          title: Text(
                            '第 ${page.pageNumber} 页 (${page.photoSlots.length} 张照片)',
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontNotoSerif,
                              fontSize: 14,
                              color: tokens.jiaomo,
                            ),
                          ),
                          subtitle: Text(
                            '版式：$layoutName',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: tokens.danmo,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (pages.length > 1)
                                IconButton(
                                  key: Key('arrange_delete_page_$index'),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 19,
                                    color: tokens.cinnabar,
                                  ),
                                  tooltip: '删除此页（照片将移回收集箱）',
                                  onPressed: () =>
                                      controller.removePage(page.id),
                                ),
                              Icon(
                                Icons.drag_handle,
                                size: 20,
                                color: tokens.qingmo,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
