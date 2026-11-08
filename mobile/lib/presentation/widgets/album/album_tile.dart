import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_ui/immich_ui.dart';
import 'package:immich_mobile/domain/models/album/album.model.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/widgets/images/thumbnail.widget.dart';
import 'package:immich_mobile/providers/infrastructure/asset.provider.dart';

/// Album presentation in the existing Immich Albums list.
///
/// This keeps the existing asset-thumbnail provider and selection callback;
/// only the layout is replaced by the shared BBOS6 list row.
class AlbumTile extends ConsumerWidget {
  const AlbumTile({super.key, required this.album, required this.isOwner, this.onAlbumSelected, this.focusNode});

  final RemoteAlbum album;
  final bool isOwner;
  final Function(RemoteAlbum)? onAlbumSelected;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumThumbnailAsset = ref.watch(assetServiceProvider).getRemoteAsset(album.thumbnailAssetId ?? "");

    return Bbos6MediaListTile(
      focusNode: focusNode,
      title: album.name,
      subtitle:
          '${context.t.items_count(count: album.assetCount)} • ${isOwner ? context.t.owned : context.t.shared_by_user(user: album.ownerName)}',
      onTap: () => onAlbumSelected?.call(album),
      leading: FutureBuilder(
        future: albumThumbnailAsset,
        builder: (context, snapshot) {
          return SizedBox(
            width: 52,
            height: 52,
            child: snapshot.hasData && snapshot.data != null
                ? ClipRect(
                    child: Thumbnail.remote(
                      remoteId: album.thumbnailAssetId!,
                      thumbhash: snapshot.data!.thumbHash ?? "",
                    ),
                  )
                : const ColoredBox(
                    color: Color(0xFF292C31),
                    child: Icon(Icons.photo_album_rounded, size: 26, color: Color(0xFFB6B7BB)),
                  ),
          );
        },
      ),
    );
  }
}
