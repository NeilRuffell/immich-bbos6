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
  runs only when the selection changes. The shared `PaneManager` itself
  transfers focus to its optional `contentFocusNode` on every activation,
  including clicks on the currently selected pane.
- After an Albums pane is activated, the helper resets the containing scroll
  view to its start and transfers focus to the supplied first-row focus node
  after Flutter rebuilds the selected content. The same node is attached to the
  first list or grid item (or its empty-state placeholder). Albums provides only
  that node, not a navigation/focus callback.
  Album data, filtering, routing and sort behavior are unchanged.
- PaneManager now defines **two isolated focus scopes** using the reusable
  `PaneManagerController` and `PaneManagerContent`. Up/Down on the pane bar
  cannot enter its content; directional traversal and Tab traversal at content
  edges cannot jump back into the pane bar.
- Enter/trackpad click activates the highlighted pane and moves focus to the
  supplied content target. The first Back is handled by the shared PaneManager
  and returns to the selected pane without changing its data. Back again is
  passed to the page's existing navigation (Albums returns to Pictures home).
  Inner list/grid directional navigation works normally.
- `addPostFrameCallback` alone does not schedule a Flutter frame. The shared
  helper explicitly schedules the focus-handoff frame, including when the
  already-selected first pane is activated and `onSelected` does not rebuild
  anything. This prevents focus from remaining on the pane bar until the next
  trackpad movement. The helper's `BBOS6-PaneManager` focus trace is guarded
  by `kDebugMode` and is inactive in profile and release APKs.
- PaneManagerContent has a **debug-only** `BBOS6-PaneScroll` trace for
  investigating focus-based scrolling. It records content focus changes, the
  nearest containing Scrollable's pixel offset, and the focused render box's
  position relative to the viewport. These are observations only: no
  `ensureVisible`, scrolling or traversal behavior is modified. The observer
  is absent from profile/release widget trees (`kDebugMode` guard).
- The shared implementation handles Android Back **only** through the
  Router's BackButtonDispatcher (via BackButtonListener). Do not also move focus
  on the physical Back key event inside PaneManagerContent: one physical press
  can deliver both a keyboard event and a route-pop notification, which would
  otherwise produce two navigation steps from one press.
- Keyboard focus boundaries remain active in previews without a Router. The
  widget regression test simulates a keyboard Back event followed by the
  Router notification, and verifies one Back returns to the pane bar while a
  separate second Back reaches page navigation.
- The bar is pinned via `SliverPersistentHeader` within `MultiSliver`
  (`pushPinnedChildren: true`).

### Reuse boundary

This is a reusable **Flutter** presentation component. Android-native Java
applications in `bb-ui` cannot import Dart widgets; they may reuse its
established visual and interaction contract through a separate native renderer.

## Device verification

1. Open **Immich → Albums**: the top selector reads **All | Shared | My Albums**.
2. Confirm the album list matches the original filters for each selection.
3. Test Left/Right highlighting without switching lists. Press Up/Down while
   on the pane bar: focus must **not** enter any list or toolbar control.
4. Press trackpad: the selected pane activates and focus enters its first album
   row (or the first grid card). Up/Down navigates within that content without
   escaping back to PaneManager.
5. Press Back once: focus returns to the **selected pane**, not the previous page.
   Press Back a second time: Albums returns to Pictures home.
6. Repeat steps 3–5 with an empty album list, in Grid mode, and after opening
   then closing an individual album.
7. Scroll a long list: PaneManager stays visible under the page header.
8. Confirm Search, Grid/List, Sorting, Open Album, Create Album and delete
   confirmation remain functional. Check portrait and landscape.

Code has been committed to the feature branch. Compilation, widget-test
execution and Q25 testing must be run on a machine with Flutter installed.
