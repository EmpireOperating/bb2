# Ranged integration validation

All listed checks passed on Godot 4.4.1. The preview uses the supplied 0.17 progression implementation unchanged. Tests deliberately use declared XP fixtures to reach late levels; this is not evidence that the 30-day campaign reaches level eleven naturally.

| Suite | Checks | Scope |
| --- | ---: | --- |
| `tests/perks.gd` | 134 | Original perk effects, pools, buying, saves and migration |
| `tests/perk_timing.gd` | 16 | Reaction/Wait/round lifetime and malformed state |
| `tests/perk_lab.gd` | 11 | Nine existing melee presets save/load |
| `tests/ranged_perks.gd` | 7,512 | 162 ranged pools; four legal weapon routes each; all new effects; ammo/refills; real earned points; old-save continuation |
| `tests/talent_growth.gd` | 7,569 | 3,600 generated people; stars/rolls; all training levels; cap and banking; malformed saves; legacy catch-up/continuations |
| `tests/combat_baseline.gd` | 141 | Worked hit/resolve/fatigue cases and twelve first contracts |
| `tests/damage_balance.gd` | 372 | Damage cases and legacy battle continuations |
| `tests/perk_trials.gd` | 2,259 | 1,080 matched melee smoke battles |
| `tests/ranged_trials.gd` | 531 | 216 matched ranged/hybrid smoke battles |
| `tests/perks_ui.gd` | 18 | Native melee tree, Gifted, hiring and active-perk input |
| `tests/ranged_ui.gd` | 54 | Native ranged trees/presets, prehire/hire, F5/F9, refill, costs, throw/bow attacks and hybrid stat display |
| `tests/talent_growth_ui.gd` | 26 | Native three-stat growth, catch-up, confirmation, save/load and independent perk points |

There are 54 melee access-pool combinations (34–36 options) and 162 ranged combinations (36–42 options). Every ranged combination passes a full ten-pick order for bow, crossbow, throwing and its available melee weapon. Nine authored ranged/hybrid builds additionally spend points from the real level-11 progression calculation, train attributes, and save at camp and in battle. This verifies access and integration, not equal power across all generated stat distributions.

## Persistence and regressions

- Saved pools and choices are retained across equipment changes and JSON roundtrips.
- Main 0.17 and the earlier melee pack import at camp or mid-battle. Old fights preserve actions, casualties and RNG through settlement before adoption.
- New counters and prepared head hits persist; malformed current-schema state is rejected. Original perk battle saves receive neutral defaults.
- Physical throwing counts persist through swaps, rounds and save/load. Town refills charge the correct currency and update merchant bookkeeping. Repairs cannot create ammunition.
- Colossus and ordinary health growth preserve missing HP. Gifted and perks remain independent of the three ordinary attribute choices.
- The native perk screen now supports F9 as well as F5. All eleven group filters fit, every perk remains visible, and action buttons are separate from active-perk controls.

## Simulation limits and findings

The smoke reports are `perk-trial-results.json` and `ranged-trial-results.json`. Ranged trials use nine builds across open, flanked and fatigue scenarios, eight battles per combination (four matched seeds, both sides). Each person's three presets keep the same authored stats and pool, but change gear and perks. Equipment costs range from 335 to 901 crowns. The comparison does not isolate perk strength or normalize cost.

The sample shows distinct trade-offs. Lysa's sword route improved markedly in the flanked scenario but struggled in the open/fatigue scenarios. Oren's crossbow harrier sometimes reached the round limit. Tova's throwing and spear options all completed their scenarios. These small, scenario-dependent observations are reasons for manual testing, not grounds for claiming equal balance or tuning to a win-rate target.

AI does not plan Wait for Patient Hunter or deliberately use Footwork, Rotation and Indomitable. Command tests cover those effects. Final balance, generated-career viability across weak and unusual recruits, and richer AI remain open. No balance values were changed merely to make the smoke results win more often.

## Reproduce

From `preview`, run `godot --headless --path . --script tests/ranged_perks.gd` (substitute another non-UI suite name as needed). Import the project once through Godot first if required. UI scripts need a native display, an isolated user data directory, and the same engine version; run `godot --path . --script tests/ranged_ui.gd` or `tests/talent_growth_ui.gd`. They use actual input events and write PNGs to `docs`.

Screenshots include `ranged-bow-tree.png`, `ranged-crossbow-tree.png`, `ranged-throwing-tree.png`, `ranged-recruit-preview.png`, `ranged-volley-actions.png`, `ranged-throw-actions.png`, `ranged-refill.png` and the retained growth/control captures. Screens were visually checked for clipping and overlap.
