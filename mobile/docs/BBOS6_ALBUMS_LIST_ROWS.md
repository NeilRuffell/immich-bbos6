# BBOS6 Albums list rows — incremental pass 1

This branch builds on `feat/bbos6-albums-pane-manager` but changes only the
presentation of the existing **Albums list**.

- `AlbumTile` now renders the existing album name, count, ownership/share status
  and remote thumbnail inside the shared `Bbos6MediaListTile`.
- Artwork is a square 52dp image centered in the existing 68dp shared leading
  slot. Missing thumbnail uses a charcoal placeholder.
- Rows use shared BBOS6 focus gradient, black background, 68dp height, square
  edges and 1dp divider. There are no between-row gaps or horizontal tile margins.
- The existing `_AlbumList` still uses the existing remoteAlbumProvider,
  `RemoteAlbumRoute` and owner-only `Dismissible` with confirmation and deletion.
- Grid rendering, sort, search, album creation and all providers remain unchanged.

**Not part of this pass:** hiding the search bar or changing the type-to-search
experience. Use this branch first to verify the new album list styling.

## Q25 check

1. Open **Immich → Albums** and leave Grid/List in list mode.
2. Verify titles, album counts, artwork, and shared/owned labels.
3. Move the trackpad up/down: rows must highlight consistently.
4. Open an album normally, then return.
5. Confirm the existing swipe-to-delete confirmation still works for an
   album you own (cancel rather than deleting it while testing).
6. Switch Grid/List: the original grid is preserved.

Compilation and Q25 interaction verification are pending.
