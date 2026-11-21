# Validation — free-roaming Marches 0.25

43,188 assertion checks across the passing suites below. Counts include repeated assertions, not unique scenarios. Godot 4.4.1 on Linux. The base is the complete delivered 0.24 project; its axe/mace code, perk data and combat rules are retained.

| Suite | Checks | Evidence |
|---|---:|---|
| `overworld` | 1,339 | Routes between every landmark, off-road orders, terrain and crossings, physical town access, pause/speed, midnight accounting, sustained NPC movement, pursuit/evasion, escorts, camp assaults, encounters, corrupt-save rejection and all 480 clock steps through JSON |
| `overworld_ui` | 23 | Native mouse/key journey: leave town, save/load mid-route, spot/intercept scouts, save contact and live battle, fight, return, buy provisions, save again |
| `axe_mace_ui` | 32 | Native perk buying, real continuous travel, mastery attacks, shield damage/stagger and exact F5/F9 continuation |
| `axe_mace` | 70 | Arithmetic/timing, three delivered 0.23 campaign continuations, exact original battle outcomes |
| `background_generation` | 29,935 | 7,200 generated people, 34–42 choices, 32 earned-point build routes and three 0.19 continuations |
| `ranged_perks` | 7,513 | Ranged rules, earned progression, equipment and historical saves |
| `turns` | 3,610 | 24 ordinary campaign battles: 17 victories, 7 defeats, no draws; map/objective and older-save continuations |
| `double_grip` | 429 | Weapon/damage exceptions and exact 0.21 continuations |
| `perks` | 134 | Shared perk costs, progression, personal pools and saves |
| `tactical_ai` | 43 | Paid decisions, no planning RNG and exact original 0.20 battle/settlement records |
| `engagement_ai` | 44 | Approach/re-engagement, bracing, escape, prior stall and saved fights |
| `perk_timing` | 16 | Expiry and reaction timing |

The native overworld run uses seed 7391, ends on day 3 and returns all six soldiers to Ashwick. The test advances the normal process clock faster than wall time and uses legal combat AI commands to finish the battle. It does not force victory, teleport the company or inject food/rewards. Other model fixtures force results only where they test settlement rather than combat balance. The axe/mace UI retains its documented XP, equipment and adjacent-combat fixtures.

`docs/overworld-*.png` records town, travel, discovery, contact, battle, aftermath and return. UI tests ran under a native X11 OpenGL window using Xvfb/Mesa. The environment emitted its known unsupported VSync warning; no game script errors occurred in the final passing native runs.

## Save and integration changes

Campaign schema 21 adds overworld schema 1 and a separate encounter record. New fights retain battle schema 18. Full-precision JSON and canonical three-minute clock/AI timers preserve spatial state across save/load. Mid-route, pending-contact, active-battle and aftermath saves are checked. Invalid spatial saves are rejected before changing a live company. Original 0.23 battle commands, RNG, wounds, gear and progression remain exact after import; tests compare every original campaign field while excluding only the newly added spatial fields and campaign version.

The native test travel helper now waits for real arrival, handles sighting pauses and resolves intervening scout fights. Legacy fixture comparisons were updated for the added schema fields; the tactical-AI test's stale new-battle version expectation was updated from 17 to the already-delivered 0.24 schema 18.

## Scope and known limitations

This is the first three-town, 30-day free-roam region. Terrain, regions and discovery content are not procedural. Field encounters reuse their originating camp’s tactical map. Friendly wagons and council patrols follow the existing daily schedules; their economic outcomes still settle daily. Independent spatial caravan interception and continuous faction economics are not implemented. Battle settlement retains its existing one-day campaign cost.

The archival `company.gd` v0.13 test has obsolete perk expectations (1,593 failures on the unmodified 0.24 baseline). The archival `world.gd` v0.3/v0.4 migration branches also fail on that baseline. These are not included as passing suites or silently repaired here. Delivered 0.19–0.24-era population/combat continuations are covered by the current suites above.

The previous 0.24 balance report is preserved in `VALIDATION-v0.24.md`. Its other historical samples are not claimed as new runs. Native Windows/macOS exports were not built or tested.
