/// Value object describing a media attachment row to insert into `media_attachments`.
class MediaAttachmentDraft {
  final String id;
  final String relativePath;
  final String mediaType;
  final String? thumbnailPath;

  const MediaAttachmentDraft({
    required this.id,
    required this.relativePath,
    this.mediaType = 'image',
    this.thumbnailPath,
  });
}
