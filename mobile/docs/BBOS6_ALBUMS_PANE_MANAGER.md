# BBOS6 Albums PaneManager

## Scope

The existing Immich **AlbumsPage** is retained. The old three rounded quick-filter buttons in
`AlbumSelector` are replaced with a shared **PaneManager** widget, pinned at the top of the
album selector while the album content scrolls.

The pane order and data mapping are:

| Pane label | Immich's existing filter |
| --- | --- |
| All | `QuickFilterMode.all` |
| Shared | `QuickFilterMode.sharedWithMe` |
| My Albums | `QuickFilterMode.myAlbums` |

No new album data source, screen, filter algorithm or route is introduced.
Album opening, search, list/grid selection, sorting, creating albums,
swipe-to-delete confirmation and provider refresh logic remain on the existing
Immich paths. The old filter buttons are removed, not left duplicated below the
new PaneManager. Search and existing sorting/view-mode UI are **not redesigned**
yet; their BBOS6 controls are a later task.

## Shared component

- Public Flutter widget: `PaneManager`
- Location: `mobile/packages/ui/lib/src/components/bbos6/pane_manager.dart`
- Re-export: `mobile/packages/ui/lib/immich_ui.dart`
- Preview: `mobile/packages/ui/lib/src/previews/bbos6_pane_manager.dart`
- Tests: `mobile/packages/ui/test/pane_manager_test.dart`

The widget receives **pane models** (label and optional icon, including icon-only display), an external **selected index**, and an **onSelected** callback. It does not know what Immich, albums, or their server are.

### BBOS6 appearance and input

- One 52dp-high horizontal bar with three equal-width text segments in Albums. The shared widget also supports icon or icon-and-label panes.
- Square edges, grayscale inactive background inspired by the BB Music chrome.
- Selected pane uses the **existing shared BBOS6 selection gradient** rather
  than a duplicate palette.
- White focus border visually distinguishes physical-input focus from the
  selected (blue-gradient) pane. Left/Right moves that focus border without
  changing the selected pane or its album results. Only trackpad click/Enter
  or touch activates the highlighted pane. The shared `onSelected` callback
  runs only when the selection changes; `onActivated` runs for every click,
  including an already-selected pane, so the parent can focus its content.
- After an Albums pane is activated, focus transfers to the first item in
  its filtered list or grid; an empty pane's status message remains focusable.
  Album data, filtering, routing and sort behavior are unchanged.
- Up/Down is not swallowed: Flutter's standard directional focus navigation is
  preserved for the other controls and album content.
- The bar is pinned via `SliverPersistentHeader` within `MultiSliver`
  (`pushPinnedChildren: true`).

### Reuse boundary

This is a reusable **Flutter** presentation component. Android-native Java
applications in `bb-ui` cannot import Dart widgets; they may reuse its
established visual and interaction contract through a separate native renderer.

## Device verification

1. Open **Immich → Albums**: the top selector reads **All | Shared | My Albums**.
2. Confirm the album list matches the original filters for each selection.
3. Test pressing Left/Right: only the white focus border moves, not the
   selected blue pane and not the album results. Press the trackpad to commit
   the highlighted pane; focus should jump into the first album row. Repeat
   by clicking the current pane and while Grid mode is enabled.
4. Scroll a long list: the pane bar should remain visible under the page header.
5. Confirm Search, Grid/List, Sorting, Open Album, Create Album and delete
   confirmation still work as before.
6. Verify Back returns to the Pictures home; check portrait and landscape.

Code has been committed to the feature branch. Compilation, widget-test
execution and Q25 testing must be run on a machine with Flutter installed.
