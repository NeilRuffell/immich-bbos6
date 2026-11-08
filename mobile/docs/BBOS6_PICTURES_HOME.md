# BBOS6 Pictures home — approved navigation composition

## User-facing home screen

The authenticated app landing screen is a **Pictures** page with six full-width BB Music-style rows, in exactly this order:

| Visible label | Existing Immich destination |
| --- | --- |
| Pictures Library | Photos timeline (`MainTimelineRoute`, existing tab index 0) |
| Albums | Albums (`AlbumsRoute`, existing tab index 2) |
| On Device | Local albums (`LocalAlbumsRoute`) |
| Memories | Memories list (`MemoryListRoute`) |
| Places | Places collection (`PlaceRoute(currentLocation: null)`) |
| People | People collection (`PeopleCollectionRoute`) |

The original Immich bottom `NavigationBar` and landscape `NavigationRail` are **not rendered**. No horizontal four-tab navigation is visible. The former Library quick-access screen remains available as an internal route, but is not a Pictures home entry; Search is not an additional home entry.

## Interaction and scope

- Use the shared `Bbos6MediaListTile` and its BB Music focus gradient for all home entries.
- The first row autofocuses for D-pad / trackpad use. Touch remains supported.
- Opening Pictures Library or Albums selects the **existing** Immich tab, including the existing tab selection side effects. Back from that top-level destination returns to Pictures home.
- On Device, Memories, Places and People push their existing guarded routes; Back pops the destination and reveals Pictures home.
- Continue honouring Immich read-only mode: Pictures Library remains usable; destinations that previously lived behind the disabled Library/Albums tabs are disabled.
- Do not change media providers, authentication, backup, synchronization, route guards, asset data, or timeline/gallery widgets.
- Keep the original four `AutoTabsRouter` routes internally for existing navigation, deep links and compatibility. This removes *visible* tabs without deleting Immich's navigation plumbing or generated routes.
- Header and temporary Flutter Material icons are presentation placeholders until their BBOS6 counterparts are identified and cleared for reuse.
- No additional Camera or Picture Apps row has been added to this user-approved six-entry home.

## Code and verification

- Home widget: `mobile/lib/presentation/pages/bbos6_pictures_home.dart`
- Existing navigation shell: `mobile/lib/pages/common/tab_shell.page.dart`
- Shared row: `mobile/packages/ui/lib/src/components/bbos6/bbos6_media_list_tile.dart`
- Widget tests: `mobile/test/presentation/pages/bbos6_pictures_home_test.dart`

### Manual acceptance checklist (target Android device)

1. After signing in, the first visible page is **Pictures** with the six entries in the approved order.
2. There is no bottom tab bar and no left rail on rotation.
3. Select Pictures Library: the existing Photos timeline displays; Android Back returns to Pictures home.
4. Select Albums: Immich's existing Albums page displays; Android Back returns to Pictures home.
5. Each of On Device, Memories, Places and People opens the existing destination; Android Back returns to Pictures home.
6. D-pad/trackpad Up/Down selects and Enter opens one row; touching any enabled row also opens it.
7. Existing album/photo viewer, backup and sync functionality remains unaffected.
8. Test read-only mode and deep links; those are dependent on the existing routing infrastructure.

The source change alone does **not** demonstrate successful compilation, automated tests or on-device verification.
