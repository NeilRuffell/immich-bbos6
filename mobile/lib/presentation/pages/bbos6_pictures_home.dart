import 'package:flutter/material.dart';
import 'package:immich_ui/immich_ui.dart';
import 'package:immich_mobile/widgets/common/immich_logo.dart';

/// BBOS6-inspired Pictures landing screen.
///
/// Navigation actions are supplied by the existing tab shell or router.
/// No Immich data or navigation state is owned by this presentation widget.
class Bbos6PicturesHome extends StatelessWidget {
  const Bbos6PicturesHome({
    required this.onPicturesLibrary,
    required this.onAlbums,
    required this.onDevice,
    required this.onMemories,
    required this.onPlaces,
    required this.onPeople,
    required this.onSettings,
    this.readonly = false,
    super.key,
  });

  final VoidCallback onPicturesLibrary;
  final VoidCallback onAlbums;
  final VoidCallback onDevice;
  final VoidCallback onMemories;
  final VoidCallback onPlaces;
  final VoidCallback onPeople;
  final VoidCallback onSettings;
  final bool readonly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 12,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ImmichLogo(size: 28),
            SizedBox(width: 8),
            Text('Immich'),
          ],
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Bbos6MediaListTile(
              title: 'Pictures Library',
              leading: const Icon(Icons.photo_library_outlined, size: 26),
              onTap: onPicturesLibrary,
              autofocus: true,
            ),
            Bbos6MediaListTile(
              title: 'Albums',
              leading: const Icon(Icons.photo_album_outlined, size: 26),
              onTap: readonly ? null : onAlbums,
            ),
            Bbos6MediaListTile(
              title: 'On Device',
              leading: const Icon(Icons.phone_android_outlined, size: 26),
              onTap: readonly ? null : onDevice,
            ),
            Bbos6MediaListTile(
              title: 'Memories',
              leading: const Icon(Icons.auto_awesome_outlined, size: 26),
              onTap: readonly ? null : onMemories,
            ),
            Bbos6MediaListTile(
              title: 'Places',
              leading: const Icon(Icons.place_outlined, size: 26),
              onTap: readonly ? null : onPlaces,
            ),
            Bbos6MediaListTile(
              title: 'People',
              leading: const Icon(Icons.people_outline, size: 26),
              onTap: readonly ? null : onPeople,
            ),
            Bbos6MediaListTile(
              title: 'Settings',
              leading: const Icon(Icons.settings_outlined, size: 26),
              onTap: onSettings,
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }
}
