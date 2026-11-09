# mobile/AGENTS.md

Flutter app with Riverpod, Drift (SQLite), auto_route, pigeon and a Rust core in `../native/`.

## Mandatory rule: shared helpers own shared behavior

**Before editing a screen, determine whether the requested behavior or appearance
belongs to an existing reusable helper. If it does, change the helper itself.**
This rule applies to *every* shared BBOS6 component, even when it currently has
only one consumer. Do not special-case the current screen (for example, Albums)
when the user asks to change the helper (for example, PaneManager).

- Shared helpers own interaction rules, focus and traversal boundaries, keyboard
  and trackpad handling, activation/selection state transitions, Back behavior,
  and reusable visual styling. Implement these **once** in the shared component
  under `packages/ui/lib/src/components/bbos6/`.
- A consuming page supplies only page-specific data, configuration, the
  content/focus target, and business-action callbacks. It should not reproduce
  shared control logic with local key listeners, navigation handlers, or
  page-specific hacks. Use configuration or interfaces only where necessary to
  connect the helper to a page's data/route system.
- Check all existing uses and treat new behavior as the **default for all
  instances** of that helper. Do not silently retain inconsistent legacy
  behavior in other consumers.
- Test the shared helper's contract independently, then regression-test every
  affected consumer (including focus, Back, touch, physical trackpad, list/grid,
  empty content, and sliver layouts where applicable).
- Only add a page-specific behavior when explicitly requested or when genuinely
  intrinsic to that page's own data/actions; document the exception and keep
  generic logic out of the page.

Reference: [BBOS6 presentation architecture](docs/BBOS6_PRESENTATION_ARCHITECTURE.md)
and [PaneManager behavior](docs/BBOS6_ALBUMS_PANE_MANAGER.md).

## BBOS6 presentation-only fork policy

Before editing this fork's mobile appearance, read [BBOS6 presentation architecture](docs/BBOS6_PRESENTATION_ARCHITECTURE.md).

- Use the **working BB Music application in `NeilRuffell/bb-ui` branch `master`**, particularly `music-app/app/src/main/java/dev/q25/bbmusic/`, as the primary reference for BlackBerry OS 6 media styling; the `bb-ui` default `main` is not the active reference.
- Port existing BB Music visual specifications and supported focus semantics into reusable **Flutter** controls. Do not copy Android Java Views, rebuild image/data pipelines or invent redundant BBOS6 components.
- Keep changes strictly inside the presentation boundary: preserve Immich's service behavior, Riverpod business state, synchronization, backup, permissions, authentication, databases, API, route semantics, and image/playback engine.
- Prefer shared Flutter controls under `packages/ui/lib/src/components/bbos6/` with tests/previews, then convert screens incrementally. Treat original BBOS6 icon mappings in `bb-ui/assets/bbos6/icon-index.csv` as canonical and review asset redistribution rights before adding images to this fork.
- Preserve touch, physical-key navigation and accessibility; validate functionality after each visual change.
- For horizontal category/icon panes, reuse `PaneManager` from `packages/ui/lib/src/components/bbos6/pane_manager.dart` (see `docs/BBOS6_ALBUMS_PANE_MANAGER.md`); supply content/filter callbacks externally. Do not create a separate pane renderer for each Flutter screen. Native Java apps need their own rendering implementation of the shared UI contract.
- Pair each PaneManager with its shared `PaneManagerController` and wrap the owned pane content in `PaneManagerContent`; all Left/Right, Enter/Select, focus-boundary and two-stage Back behavior belongs in the shared helper, never page-specific key handlers. Pages supply only content focus targets and data callbacks.
- For BBOS6-style inline search, reuse visual-only `Bbos6SearchBar` from `packages/ui/lib/src/components/bbos6/bbos6_search_bar.dart` (see `docs/BBOS6_ALBUMS_TYPE_TO_SEARCH.md`). Supply existing TextField/controllers/filter callbacks; never move search data/business logic into UI components.
- For timeline/photo grids, reuse `Bbos6GalleryView`, `Bbos6GridNavigationController` and `Bbos6GalleryItem` from `packages/ui/lib/src/components/bbos6/bbos6_gallery_view.dart`. The shared UI owns directional row-aware navigation and selected-thumbnail highlighting. Each consuming presentation adapter supplies its existing grid, viewer callback and scroll geometry. Keep original timeline date headers and group-selection controls. Do not place Immich providers or EXIF fetching in the shared UI package; see `docs/BBOS6_TIMELINE_GALLERY.md`.

## Rules

- Run `mise //mobile:checkout` after switching branches. All generated Dart is git-ignored; never edit it.
- New code follows `lib/domain/` (models, services, utils; no dependency on presentation or infrastructure) → `lib/infrastructure/repositories/` → `lib/presentation/`, wired by providers in `lib/providers/`. New data access goes in `lib/data/` (`lib/data/db/main/` holds the Drift database, `dao/`, `query/`, `table/`; `lib/data/server/` the API base).
- Top-level `lib/pages`, `lib/widgets`, `lib/services`, `lib/repositories`, `lib/entities` are legacy; do not add to them.
- Shared design-system widgets live in `packages/ui/` (`immich_ui`), with a preview per component in `lib/src/previews/`.

## Skills

- **Run codegen**: `mise //mobile:codegen` runs the Dart OpenAPI client, build_runner (`*.g.dart`, `*.freezed.dart`, `router.gr.dart`), Drift migrations and schema, ffigen, pigeon and translations. Run it after changing Drift tables, routes, pigeon definitions or freezed classes; `mise //mobile:codegen:watch` keeps build_runner running. CI job "Unit Test Mobile" regenerates and fails if the code does not compile.
- **Change the local database**: edit tables in `lib/data/db/main/table/` and the `@DriftDatabase` in `lib/data/db/main/database.dart`, bump the schema version, then `mise //mobile:codegen:drift:migration` writes `database.steps.dart` and a snapshot in `drift_schemas/main/`. Add a step migration and a test in `test/drift/main/`.
- **Add a platform channel**: define the API in `pigeon/<name>.dart`, run `mise //mobile:codegen:pigeon` to generate `lib/platform/<name>.g.dart` plus the Swift and Kotlin interfaces, then implement them in `ios/` and `android/`.
- **Tests and lint**: `mise //mobile:test`; one file with `flutter test test/path/foo_test.dart`. Tests live under `test/{unit,medium,domain,infrastructure,drift,presentation}/`; `test/medium/` has `repository_context.dart` and `service_context.dart` for tests against a real Drift database. `mise //mobile:lint` runs the analyzer and DCM; `mise //mobile:lint-fix` fixes what it can.
- **Preview a UI component**: `cd packages/ui && flutter widget-preview start` shows components from `lib/src/previews/` with a light/dark toggle.
