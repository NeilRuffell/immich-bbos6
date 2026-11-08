import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:immich_ui/immich_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/enums.dart';
import 'package:immich_mobile/domain/models/album/album.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/theme_extensions.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/models/albums/album_search.model.dart';
import 'package:immich_mobile/presentation/widgets/album/album_tile.dart';
import 'package:immich_mobile/presentation/widgets/album/new_album_name_modal.widget.dart';
import 'package:immich_mobile/presentation/widgets/images/thumbnail.widget.dart';
import 'package:immich_mobile/providers/album/album_sort_by_options.provider.dart';
import 'package:immich_mobile/providers/asset_viewer/asset_viewer.provider.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/settings.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';
import 'package:immich_mobile/providers/user.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/utils/album_filter.utils.dart';
import 'package:immich_mobile/widgets/common/confirm_dialog.dart';
import 'package:immich_mobile/widgets/common/immich_toast.dart';
import 'package:sliver_tools/sliver_tools.dart';

typedef AlbumSelectorCallback = void Function(RemoteAlbum album);

// Explicit mapping keeps the pane order independent of enum declaration order.
const _albumPaneFilters = [
  QuickFilterMode.all,
  QuickFilterMode.sharedWithMe,
  QuickFilterMode.myAlbums,
];

class AlbumSelector extends ConsumerStatefulWidget {
  final AlbumSelectorCallback onAlbumSelected;
  final Function? onKeyboardExpanded;

  const AlbumSelector({super.key, required this.onAlbumSelected, this.onKeyboardExpanded});

  @override
  ConsumerState<AlbumSelector> createState() => AlbumSelectorState();
}

class AlbumSelectorState extends ConsumerState<AlbumSelector> {
  bool isGrid = false;
  final searchController = TextEditingController();
  final menuController = MenuController();
  final searchFocusNode = FocusNode();
  final _firstAlbumFocusNode = FocusNode(debugLabel: 'First album in active pane');
  bool _searchVisible = false;

  bool get isSearchVisible => _searchVisible;
  bool get isSearchInputFocused => searchFocusNode.hasFocus;

