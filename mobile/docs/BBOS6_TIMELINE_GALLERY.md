# BBOS6 shared Timeline Gallery

## Scope

The Pictures Library is the first consumer of `Bbos6GalleryView`, enabled by
`Timeline(bbosGallery: true)`. Other timelines retain stock behavior unless they
explicitly opt into this shared presentation component.

The reusable controls live in
`mobile/packages/ui/lib/src/components/bbos6/bbos6_gallery_view.dart`:

- `Bbos6GalleryView` presents an existing scrollable/sliver gallery with a
  persistent 56dp footer and handles keyboard/trackpad directions and activation.
- `Bbos6GridNavigationController` stores the selected asset index and navigates
  actual row boundaries, including partial rows at date-group transitions.
- `Bbos6GalleryItem` adds a focus highlight to a supplied thumbnail without
  changing its image loading or tap/long-press behavior.

Consumers pass the row groups, column count, an existing scrollable, reveal and
activation callbacks, and a footer content builder. The shared component has no
dependency on `BaseAsset`, Riverpod, Immich routes, EXIF or any database/API.

## Pictures Library integration

`MainTimelinePage` enables the helper. `Timeline` continues to create the
existing `CustomScrollView`, `SliverSegmentedList`, `FixedSegment` and
`ThumbnailTile` widgets, including existing date headers, virtualization,
selection, pinch zoom, scrubber, viewer and asset-loading logic.

The presentation adapter computes the scroll offset for a focused asset using
its existing `Segment` geometry. It opens that asset using the same
`activateTimelineAsset` action as touchscreen taps. Left/Right navigate to
adjacent assets; Up/Down follow the previous/next rendered row, preserving
column where possible. Enter, numpad Enter and Select activate the highlighted
asset. Touching a thumbnail updates the displayed date and retains the
existing thumbnail gesture.

## Persistent date/time footer

`Bbos6TimelineDateFooter` is a presentation-only adapter. For the selected
asset it uses the existing buffered `TimelineService.getAssetAsync` and
`assetExifProvider` to read the cached EXIF metadata, then calls the existing
`resolveAssetDateTime(asset, exif)` function.

The existing resolver chooses:

1. `ExifInfo.dateTimeOriginal` with EXIF timezone where available.
2. `BaseAsset.createdAt.toLocal()` if no original date is available.

Do not invent a third timestamp fallback, query a new API, parse original
media directly, or change timezone handling in the shared component. For
local-only assets, the existing EXIF provider returns null and `createdAt`
provides the display date. The footer honors the platform 12/24-hour setting.
It displays a placeholder when no asset or timestamp record is available.

## Verification

- Run `mise //mobile:checkout` after switching to the feature branch.
- Test the shared controller and widget in
  `mobile/packages/ui/test/bbos6_gallery_view_test.dart`.
- On the Q25, verify initial highlight, all four directions, date-group
  boundaries, scroll-to-focus at both viewport edges, Enter, Back from viewer,
  touchscreen tap and long-press, and selection mode.
- Verify local-only images and server-backed images with and without EXIF dates,
  plus device and EXIF timezone differences.
- Verify other Timeline consumers are unchanged when `bbosGallery` is false.

Changes are restricted to Flutter presentation, shared UI and documentation.
No backend, API, synchronization, asset models, repositories or database code
is modified.
