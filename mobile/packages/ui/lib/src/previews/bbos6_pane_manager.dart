import 'package:flutter/material.dart';
import 'package:immich_ui/src/components/bbos6/pane_manager.dart';
import 'package:immich_ui/src/previews.dart';

@ImmichPreview(group: 'BBOS6', name: 'Pane manager')
Widget previewBbos6PaneManager() {
  var selected = 0;
  return StatefulBuilder(
    builder: (context, setState) => SizedBox(
      width: 340,
      child: PaneManager(
        panes: const [
          PaneManagerItem(label: 'All'),
          PaneManagerItem(label: 'Shared'),
          PaneManagerItem(label: 'My Albums'),
        ],
        selectedIndex: selected,
        onSelected: (index) => setState(() => selected = index),
      ),
    ),
  );
}

@ImmichPreview(group: 'BBOS6', name: 'Pane manager icon-only')
Widget previewBbos6IconPanes() => SizedBox(
  width: 340,
  child: PaneManager(
    panes: const [
      PaneManagerItem(label: 'Camera', icon: Icon(Icons.camera_alt_outlined), showLabel: false),
      PaneManagerItem(label: 'Gallery', icon: Icon(Icons.photo_library_outlined), showLabel: false),
      PaneManagerItem(label: 'Settings', icon: Icon(Icons.settings_outlined), showLabel: false),
    ],
    selectedIndex: 0,
    onSelected: (_) {},
  ),
);
