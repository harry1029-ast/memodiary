/// Centralized UI copy and strings for Travel Memory Album Studio.
abstract final class AlbumStudioStrings {
  static const String collectionBoxTitle = '收集箱';
  static const String collectionBoxDockTab = '收集箱';
  static const String collectionBoxBadge = '放入本页';
  static const String collectionBoxSlotTooltip = '移至收集箱';
  static const String collectionBoxDrawerSub =
      '点击或拖拽照片即可排入当前页，版式会自动调整';

  static const String addBlankPageButton = '+ 添加一页';
  static const String endpaperLabel = '封底';
  static const String coverLabel = '封面';

  static String pageLabel(int pageNumber) => '第 $pageNumber 页';

  static String pendingAddPageLabel(int pageNumber) =>
      '待添加 · 第 $pageNumber 页';

  static String pageFullNotice(int maxPhotos) =>
      '当前页照片已满（最多 $maxPhotos 张），请翻至其他页或添加新页';

  static String overviewHeaderCount(int pageCount, int collectionCount) =>
      '共 $pageCount 页 · 收集箱 $collectionCount 张';
}

