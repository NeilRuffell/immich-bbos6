import 'package:flutter/material.dart';
import 'package:immich_ui/src/components/bbos6/bbos6_media_list_tile.dart';
import 'package:immich_ui/src/previews.dart';

void _previewNoop() {}

@ImmichPreview(group: 'BBOS6', name: 'Media list rows')
Widget previewBbos6MediaListRows() => const SizedBox(
  width: 340,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Bbos6MediaListTile(
        leading: Icon(Icons.folder_outlined, size: 26),
        title: 'Folders',
        onTap: _previewNoop,
      ),
      Bbos6MediaListTile(
        leading: Icon(Icons.lock_outline_rounded, size: 26),
        title: 'Locked Folder',
        onTap: _previewNoop,
      ),
      Bbos6MediaListTile(
        leading: Icon(Icons.group_outlined, size: 26),
        title: 'Partners',
        showDivider: false,
        onTap: _previewNoop,
      ),
    ],
  ),
);
