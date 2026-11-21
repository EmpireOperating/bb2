# Procedural maps: first playable integration slice

This preview generates a different connected overworld for each seed and saves that world in full. It extends the delivered 0.27 prototype while leaving other chats' work for a separate merge. It is a Godot 4.4.1 source project, not a native executable or a merged 0.28 release.

## Player loop

Start in a generated farming town. Ask for local rumours, click open ground to investigate an approximate search area, and discover the actual landmark through normal sight. Survey a watchtower to reveal more country, or spend time searching for finite supplies. Arrivals, sightings and completed actions pause the world. A search can be interrupted by a raider party; unfinished work awards nothing.

Town contracts mark camp targets without revealing their surrounding terrain. Roads follow traversable ground and cross rivers at bridges. Forests and hills cost more travel time; water and mountains block movement. The existing trade economy, council patrols, scouts, markets, recruits and tactical battles consume the generated region.

Clearing a camp frees its road. A surviving strength-three band must spend real stolen food to reoccupy it, and cannot do so before `cleared_day + 4`. This is a calendar-day rule, not a separate 96-hour timer. A stationed patrol still blocks expansion. New occupation increments the band's generation and can create a new scout party; it never refills an already searched discovery. If every band is destroyed, no outside invaders appear in this slice.

## Contents and boundaries

| Included now | Deliberate boundary |
|---|---|
| Seeded terrain, horizontal or vertical river, two crossings | Existing 58×30 navigation grid and map viewport |
| Three named towns and six connected road links | Existing farming/market/mining economy roles |
| Three camps with finite scout parties | Existing camp/tactical-map roles and combat rules |
| Watchtower, ruined refuge, guarded cache | Three discovery templates; no event dialogue system yet |
| Rumours, scout/search actions, finite loot, saved history | No repeat harvesting or randomized reload rewards |
| Existing caravans and council patrols on generated routes | Economic interception still settles daily, not physical NPC collisions |
| Full region and action-state persistence | Preview schema 23 is not readable by the main 0.27 build |

The internal IDs `ashwick`, `stonecross`, `dunmere`, `ford`, `forest`, and `ridge` remain stable role keys. Their display names and positions come from the generator. Recruitment, stock, factions and contract providers already depend on these keys. This adapter proves generated geography without simultaneously replacing those providers. More towns will require provider changes, not merely a larger generator loop.

Generation uses an independent seeded RNG. Founder attributes, personal trees, gear, recruit pools and combat randomness do not consume map randomness. Joining-history prose uses the generated hometown name. Terrain and definitions are stored, so loading does not run the generator again.

## Integration contract

`Campaign.setup(company_seed, map_seed)` creates generated geography when `map_seed >= 0`. Omitting the second argument retains the fixed map for existing tests and callers. The preview UI passes the company seed as both values; the existing smoke test explicitly retains its classic fixture.

| File | Integration responsibility |
|---|---|
| `src/map_generator.gd` | Deterministic region generation, road polylines, discovery definitions, economy adapter, validation |
| `src/exploration.gd` | Rumours, finite discovery history, timed scout/search actions, atomic restore validation |
| `src/procedural_view.gd` | Generated terrain, fog, roads, landmarks and discovery detail panel |
| `src/campaign.gd` | Setup, schema 23 snapshots, candidate-region restore, action cancellation and clock integration |
| `src/overworld.gd` | Generated terrain/costs/obstacles, road segments and survey reveal radius |
| `src/world.gd` | Optional reoccupation delay and generated place names in events |
| `src/main.gd` | New-company map seed, renderer branch, discovery controls, preview save path |
| `src/playability.gd` | First-contract hint uses actual town and camp names |

Restore validates candidate region, world, navigation, exploration, inventory and battle before assigning live objects. A malformed save leaves the current game unchanged. The market validator now checks actual physical town presence: a company crossing a weekly refresh while still travelling does not need a remotely created market book for the town it last visited.

| State | Schema |
|---|---:|
| Generated campaign | 23 |
| Classic campaign | 22 |
| Generator definition | 1 |
| World economy | 2, unchanged |
| Overworld | 1, unchanged |
| Tactical battle | 19, unchanged |
| Personal perk pool | 5, unchanged |

The preview save is `user://ashen-company-procedural-preview.json`. Its normal Save/Load controls intentionally use this separate path. The main prototype save is not overwritten. The perk lab retains its existing save path. Classic saves are supported by the campaign reader, but are not automatically imported into the preview file.

Merge `campaign.gd`, `main.gd`, `overworld.gd` and `playability.gd` carefully with the other chat's early-game/visibility work. Preserve their balance and progression changes. `ProceduralView` owns the generated-map fog branch; the classic renderer remains separate. Main-file differences include indenting the original renderer under that branch, not replacing all of its behavior.

Generator validation currently derives its expected economy from `data/world.json`. If that template is changed during integration, review the generator adapter and schema-23 migration together: do not silently reject delivered preview saves or reroll their stored geography. Before shipping later generator/economy versions, retain a versioned validation/migration path for these definitions. Enlarging the grid also requires versioned navigation bounds rather than changing the existing constants in place.

## Verification

The deliverable's `VALIDATION.md` records final results and reproducible commands. The focused new suites are:

`docs/.gdignore` keeps human-readable CSV reports and screenshots out of Godot's asset importer. A clean editor import initially crashed while importing the inherited CSV reports; documentation is not a game resource. Tests can still write their screenshots and reports to that directory through `FileAccess`.

- `tests/procedural.gd`: 128 seeds; deterministic replay; all landmark pairs routed on production navigation for eight seeds; 30-day economy conservation; unchanged people/perks/gear; old/new save replacement; timed and interrupted searches; one-time loot; guarded caches; cooldown and funded reoccupation; no spontaneous respawn after complete clearance; weekly refresh during travel; corrupt-save rejection.
- `tests/procedural_journeys.gd`: eight default companies, real continuous journeys and legal AI battles; mid-route, battle, aftermath and camp saves; both victory and defeat; contracts and economic conservation. No manufactured battle results in this suite.
- `tests/procedural_ui.gd`: actual native mouse/key journey to a rumoured watchtower, survey/search, F5/F9 during travel and actions, resupply, contract travel and combat; a separate fresh seed-1 camp victory and cleared-road reload. No stat buffs or forced combat outcomes.

The initial long native journey lost its camp fight after earlier casualties. That exposed the baseline's harsh recovery/balance, not a map-state failure; this pack makes no combat balance changes. The final test verifies that this loss preserves the camp and searched-site history, and separately verifies a real fresh-company victory. The eight model journeys likewise include both outcomes; they are integration coverage, not evidence that all starting seeds are equally easy.

Screenshots named `procedural-atlas-fixture-*` explicitly reveal the whole map solely for layout inspection. Other `procedural-*` screenshots come from the actual native journey. The final pack includes both kinds with their filenames intact.

## Next slice after merge

Playtest travel distances, recovery time and scout pressure against the other chat's revised starting-company balance. Then add more discovery templates through the existing immutable definition / mutable history split. Expanding town count and introducing outside bands should follow that test, with explicit regional population budgets and save migrations.
