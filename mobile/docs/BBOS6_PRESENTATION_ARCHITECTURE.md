# BBOS6 presentation architecture for Immich Android

## Purpose and decisions

This fork restyles **the existing Immich Flutter Android app** as a BlackBerry OS 6-style Pictures/media application. The project design premise is that BBOS6 Music and Pictures share visual conventions; therefore, **the already working BB Music UI in [NeilRuffell/bb-ui](https://github.com/NeilRuffell/bb-ui/tree/master/music-app) is the primary visual and interaction reference**. Do not create a separate interpretation of BBOS6 styling when an existing BB Music component provides the relevant design.

**Decision: hybrid, reuse-first implementation.** First port shared BB Music presentation patterns as a Flutter design system, then adapt Immich screens incrementally. Preserve Immich's navigation, business logic, data models, synchronization, image processing, backup, authentication, and server compatibility.

The two projects are implemented in different UI frameworks: BB Music uses Android Java Views; Immich uses Flutter/Dart. **Reuse verified assets, visual specifications, dimensions, and relevant interaction semantics; reimplement the rendering in Flutter.** Do not copy native Android View classes into the Flutter widget tree or re-create Android's data/services.

## Non-negotiable scope

### Allowed changes
- Flutter styling, colors, gradients, typography, borders, padding, component sizing, icons, visual animations, app chrome, and screen composition.
- Presentation widgets and their layout-specific state, with the same user-visible action callbacks and data inputs.
- Flutter focus/highlight rendering and keyboard/D-pad accessibility **without** changing what an Immich action does.
- Asset integration after identifying original sources and reviewing redistribution rights.

### Protected implementation
- Server code, API contracts, authentication, permissions, network transport, synchronization, background uploads, backup policy, persistence/database, media decoding, thumbnail/cache pipelines, Riverpod business state, and native Rust/Kotlin/Swift functionality.
- The meaning of existing route actions, viewer gestures, selection, sorting, filters, deletion, sharing, export, map, and playback operations.
- Generated code and the mobile build/code-generation workflow.

**Boundary test:** If a change modifies which assets are returned, when/how data is saved or uploaded, which backend operation occurs, or the semantics of an existing action, it is not presentation-only. Do not silently widen scope to make a visual redesign easier. File location alone does not prove a change is presentation-only: some pages contain provider calls and operational logic.

## Sources of truth (always identify the correct branches)

| Reference | Purpose |
| --- | --- |
| [bb-ui `master` / `music-app/`](https://github.com/NeilRuffell/bb-ui/tree/master/music-app) | **Existing working BB Music UI reference**. This repo's default `main` branch is not the reference; inspect `master`. |
| [BB Music README](https://github.com/NeilRuffell/bb-ui/blob/master/music-app/README.md) | Established behavior, dimensions, focus semantics, artwork layout and media chrome. |
| [BB UI design philosophy](https://github.com/NeilRuffell/bb-ui/blob/master/docs/DESIGN_PHILOSOPHY.md) | Reuse-first, one owner per responsibility; apply the same principle at the app level. |
| [BBOS6 icon index](https://github.com/NeilRuffell/bb-ui/blob/master/assets/bbos6/icon-index.csv) | Canonical verified original icon number/name mapping. |
| [BB UI icon identification policy](https://github.com/NeilRuffell/bb-ui/blob/master/AGENTS.md) | No speculative icon names; update the canonical index when a newly verified icon is assigned. |
| `mobile/AGENTS.md` in this fork | Existing Immich mobile coding constraints and development commands. |

**Do not assume the BB Music implementation or icon index is identical across branches.** Record a source commit SHA when importing an asset or translating a component, so appearance changes can be traced to an exact version. Do not alter the reference repository without a separate request.

## Verified BB Music components to translate into Flutter

The following paths refer to `bb-ui` **`master`**, relative to `music-app/app/src/main/java/dev/q25/bbmusic/`. Suggested Flutter component names are new proposals, not classes that already exist.

| Existing Java component | Verified responsibility | Proposed reusable Flutter presentation equivalent |
| --- | --- | --- |
| `MusicSelectionGradient.java` | Shared borderless, square-cornered top-to-bottom selection gradient; light/dark palettes | `Bbos6FocusDecoration` / shared selection-state tokens |
| `MusicListView.java` | Consistent black 68dp list rows, titles/counts/artwork, visual highlight, Up/Down focus; menu artwork normalized into a 52dp visible area | `Bbos6MediaListTile`, `Bbos6Icon`, focus visuals only; keep Immich's Flutter lists and scrolling |
| `MusicSearchBarView.java` | 54dp search chrome, top border `#5A5D63`, gradient `#4B4E53` to `#292C31` and inset field | `Bbos6SearchChrome` around existing Immich search/filter behavior |
| `MusicSettingsHeaderView.java` | Reusable 36dp non-selectable settings section header | `Bbos6SectionHeader` |
| `MusicAlbumHeaderView.java` | Album artwork/info presentation: 88dp content + 1dp `#515251` divider | `Bbos6MediaDetailHeader`, only where the Immich screen has corresponding data |
| `MusicPlayerChrome.java` and `MediaChromeDivider.java` | Shared media-control/seek-area visual layers, borders and separators | `Bbos6MediaChrome` for relevant photo/video viewer controls; no playback logic port |
| `MusicListArtworkLoader.java` and icon normalization in `MusicListView.java` | Music artwork binding and icon alpha-crop presentation | Reuse **icon sizing/cropping appearance**, not the music-specific loader; keep Immich's image pipeline |

These are reference implementations, not a requirement to replace each Immich component with a one-to-one equivalent. If a Pictures screen differs functionally from Music, preserve the Pictures behavior and apply the common *visual language* rather than forcing Music's screen structure.

### Original icon handling

- Look up original icon filenames in `bb-ui/assets/bbos6/icon-index.csv`; do not infer icon identity from numeric filename.
- Preserve original numbered PNGs, mapping records, and proportions when approved for reuse. Do not redraw or distort them merely to fit a slot.
- BB Music's menu renderer removes transparent padding **in memory** and scales the visible bitmap into a centered 52dp area inside the 68dp artwork slot; reproduce the effect with Flutter where it is applicable.
- Original BlackBerry-branded assets may have separate licensing/redistribution constraints. **Review rights before copying them into this public fork**; an asset appearing in another repository is not proof of a reusable license.
- The icon index is maintained at its BB UI source. Where new icon mappings are confirmed, update that index in the appropriate BB UI change; do not create a second contradictory master index in Immich.

## Immich integration points

Verified in this fork:

- `mobile/lib/theme/theme_data.dart` and `mobile/lib/theme/color_scheme.dart`: app-wide Flutter theme.
- `mobile/packages/ui/lib/src/theme.dart`: additional shared-package theme/extension.
- `mobile/packages/ui/lib/src/components/`: existing shared `immich_ui` controls (including menu, button and settings components).
- `mobile/packages/ui/lib/immich_ui.dart`: exports for shared widgets.
- `mobile/lib/pages/common/tab_shell.page.dart`: now presents the [approved six-entry Pictures home](BBOS6_PICTURES_HOME.md), without visible bottom tabs or landscape rail. The existing four `AutoTabsRouter` children and route-selection actions remain for compatibility.
- `mobile/lib/presentation/widgets/timeline/`: photo timeline, segmented layout, scrolling, scrubber, pinch zoom and drag selection. **Retain those mechanisms.**
- `mobile/lib/presentation/widgets/asset_viewer/`: image/video viewer controls, app bars, bottom bar and menus; keep the existing underlying asset state and playback handlers.
- `mobile/lib/presentation/pages/`: current screens; `mobile/lib/pages/` and `mobile/lib/widgets/` also contain older but active presentation code.
- `mobile/lib/routing/router.dart`: existing route declarations and guards; preserve their intent.

**Preferred location:** Add shared BB-specific Flutter components under `mobile/packages/ui/lib/src/components/bbos6/` (or a similarly dedicated namespace), export them from `immich_ui.dart`, and add component previews/tests following the package's established patterns. Place app-specific composition in existing `lib/presentation/` screens or targeted legacy screens; do not expand the old top-level legacy folders with new general-purpose widgets.

Retain Immich components when only their `ThemeData` styling needs changing. Use a new reusable BBOS6 component where Flutter's theme cannot express a verified gradient, border, icon treatment, or focus state. Avoid duplicate renderers or parallel data pipelines.

## Shared-helper ownership contract

**Shared first, even with a single current consumer.** When a change request
names a reusable helper, or changes behavior that a reusable helper owns, the
implementation target is that helper—not the page where the problem was noticed.
The helper is the source of truth for every current and future instance.

| Owned by shared helper | Supplied by consuming page |
| --- | --- |
| Focus/highlight behavior and navigation boundaries | Labels, pane models and content |
| Physical trackpad / keyboard activation and traversal | Data providers and action callbacks |
| Reusable Back/Enter state transitions | The page's normal route operations |
| Common visual design, sizing, gradients and accessibility contract | Layout placement and page-specific content |

**Required workflow:** (1) locate and read the helper and its consumers;
(2) make shared behavior changes in the helper; (3) update consumers only for
configuration, data/callback wiring, or the minimal integration needed;
(4) test the helper independently and verify affected callers; (5) document any
explicitly requested page-specific exception. Avoid solving a shared problem by
adding screen-local input handlers or duplicating helper functionality.

**PaneManager example:** Left/Right highlighting, Enter-to-activate,
focus isolation between the pane bar and owned content, and Back-to-pane
belong to the shared `PaneManager` / `PaneManagerController` /
`PaneManagerContent` implementation. Albums simply provides the pane
descriptions, the selection callback and the content focus target. See
[Albums PaneManager integration](BBOS6_ALBUMS_PANE_MANAGER.md).

**Exception:** When functionality is inherently specific to a screen
(e.g., the actual album filter operation or opening an album), retain it in
that screen's existing business/presentation wiring. Do not move Immich's
business logic into a generic UI helper.

## UX contract: BBOS6 appearance, Immich behavior

1. **Focus vs activation:** Visually distinguish unfocused, highlighted/focused and activated/selected state when the interaction requires it. Keyboard/trackpad focus must not accidentally activate a destructive command.
2. **Shared visuals:** One source per gradient, divider, row style, icon renderer, search chrome and grouped header. Fix styling in the shared component; do not paste equivalent color stops across screens.
3. **Dual input:** Existing touch/gesture interaction continues working. Physical keyboard, D-pad and focus navigation must remain usable where supported; implement focus through Flutter's focus/actions system rather than copying Android View event handlers.
4. **Media fidelity:** Use BB Music's proven list/chrome geometry where it fits. Photo grids, thumbnails, pinch/drag gestures, camera roll ordering and asset-viewer capabilities must remain intact.
5. **Platform behavior:** Preserve system dialogs, navigation guards, Back behavior, accessibility labels, readable text scaling, rotation, safe areas, and permission prompts. A stylistic change must not hide critical backup/sync/error status.
6. **Maintainability:** No replacement server, duplicate cache, second image loader, parallel navigator, or alternate data model to accomplish a visual change.

## Working method and order

1. **Reference audit:** Before implementing a component, inspect its BB Music Java source and any verified BBOS6 screenshot. Identify its states, exact sizing, gradient stops, separator geometry, and input behavior. Record source commit(s) in implementation notes.
2. **Design tokens and small shared widgets:** Port visual primitives and component previews first; avoid screen rewrites. Account for the two existing Immich theme layers.
3. **One screen at a time:** Restyle the main navigation/photo timeline, then albums/library, search, viewer, settings, backup/login, and remaining secondary screens. Prefer shared widgets whenever the same appearance recurs.
4. **Minimal diffs:** Change appearance/composition in existing widgets; preserve callbacks, provider subscriptions, routes, and operational state. Keep PRs/commits reviewable and changes easy to rebase against upstream Immich.
5. **Validation:** Run existing Flutter formatting, analyzer, widget tests and required checks (per `mobile/AGENTS.md`). Visually compare reference screenshots and exercise both touch and physical navigation on the target device. Explicitly check media browsing, opening assets, selection, search, sharing/deletion, backup status, settings, and Back/rotation. Compilation alone does not establish UI or behavior parity.
6. **Upstream updates:** Rebase/merge upstream Immich changes carefully. New upstream UI paths may require updated BB wrappers; never freeze or fork the underlying services just to avoid a UI reconciliation.

## Decision log

- **2026-11-07:** Adopt a presentation-only fork of official Immich mobile.
- **2026-11-07:** Select a hybrid approach: shared Flutter design system plus incremental page conversions; no wholesale UI rewrite.
- **2026-11-07:** Make `NeilRuffell/bb-ui` branch **`master`**, especially its working standalone BB Music app, the primary reference for BlackBerry OS 6 media styling. Import *appearance and verified interaction patterns*, not its Android Java, audio engine, or platform-specific implementations.
- **2026-11-08:** Approve a dedicated six-entry **Pictures home** with Pictures Library, Albums, On Device, Memories, Places and People, replacing visible Immich bottom/side tabs while retaining existing internal route behavior. See [Pictures home navigation](BBOS6_PICTURES_HOME.md).

**Current status:** The shared BBOS6 media list row is integrated into Library quick-access rows, and the approved six-entry Pictures home replaces the visible four-tab navigation. Existing internal routes remain. Build, widget tests and on-device navigation must be validated on the target Android device.
