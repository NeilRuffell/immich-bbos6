# Library quick-access rows — BBOS6 presentation pilot

## Scope

The first BBOS6 user-facing change applies the reusable `Bbos6MediaListTile` to the **Library** screen's quick-access list only:

- Folders
- Locked Folder
- Partners
- Partner photos entries (when available)

**Not changed:** The Library header, main navigation tabs, action-button grid, collection cards, photo timeline, viewer, routes, providers, backup/sync or server functions.

The original `LibraryPage` data subscriptions and the exact `onTap` route actions are retained. The original leading Flutter icons and partner avatars remain in use, pending identification/licensing of matching BBOS6 images.

## Source references

- `NeilRuffell/bb-ui` branch `master`: `music-app/app/src/main/java/dev/q25/bbmusic/MusicListView.java`
- `NeilRuffell/bb-ui` branch `master`: `music-app/app/src/main/java/dev/q25/bbmusic/MusicSelectionGradient.java`
- BB Music source revision: `89ce1261ccf1c5003bdc0e104280c70221e7e519` (reference checked during this implementation).

Verified and ported to Flutter:

- Black background (`#000000`) in both light and dark mode.
- 68dp minimum row height, square corners, no outline.
- White, 15sp title text with 16dp horizontal label padding.
- 68dp leading artwork/icon slot. Current Library icons are centered rather than importing BlackBerry assets.
- 1dp `#303030` separator *between* rows.
- Full-width selection gradient, matching all original stops: light mode `#088EEF` … `#1065DE`; dark mode `#459FD9` → `#3285C5` → `#2368AA`.
- Focus (not row activation) drives the selection gradient; Flutter's `InkWell` retains touch and standard keyboard activation via existing callbacks.
- Minimum rather than forced height allows large accessibility text to grow without changing ordinary row sizing.

Shared code: `mobile/packages/ui/lib/src/components/bbos6/`.

Tests: `mobile/packages/ui/test/bbos6_media_list_tile_test.dart`.

Preview: `mobile/packages/ui/lib/src/previews/bbos6_media_list_tile.dart`.

## Validation

Run the package widget tests and analyzer using the repository's mobile development setup; validate row height, colors, gradient, focus traversal and Enter/trackpad activation on the target Android device.

**No build or device validation is implied by a source-only commit.** Follow the architecture policy in `mobile/docs/BBOS6_PRESENTATION_ARCHITECTURE.md`.
