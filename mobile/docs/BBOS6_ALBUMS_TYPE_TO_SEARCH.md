# BBOS6 Albums type-to-search — incremental pass 2

This is a **separate, testable branch** built on
`feat/bbos6-albums-list-rows` (the list-row pass, itself based on the
PaneManager feature branch). No changes have been merged into `main`.

## Expected interaction

- When first opening Albums, the old permanent search bar is gone. The
  PaneManager and the original Grid/List and Sort controls remain visible.
- With the album page focused, pressing a printable physical keyboard key
  reveals the BB Music-style search field, with that character already entered.
- Further typing edits the same `searchController`; Immich's existing
  `onSearch`, `filterAlbums`, provider and search mode are used unchanged.
- The search field appears only while the user is searching. The visible X
  button or Escape closes it and invokes the existing `clearSearch()` action.
- The keyboard listener ignores control/alt/meta shortcuts and avoids
  intercepting letters while the search text field itself has focus.
- PaneManager continues to own initial focus; Left/Right pane navigation
  continues to work.
- Existing album opening, sorting, grid/list view, new-album creation,
  delete confirmation, upload and refresh logic remain unchanged.

**Scope note:** Android Back still follows Immich's existing navigation
behavior; this pass does not change the route hierarchy or alter global Back
handling. The explicit X button and Escape provide search dismissal.

## Reusable BBOS6 search bar

`Bbos6SearchBar` is exported from `immich_ui` and owns **appearance only**:

- 54dp outer height, 1dp top rule `#5A5D63`
- charcoal gradient `#4B4E53` to `#292C31`
- 5dp gray field rim with 1dp inset and 4dp inner radius
- inset light field with the six BB Music stops
  `#D6D7D6`, `#E7E7E7`, `#EFEFEF`, `#F7F7F7`, white, white
- accepts any Flutter `Widget` child, so it can wrap existing search inputs
  without cloning their search/filter/data logic.

Reference: `NeilRuffell/bb-ui` branch `master`,
`music-app/app/src/main/java/dev/q25/bbmusic/MusicSearchBarView.java`,
blob SHA `bb18efd2a6ba9a257396c88c6d02041d1408a920`.

## Test procedure on Q25

1. Install Pass 1, confirm album rows and existing search work.
2. Install Pass 2. Open **Albums**: no search field until typing.
3. Type a letter on the Q25 keyboard. The BB-style bar appears showing that
   letter and the list filters as before.
4. Type more letters, Backspace and edit text; confirm the same album results
   as original Immich search.
5. Tap X (or press Escape): search closes and the original album list returns.
6. Move between All, Shared and My Albums; confirm each still uses the existing
   Immich filter.
7. Verify Grid/List, Sort, new album, album opening and scrolling still work.

**Unverified:** code compilation, automated tests and Q25 behavior must be
validated with Flutter on the user's development laptop.
