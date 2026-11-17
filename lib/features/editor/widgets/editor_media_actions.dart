import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/media_sandbox_types.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../controllers/editor_media_binding.dart';
import '../services/editor_pagination_coordinator.dart';

/// Thin UI source-sheet and [ImagePicker] adapter forwarding picked media into
/// [EditorMediaBinding] and rendering capacity/error SnackBars.
class EditorMediaActions {
  const EditorMediaActions._();

  static void _showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
  }

  /// Refuses a collect with "待选区已满 15 项" when the Staging Handscroll is full.
  static bool _refuseWhenHandscrollFull(
    BuildContext context,
    EditorPaginationCoordinator coordinator,
  ) {
    if (coordinator.handscrollRoom > 0) return false;
    _showSnackBar(
      context,
      '待选区已满 ${EditorPaginationCoordinator.kHandscrollCapacity} 项',
    );
    return true;
  }

  static Future<ImageSource?> _pickMediaSource(
    BuildContext context, {
    required IconData cameraIcon,
    required String cameraLabel,
    required IconData galleryIcon,
    required String galleryLabel,
  }) {
    final tokens = InkDiaryTheme.tokensOf(context);
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: tokens.xuanGround,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(cameraIcon, size: 20, color: tokens.jiaomo),
              title: Text(
                cameraLabel,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  color: tokens.jiaomo,
                ),
              ),
              onTap: () => Navigator.pop(modalContext, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(galleryIcon, size: 20, color: tokens.jiaomo),
              title: Text(
                galleryLabel,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  color: tokens.jiaomo,
                ),
              ),
              onTap: () => Navigator.pop(modalContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  /// Prompts the user to take one photo or pick several from the gallery and
  /// delegates sandboxing, persistence, and staging to [binding].
  static Future<void> handleImagePick({
    required BuildContext context,
    required ImagePicker imagePicker,
    required EditorMediaBinding binding,
  }) async {
    if (_refuseWhenHandscrollFull(context, binding.coordinator)) return;

    final source = await _pickMediaSource(
      context,
      cameraIcon: Icons.camera_alt_outlined,
      cameraLabel: '拍照',
      galleryIcon: Icons.photo_library_outlined,
      galleryLabel: '从相册选择照片',
    );
    if (source == null || !context.mounted) return;

    try {
      final List<XFile> picks;
      if (source == ImageSource.gallery) {
        picks = await imagePicker.pickMultiImage();
      } else {
        final photo = await imagePicker.pickImage(source: source);
        picks = [if (photo != null) photo];
      }
      if (picks.isEmpty) return;

      final outcome = await binding.collectImages(picks);
      if (!context.mounted) return;
      if (outcome.wasFull) {
        _showSnackBar(
          context,
          '待选区已满 ${EditorPaginationCoordinator.kHandscrollCapacity} 项',
        );
      } else if (outcome.hasRejected) {
        _showSnackBar(
          context,
          '待选区已满 ${EditorPaginationCoordinator.kHandscrollCapacity} 项，${outcome.rejectedByCapacity} 项未添加',
        );
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(context, '插入照片失败：$error');
      }
    }
  }

  /// Prompts the user to pick or record a video (<= 60s) and delegates
  /// sandboxing, persistence, and staging to [binding].
  static Future<void> handleVideoPick({
    required BuildContext context,
    required ImagePicker imagePicker,
    required EditorMediaBinding binding,
  }) async {
    if (_refuseWhenHandscrollFull(context, binding.coordinator)) return;

    final source = await _pickMediaSource(
      context,
      cameraIcon: Icons.videocam_outlined,
      cameraLabel: '录制视频（≤60秒）',
      galleryIcon: Icons.video_library_outlined,
      galleryLabel: '从相册选择视频（≤60秒）',
    );
    if (source == null || !context.mounted) return;

    try {
      final picked = await imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );
      if (picked == null) return;

      final outcome = await binding.collectVideo(picked);
      if (context.mounted && outcome.wasFull) {
        _showSnackBar(
          context,
          '待选区已满 ${EditorPaginationCoordinator.kHandscrollCapacity} 项',
        );
      }
    } on VideoDurationExceededException catch (error) {
      if (context.mounted) {
        _showSnackBar(
          context,
          error.message,
          backgroundColor: Colors.red.shade700,
        );
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(context, '插入视频失败：$error');
      }
    }
  }
}
