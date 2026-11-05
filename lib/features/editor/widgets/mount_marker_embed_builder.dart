import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../models/mount_marker.dart';

/// Renders a mount marker as nothing: zero width, zero height and invisible,
/// so anchoring a mounted item never alters the diarist's writing or rows.
class MountMarkerEmbedBuilder extends EmbedBuilder {
  const MountMarkerEmbedBuilder();

  @override
  String get key => MountMarker.embedType;

  @override
  bool get expanded => false;

  @override
  String toPlainText(Embed node) => '';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) => const SizedBox.shrink();
}
