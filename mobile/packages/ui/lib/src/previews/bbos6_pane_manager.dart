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
        labels: const ['All', 'Shared', 'My Albums'],
        selectedIndex: selected,
        onSelected: (index) => setState(() => selected = index),
      ),
    ),
  );
}
