# BBOS6 shared Timeline Gallery

## Scope

Pictures Library and opened server albums use `Bbos6GalleryView`, enabled by
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

## Opened server albums

`RemoteAlbumPage` opts into the same shared gallery via
`Timeline(bbosGallery: true)`. Its existing `timelineFactoryProvider.remoteAlbum`
asset source, `RemoteAlbumSliverAppBar`, pending uploads banner, album
permissions and actions, selection flow, viewer, and
`RemoteAlbumBottomSheet` remain unchanged. BBOS6 navigation, thumbnail
highlighting, and compact date-row layout are inherited from the shared
timeline/gallery components rather than reimplemented in this page.
Local album galleries and all other Timeline consumers remain unchanged.

The shared `RemoteAlbumSliverAppBar` removes its former animated album
cover background and uses a solid dark surface. Instead of the stock fixed
400dp expanded header, it calculates the expanded height from its compact
album-title text (up to three lines), date range and item count, optional
scrollable description (up to 44dp), and shared-user icon row. The pinned
toolbar remains independently accessible for Back, slideshow, activity,
and album options. Title and description editing, date metadata, item count,
and shared-user controls are unchanged.

The height calculation belongs to the existing album-header component, not
a one-off `RemoteAlbumPage` wrapper. Regression coverage:
`test/presentation/widgets/remote_album/compact_server_album_header_test.dart`.

Because the server-album page contains a dynamic app bar and an upload banner,
Q25 verification should include focus scrolling at both edges of the image
viewport, Enter and Back, long titles and descriptions, shared-user rows,
and navigation when a pending-upload banner is visible.

### Compact BBOS6 date rows

The shared gallery uses the presentation-only `compactTimelineDateHeadersProvider`
to request compact date-row extents from `FixedSegmentBuilder` and
`TimelineHeader`. The shared header layout remains responsible for the
date text and existing date-group selection control.

| Header | Stock height | BBOS6 gallery height |
| --- | ---: | ---: |
| Day | 72dp | 52dp |
| Month | 80dp | 52dp |
| Month and day | 128dp | 72dp |

The compact combined month/day header presents the month and date as a
two-line text stack with a **2dp line gap** and compact (1.05) line height.
Its 48dp date-group selection control is separately positioned on the right,
aligned with the date line rather than occupying a second text row. The
combined height is **72dp**, preserving the checkbox touch target without
padding out both labels to 48dp each.

The single-date rows remain 52dp. The header heights and text gap are
centralized in `timeline/constants.dart`, and the virtualized segment
geometry uses the same extents. Other Timeline consumers retain stock header
dimensions and behavior. Do not change underlying bucket grouping, image
source, the stock date scrubber, or selection callbacks.

## Verification

- Run `mise //mobile:checkout` after switching to the feature branch.
- Test shared trackpad navigation in
  `mobile/packages/ui/test/bbos6_gallery_view_test.dart`.
- On the Q25, verify date labels and group-selection checkboxes, initial
  focus highlight, all four directions, navigation across date boundaries,
  scroll-to-focus at both viewport edges, Enter, Back from viewer,
  touchscreen tap and long-press, and selection mode.
- Verify compact date labels and checkboxes are not clipped, and focus
  scrolling and the scrubber align correctly after crossing month/day headers.
- Run `mobile/test/presentation/widgets/timeline/bbos6_date_header_overflow_test.dart`
  to check compact month/day, month-only, and day-only headers at 360dp
  width with 120% text scaling and the full 48dp selection control.
- Verify the image grid extends to its normal bottom edge without a
  persistent date/time footer.
- Verify stock date scroller behavior and other Timeline consumers.

Changes are restricted to Flutter presentation, shared UI and documentation.
No backend, API, synchronization, asset models, repositories or database code
is modified.