  /// Reveals the existing search input after a physical key is typed.
  /// The controller's existing listeners still perform filtering.
  void beginSearchWith(String characters) {
    if (characters.isEmpty) {
      return;
    }
    if (!_searchVisible) {
      setState(() => _searchVisible = true);
    }
    final text = searchController.text + characters;
    searchController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _searchVisible) {
        searchFocusNode.requestFocus();
      }
    });
  }

  void dismissSearch() {
    if (!_searchVisible) {
      return;
    }
    searchFocusNode.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
    clearSearch();
    setState(() => _searchVisible = false);
  }

  List<RemoteAlbum> sortedAlbums = [];
  List<RemoteAlbum> shownAlbums = [];

  AlbumFilter filter = const AlbumFilter(query: "", mode: QuickFilterMode.all);
  AlbumSort sort = const AlbumSort(mode: AlbumSortMode.lastModified, isReverse: true);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final albumConfig = ref.read(appConfigProvider).album;

      setState(() {
        sort = AlbumSort(mode: albumConfig.sortMode, isReverse: albumConfig.isReverse);
        isGrid = albumConfig.isGrid;
      });

      unawaited(ref.read(remoteAlbumProvider.notifier).refresh());
    });

    searchController.addListener(() {
      onSearch(searchController.text, filter.mode);
    });

    searchFocusNode.addListener(() {
      if (searchFocusNode.hasFocus) {
        widget.onKeyboardExpanded?.call();
      }
    });
  }

  void onSearch(String searchTerm, QuickFilterMode filterMode) {
    final userId = ref.read(currentUserProvider)?.id;
    filter = filter.copyWith(query: searchTerm, userId: userId, mode: filterMode);

    unawaited(filterAlbums());
  }

  void toggleViewMode() {
    setState(() {
      isGrid = !isGrid;
    });
    unawaited(ref.read(settingsProvider).write(.albumIsGrid, isGrid));
  }

  void changeFilter(QuickFilterMode mode) {
    setState(() {
      filter = filter.copyWith(
        mode: mode,
        query: searchController.text,
        userId: ref.read(currentUserProvider)?.id,
      );
    });

    unawaited(filterAlbums());
  }

  Future<void> changeSort(AlbumSort sort) async {
    setState(() {
      this.sort = sort;
    });

    final metadata = ref.read(settingsProvider);
    await metadata.write(.albumSortMode, sort.mode);
    await metadata.write(.albumIsReverse, sort.isReverse);

    await sortAlbums();
  }

  void clearSearch() {
    setState(() {
      filter = filter.copyWith(mode: QuickFilterMode.all, query: null);
      searchController.clear();
    });

    unawaited(filterAlbums());
  }

  Future<void> sortAlbums() async {
    final sorted = await ref
        .read(remoteAlbumProvider.notifier)
        .sortAlbums(ref.read(remoteAlbumProvider).albums, sort.mode, isReverse: sort.isReverse);

    if (!mounted) {
      return;
    }

    setState(() {
      sortedAlbums = sorted;
    });

    // we need to re-filter the albums after sorting
    // so shownAlbums gets updated
    unawaited(filterAlbums());
  }

  Future<void> filterAlbums() async {
    if (filter.query == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        shownAlbums = sortedAlbums;
      });

      return;
    }

    final filteredAlbums = ref
        .read(remoteAlbumProvider.notifier)
        .searchAlbums(sortedAlbums, filter.query!, filter.userId, filter.mode);

    if (!mounted) {
      return;
    }

    setState(() {
      shownAlbums = filteredAlbums;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    _firstAlbumFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider.select((user) => user?.id));

    // refilter and sort when albums change
    ref.listen(remoteAlbumProvider.select((state) => state.albums), (_, _) async {
      await sortAlbums();
    });

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        menuController.close();
      },
      child: MultiSliver(
        pushPinnedChildren: true,
        children: [
          // Stay visible above the album list while scrolling, as a BBOS6
          // pane selector. Existing Immich filtering remains the data source.
          SliverPersistentHeader(
            pinned: true,
            delegate: _AlbumPaneHeaderDelegate(
              child: PaneManager(
                panes: [
                  PaneManagerItem(label: context.t.all),
                  const PaneManagerItem(label: 'Shared'),
                  PaneManagerItem(label: context.t.my_albums),
                ],
                selectedIndex: _albumPaneFilters.indexOf(filter.mode),
                onSelected: (index) => changeFilter(_albumPaneFilters[index]),
                contentFocusNode: _firstAlbumFocusNode,
                autofocus: true,
              ),
            ),
          ),
          if (_searchVisible)
            _SearchBar(
              searchController: searchController,
              searchFocusNode: searchFocusNode,
              onSearch: onSearch,
              filterMode: filter.mode,
              onClearSearch: dismissSearch,
            ),
          _QuickSortAndViewMode(
            isGrid: isGrid,
            onToggleViewMode: toggleViewMode,
            onSortChanged: changeSort,
            controller: menuController,
            currentSortMode: sort.mode,
            currentIsReverse: sort.isReverse,
          ),
          isGrid
              ? _AlbumGrid(
                  albums: shownAlbums,
                  userId: userId,
                  onAlbumSelected: widget.onAlbumSelected,
                  firstItemFocusNode: _firstAlbumFocusNode,
                )
              : _AlbumList(
                  albums: shownAlbums,
                  userId: userId,
                  onAlbumSelected: widget.onAlbumSelected,
                  firstItemFocusNode: _firstAlbumFocusNode,
                ),
        ],
      ),
    );
  }
}

class _SortButton extends ConsumerStatefulWidget {
  const _SortButton(
    this.onSortChanged, {
    required this.initialSortMode,
    required this.initialIsReverse,
    this.controller,
  });

  final Future<void> Function(AlbumSort) onSortChanged;
  final MenuController? controller;
  final AlbumSortMode initialSortMode;
  final bool initialIsReverse;

