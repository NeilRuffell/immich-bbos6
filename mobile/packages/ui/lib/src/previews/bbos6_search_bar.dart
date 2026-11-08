import 'package:flutter/material.dart';
import 'package:immich_ui/src/components/bbos6/bbos6_search_bar.dart';
import 'package:immich_ui/src/previews.dart';

@ImmichPreview(group: 'BBOS6', name: 'Search bar')
Widget previewBbos6SearchBar() => const SizedBox(
  width: 340,
  child: Bbos6SearchBar(
    child: Row(
      children: [
        Icon(Icons.search, color: Color(0xFF6B7074), size: 20),
        SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Search albums',
              hintStyle: TextStyle(color: Color(0xFFB6B7BB)),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(color: Color(0xFF24272B), fontSize: 16),
          ),
        ),
      ],
    ),
  ),
);
