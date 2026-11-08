import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/constants.dart';
import 'package:immich_mobile/domain/models/events.model.dart';
import 'package:immich_mobile/domain/utils/event_stream.dart';
import 'package:immich_mobile/presentation/pages/bbos6_pictures_home.dart';
import 'package:immich_mobile/presentation/pages/search/paginated_search.provider.dart';
import 'package:immich_mobile/providers/haptic_feedback.provider.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/memory.provider.dart';
import 'package:immich_mobile/providers/infrastructure/readonly_mode.provider.dart';
import 'package:immich_mobile/providers/search/search_input_focus.provider.dart';
import 'package:immich_mobile/providers/tab.provider.dart';
import 'package:immich_mobile/routing/router.dart';

@RoutePage()
class TabShellPage extends ConsumerStatefulWidget {
  const TabShellPage({super.key});

  @override
  ConsumerState<TabShellPage> createState() => _TabShellPageState();
}

class _TabShellPageState extends ConsumerState<TabShellPage> {
  bool _showPicturesHome = true;

  void _openTab(TabsRouter tabsRouter, int index) {
    _onNavigationSelected(tabsRouter, index, ref);
    setState(() => _showPicturesHome = false);
  }

  void _returnHome(TabsRouter tabsRouter) {
    // Keep the original tab routes available to deep links and existing
    // navigation while returning the visible shell to the new Pictures menu.
    tabsRouter.setActiveIndex(kPhotoTabIndex);
    ref.read(tabProvider.notifier).state = TabEnum.home;
    setState(() => _showPicturesHome = true);
  }

  @override
  Widget build(BuildContext context) {
    final isReadonlyModeEnabled = ref.watch(readonlyModeProvider);

    // The existing tab router stays intact for Immich's internal navigation.
    // Only the former tab bar/rail is replaced by the BBOS6 home screen.
    return AutoTabsRouter(
      routes: const [MainTimelineRoute(), SearchRoute(), AlbumsRoute(), LibraryRoute()],
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (context, child, animation) => FadeTransition(opacity: animation, child: child),
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        return PopScope(
          canPop: _showPicturesHome,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !_showPicturesHome) {
              _returnHome(tabsRouter);
            }
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: _showPicturesHome
                ? Bbos6PicturesHome(
                    readonly: isReadonlyModeEnabled,
                    onPicturesLibrary: () => _openTab(tabsRouter, kPhotoTabIndex),
                    onAlbums: () => _openTab(tabsRouter, kAlbumTabIndex),
                    onDevice: () => context.pushRoute(const LocalAlbumsRoute()),
                    onMemories: () => context.pushRoute(const MemoryListRoute()),
                    onPlaces: () => context.pushRoute(PlaceRoute(currentLocation: null)),
                    onPeople: () => context.pushRoute(const PeopleCollectionRoute()),
                  )
                : child,
          ),
        );
      },
    );
  }
}

void _onNavigationSelected(TabsRouter router, int index, WidgetRef ref) {
  // On Photos page menu tapped
  if (router.activeIndex == kPhotoTabIndex && index == kPhotoTabIndex) {
    EventStream.shared.emit(const ScrollToTopEvent());
  }

  if (index == kPhotoTabIndex) {
    ref.invalidate(memoryLaneProvider);
  }

  if (router.activeIndex != kSearchTabIndex && index == kSearchTabIndex) {
    ref.read(searchPreFilterProvider.notifier).clear();
  }

  // On Search page tapped
  if (router.activeIndex == kSearchTabIndex && index == kSearchTabIndex) {
    ref.read(searchInputFocusProvider).requestFocus();
  }

  // Album page
  if (index == kAlbumTabIndex) {
    unawaited(ref.read(remoteAlbumProvider.notifier).refresh());
  }

  ref.read(hapticFeedbackProvider.notifier).selectionClick();
  router.setActiveIndex(index);
  ref.read(tabProvider.notifier).state = TabEnum.values[index];
}