  @override
  ConsumerState<_SortButton> createState() => _SortButtonState();
}

class _SortButtonState extends ConsumerState<_SortButton> {
  late AlbumSortMode albumSortOption;
  late bool albumSortIsReverse;
  bool isSorting = false;

  @override
  void initState() {
    super.initState();
    albumSortOption = widget.initialSortMode;
    albumSortIsReverse = widget.initialIsReverse;
  }

  @override
  void didUpdateWidget(_SortButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSortMode != widget.initialSortMode || oldWidget.initialIsReverse != widget.initialIsReverse) {
      setState(() {
        albumSortOption = widget.initialSortMode;
        albumSortIsReverse = widget.initialIsReverse;
      });
    }
  }

  Future<void> onMenuTapped(AlbumSortMode sortMode) async {
    final selected = albumSortOption == sortMode;
    // Switch direction
    if (selected) {
      setState(() {
        albumSortIsReverse = !albumSortIsReverse;
        isSorting = true;
      });
    } else {
      setState(() {
        albumSortOption = sortMode;
        isSorting = true;
        // reset sort order to default state when switching option
        albumSortIsReverse = false;
      });
    }

    await widget.onSortChanged.call(AlbumSort(mode: albumSortOption, isReverse: albumSortIsReverse));

    setState(() {
      isSorting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOrder = albumSortOption.effectiveOrder(albumSortIsReverse);
    return MenuAnchor(
      controller: widget.controller,
      style: MenuStyle(
        elevation: const WidgetStatePropertyAll(1),
        shape: WidgetStateProperty.all(
          const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
      ),
      consumeOutsideTap: true,
      menuChildren: AlbumSortMode.values
          .map(
            (sortMode) => MenuItemButton(
              leadingIcon: albumSortOption == sortMode
                  ? effectiveOrder == SortOrder.desc
                        ? Icon(
                            Icons.keyboard_arrow_down,
                            color: albumSortOption == sortMode
                                ? context.colorScheme.onPrimary
                                : context.colorScheme.onSurface,
                          )
                        : Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: albumSortOption == sortMode
                                ? context.colorScheme.onPrimary
                                : context.colorScheme.onSurface,
                          )
                  : const Icon(Icons.abc, color: Colors.transparent),
              onPressed: () => onMenuTapped(sortMode),
              style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.fromLTRB(12, 12, 24, 12)),
                backgroundColor: WidgetStateProperty.all(
                  albumSortOption == sortMode ? context.colorScheme.primary : Colors.transparent,
                ),
                shape: WidgetStateProperty.all(
                  const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              child: Text(
                sortMode.label(context.t),
                style: context.textTheme.labelLarge?.copyWith(
                  color: albumSortOption == sortMode
                      ? context.colorScheme.onPrimary
                      : context.colorScheme.onSurface.withAlpha(185),
                ),
              ),
            ),
          )
          .toList(),
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: effectiveOrder == SortOrder.desc
                    ? Icon(Icons.keyboard_arrow_down, color: context.colorScheme.onSurface)
                    : Icon(Icons.keyboard_arrow_up_rounded, color: context.colorScheme.onSurface),
              ),
              Text(
                albumSortOption.label(context.t),
                style: context.textTheme.labelLarge?.copyWith(color: context.colorScheme.onSurface.withAlpha(225)),
              ),
              isSorting
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colorScheme.onSurface.withAlpha(225),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearch,
    required this.filterMode,
    required this.onClearSearch,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final void Function(String, QuickFilterMode) onSearch;
  final QuickFilterMode filterMode;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Bbos6SearchBar(
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF6B7074), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                onChanged: (text) => onSearch(text, filterMode),
                onTapOutside: (_) => searchFocusNode.unfocus(
                  disposition: UnfocusDisposition.previouslyFocusedChild,
                ),
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: Color(0xFF24272B), fontSize: 16),
                cursorColor: const Color(0xFF24272B),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: context.t.search_albums,
                  hintStyle: const TextStyle(color: Color(0xFFB6B7BB)),
                ),
              ),
            ),
            IconButton(
              tooltip: context.t.cancel,
              icon: const Icon(Icons.close, color: Color(0xFF4E555B), size: 20),
              onPressed: onClearSearch,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumPaneHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _AlbumPaneHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => PaneManager.height;

  @override
  double get maxExtent => PaneManager.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(color: Colors.black, child: child);
  }

  @override
  bool shouldRebuild(covariant _AlbumPaneHeaderDelegate oldDelegate) => true;
}

