# BBOS6 shared Timeline Gallery

## Scope

The Pictures Library is the first consumer of `Bbos6GalleryView`, enabled by
`Timeline(bbosGallery: true)`. Other timelines retain stock behavior unless they
explicitly opt into this shared presentation component.

Reusable controls live in
`mobile/packages/ui/lib/src/components/bbos6/bbos6_gallery_view.dart`:

- `Bbos6GalleryView` wraps the existing scrollable/sliver gallery and handles
  keyboard/trackpad directional navigation and activation.
- `Bbos6GridNavigationController` stores the selected thumbnail index and
  navigates existing row boundaries, including partial rows at date changes.
- `Bbos6GalleryItem` adds a focus highlight to a supplied thumbnail without
  changing Immich image loading, thumbnail tap or long-press behavior.

Consumers pass section item counts, the column count, an existing scrollable,
reveal and activation callbacks. The shared control has no dependency on
`BaseAsset`, Riverpod, Immich routes, EXIF or a database/API.

## Pictures Library integration

`MainTimelinePage` enables the helper. `Timeline` still creates the original
`CustomScrollView`, `SliverSegmentedList`, `FixedSegment`,
`TimelineHeader` and `ThumbnailTile` widgets. Date/day/month header rows
and their existing group-selection checkboxes are retained. Date bucket
grouping, virtualized scrolling, pinch zoom, date scrubber, photo selection,
viewer routing and asset loading are unchanged.

The presentation adapter computes the scroll offset for a focused asset using
existing `Segment` geometry, and invokes the existing `activateTimelineAsset`
action for Enter. Left/Right move to adjacent thumbnails; Up/Down move by
rendered row and preserve column when possible. Enter, numpad Enter and Select
open the focused image. Touching a thumbnail updates focus and retains existing
gestures.

There is no persistent bottom date/time bar. Original in-grid date rows
identify date groups; the stock Immich date scroller remains in use.

## Verification

- Run `mise //mobile:checkout` after switching to the feature branch.
- Test shared trackpad navigation in
  `mobile/packages/ui/test/bbos6_gallery_view_test.dart`.
- On the Q25, verify date labels and group-selection checkboxes, initial
  focus highlight, all four directions, navigation across date boundaries,
  scroll-to-focus at both viewport edges, Enter, Back from viewer,
  touchscreen tap and long-press, and selection mode.
- Verify the image grid extends to its normal bottom edge without a
  persistent date/time footer.
- Verify stock date scroller behavior and other Timeline consumers.

Changes are restricted to Flutter presentation, shared UI and documentation.
No backend, API, synchronization, asset models, repositories or database code
is modified.
