/// Centralized UI copy and strings for Travel Memory Album Studio.
abstract final class AlbumStudioStrings {
  static const String collectionBoxTitle = '收集箱 · Collection Box';
  static const String collectionBoxDockTab = 'Collection';
  static const String collectionBoxBadge = '放入本页';
  static const String collectionBoxSlotTooltip = '移至收集箱';
  static const String collectionBoxDrawerSub =
      '点击或拖拽照片即可排入当前书页，版式将自动适配 (N → N+1)';

  static const String addBlankPageButton = '+ 增加书页';
  static const String endpaperLabel = '卷尾留白 · Endpaper';
  static const String coverLabel = '封面 · Cover';
  static const String pagePrefix = 'Page';
  static const String pendingAddPrefix = '待添加 · Page';

  static String pageFullNotice(int maxPhotos) =>
      '当前书页照片已满 (最多$maxPhotos张)，请翻至其他页面或新增书页';

  static String overviewHeaderCount(int pageCount, int collectionCount) =>
      '共 $pageCount 页 · 收集箱 $collectionCount 张';
}