class _QuickSortAndViewMode extends StatelessWidget {
  const _QuickSortAndViewMode({
    required this.isGrid,
    required this.onToggleViewMode,
    required this.onSortChanged,
    required this.currentSortMode,
    required this.currentIsReverse,
    this.controller,
  });

  final bool isGrid;
  final VoidCallback onToggleViewMode;
  final MenuController? controller;
  final Future<void> Function(AlbumSort) onSortChanged;
  final AlbumSortMode currentSortMode;
  final bool currentIsReverse;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SortButton(
              onSortChanged,
              controller: controller,
              initialSortMode: currentSortMode,
              initialIsReverse: currentIsReverse,
            ),
            IconButton(
              icon: Icon(
                isGrid ? Icons.view_list_outlined : Icons.grid_view_outlined,
                size: 24,
                color: context.colorScheme.onSurface,
              ),
              onPressed: onToggleViewMode,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumList extends ConsumerWidget {
  const _AlbumList({
    required this.albums,
    required this.userId,
    required this.onAlbumSelected,
    required this.firstItemFocusNode,
  });

  final List<RemoteAlbum> albums;
  final String? userId;
  final AlbumSelectorCallback onAlbumSelected;
  final FocusNode firstItemFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (albums.isEmpty) {
      return SliverToBoxAdapter(
        child: Focus(
          focusNode: firstItemFocusNode,
          child: Center(
            child: Padding(padding: const EdgeInsets.all(20.0), child: Text(context.t.album_search_not_found)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 64),
      sliver: SliverList.builder(
        itemBuilder: (_, index) {
          final album = albums[index];
          final isOwner = album.ownerId == userId;

          if (isOwner) {
            return Dismissible(
              key: ValueKey(album.id),
              background: Container(
                  color: context.colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(Icons.delete, color: context.colorScheme.onError),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) {
                  return showDialog<bool>(
                    context: context,
                    builder: (context) => ConfirmDialog(
                      onOk: () => true,
                      title: context.t.delete_album,
                      content: context.t.album_delete_confirmation(album: album.name),
                      ok: context.t.delete,
                    ),
                  );
                },
                onDismissed: (direction) async {
                  await ref.read(remoteAlbumProvider.notifier).deleteAlbum(album.id);
                },
              child: AlbumTile(
                album: album,
                isOwner: isOwner,
                onAlbumSelected: onAlbumSelected,
                focusNode: index == 0 ? firstItemFocusNode : null,
              ),
            );
          } else {
            return AlbumTile(
              album: album,
              isOwner: isOwner,
              onAlbumSelected: onAlbumSelected,
              focusNode: index == 0 ? firstItemFocusNode : null,
            );
          }
        },
        itemCount: albums.length,
      ),
    );
  }
}

class _AlbumGrid extends StatelessWidget {
  const _AlbumGrid({
    required this.albums,
    required this.userId,
    required this.onAlbumSelected,
    required this.firstItemFocusNode,
  });

  final List<RemoteAlbum> albums;
  final String? userId;
  final AlbumSelectorCallback onAlbumSelected;
  final FocusNode firstItemFocusNode;

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return SliverToBoxAdapter(
        child: Focus(
          focusNode: firstItemFocusNode,
          child: Center(
            child: Padding(padding: const EdgeInsets.all(20.0), child: Text(context.t.album_search_not_found)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 250,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: .7,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final album = albums[index];
          return _GridAlbumCard(
            album: album,
            userId: userId,
            onAlbumSelected: onAlbumSelected,
            focusNode: index == 0 ? firstItemFocusNode : null,
          );
        }, childCount: albums.length),
      ),
    );
  }
}

class _GridAlbumCard extends ConsumerWidget {
  const _GridAlbumCard({required this.album, required this.userId, required this.onAlbumSelected, this.focusNode});

  final RemoteAlbum album;
  final String? userId;
  final AlbumSelectorCallback onAlbumSelected;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumThumbnailAsset = ref.watch(assetServiceProvider).getRemoteAsset(album.thumbnailAssetId ?? "");

    return InkWell(
      focusNode: focusNode,
      onTap: () => onAlbumSelected(album),
      child: Card(
        elevation: 0,
        color: context.colorScheme.surfaceBright,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: context.colorScheme.onSurface.withAlpha(25), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: SizedBox(
                  width: double.infinity,
                  child: FutureBuilder(
                    future: albumThumbnailAsset,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Thumbnail.remote(
                          remoteId: album.thumbnailAssetId!,
                          thumbhash: snapshot.data!.thumbHash ?? "",
                        );
                      }

                      return ColoredBox(
                        color: context.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.photo_album_rounded, size: 40, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      album.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${context.t.items_count(count: album.assetCount)} • ${album.ownerId != userId ? context.t.shared_by_user(user: album.ownerName) : context.t.owned}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelMedium?.copyWith(color: context.colorScheme.onSurfaceSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddToAlbumHeader extends ConsumerWidget {
  const AddToAlbumHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> onCreateAlbum() async {
      final albumName = await showDialog<String?>(context: context, builder: (context) => const NewAlbumNameModal());
      if (albumName == null || !context.mounted) {
        return;
      }

      final selectedAssets = ref.read(multiSelectProvider).selectedAssets;
      final newAlbum = await ref
          .read(remoteAlbumProvider.notifier)
          .createAlbumWithAssets(title: albumName, assets: selectedAssets);

      if (!context.mounted) {
        return;
      }

      if (newAlbum == null) {
        ImmichToast.show(context: context, toastType: ToastType.error, msg: context.t.errors.failed_to_create_album);
        return;
      }

      ref.read(multiSelectProvider.notifier).reset();
      unawaited(context.pushRoute(RemoteAlbumRoute(album: newAlbum)));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.t.add_to_album, style: context.textTheme.titleSmall),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // remove internal padding
                minimumSize: Size.zero, // allow shrinking
                tapTargetSize: MaterialTapTargetSize.shrinkWrap, // remove extra height
              ),
              onPressed: onCreateAlbum,
              icon: Icon(Icons.add, color: context.primaryColor),
              label: Text(
                context.t.common_create_new_album,
                style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateAlbumButton extends ConsumerWidget {
  const CreateAlbumButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> onCreateAlbum() async {
      final albumName = await showDialog<String?>(context: context, builder: (context) => const NewAlbumNameModal());
      if (albumName == null || !context.mounted) {
        return;
      }

      final asset = ref.read(assetViewerProvider).currentAsset;

      if (asset == null) {
        ImmichToast.show(context: context, msg: "Cannot load asset information.", toastType: ToastType.error);
        return;
      }

      final album = await ref
          .read(remoteAlbumProvider.notifier)
          .createAlbum(title: albumName, assetIds: [asset.remoteId!]);

      if (!context.mounted) {
        return;
      }

      if (album == null) {
        ImmichToast.show(context: context, toastType: ToastType.error, msg: context.t.errors.failed_to_create_album);
        return;
      }

      ImmichToast.show(
        context: context,
        msg: context.t.add_to_album_bottom_sheet_added(album: album.name),
      );

      // Invalidate using the asset's remote ID to refresh the "Appears in" list
      ref.invalidate(albumsContainingAssetProvider(asset.remoteId!));

      ContextHelper(context).pop();
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.t.add_to_album, style: context.textTheme.titleSmall),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onCreateAlbum,
              icon: Icon(Icons.add, color: context.primaryColor),
              label: Text(
                context.t.common_create_new_album,
                style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
