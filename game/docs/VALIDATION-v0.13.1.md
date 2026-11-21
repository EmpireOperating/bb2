# Validation — archer hotfix 0.13.1

Godot 4.4.1, Linux x86-64. Native tests run at 1440×900 with Mesa software rendering and isolated save directories. This checks the source project; standalone exports and human balance are not established.

## Checks rerun for this patch

| Suite | Checks | Failures |
| --- | ---: | ---: |
| `tests/archer_rules.gd` | 396 | 0 |
| `tests/run.gd` | 1,160 | 0 |
| `tests/fields.gd` | 486 | 0 |
| `tests/formations.gd` | 564 | 0 |
| `tests/weapons.gd` | 865 | 0 |
| `tests/equipment_economy.gd` | 220 | 0 |
| `tests/playability.gd` | 42 | 0 |
| `tests/archer_ui.gd` | 30 | 0 |
| `tests/equipment_compat_ui.gd` | 128 | 0 |
| **Total** | **3,891** | **0** |

Only these seven model suites and two native suites were rerun. See `VALIDATION-v0.13.md` for the prior release's broader historical report. Counts include repetitive geometry and accounting assertions, not that many distinct player experiences.

## Root causes and rules

The ordinary move handler displayed the same Withdraw warning for every failed move. The model already excluded allies from engagement, so the reported earlier failed step cannot be attributed to friendly engagement. Its exact original AP/fatigue/position state was not available. Water, resources and routes now have separate reasons, and true engagement names an adjacent enemy.

The ray test also blocked every intervening living unit. For modern weapon-rule battles it now skips friendly occupants exactly one hex from the shooter, including bowed and crossbow variants and aimed shots. It keeps intervening forests, more distant allies and enemies opaque. A living, non-routed adjacent enemy still prevents ranged attacks. Player and enemy armies use identical rules; ammunition, loaded state and action costs are unchanged. The same line query powers legality and the displayed refusal reason.

The read-only movement diagnosis computes a passable route with the existing terrain, occupancy and enemy-control constraints, then distinguishes AP from free-fatigue shortages. It does not mutate positions, resources, commands or RNG. The Withdraw hotkey now matches its button's engagement and resource requirements.

## Focused model evidence

`archer_rules.gd` covers all five ranged variants, both armies, six hex directions and both row parities. Its 120 declared lane fixtures actually fire shots, verifying AP, fatigue, ammo and untouched allied health. Additional fixtures cover aimed shots, adjacent enemy control, distant friendly/enemy blockers, trees on an adjacent ally's tile, dead/escaped/routed units, range, polearm minimum reach, empty ammo, unloaded crossbows, ordinary backward movement, water, AP shortage, fatigue shortage, occupied destinations and impossible routes. Preview and rejected-command checks compare entire snapshots for mutation.

The focused suite also completes two identical current battles from a checkpoint and one migrated v0.12 active battle, settles them and reloads the resulting companies. Generated encounters use the patched engine without injected victories or resources.

Existing weapon and economy suites still exercise all 23 weapons, physical equipment costs, actual battles and salvage. The economy compatibility assertion was deliberately updated: v0.12 state must match exactly **at load**, but future combat now uses corrected rays. Requiring an identical unpatched AI command sequence would preserve the reported shooting bug. Instead, two independently restored patched copies must produce identical full state, command sequence, RNG and outcome. The older pre-v0.12 weapon-rule continuation check still passes unchanged.

The baseline `run`, `fields` and `formations` simulations mostly use historical weapon rules and therefore provide regression evidence, not balance evidence for the corrected friendly-rank shots.

## Native evidence

The archer journey equips a real stored bow and arrow pack through the loadout editor, accepts a contract, travels and deploys. A **declared positioning fixture** places the actual units in a controlled front-rank arrangement without changing equipment or resources. Mouse/keyboard input then verifies:

- Friendly adjacency leaves Withdraw disabled; its hotkey explains ordinary movement.
- Clicking behind the archer performs an ordinary backward step with the normal cost.
- Clicking the enemy fires through the adjacent ally and spends an arrow/AP without injuring the ally.
- The Aimed Shot action-panel button is enabled and pays its actual costs.
- Low AP, a more distant allied blocker, a real adjacent enemy and deep water produce distinct visible messages.
- F5/F9 restores the exact prepared state.

![Shot over a friendly front rank](archer-shot-over-frontline.png)

![Specific AP shortage](archer-ap-message.png)

![Aimed shot is available](archer-aimed-frontline.png)

![Genuine enemy engagement](archer-real-engagement.png)

The fixture is then discarded through the native New Company shortcut. A fresh, unmodified seed-2 company completes an ordinary battle and reloads its actual settlement. This is one complete native battle; the positioning tests are not counted as earned campaign progress.

A second native journey loads a genuine v0.12 active company with an already paid guard action. Every unit field and the RNG match at load. Its UI-driven continuation matches an independent patched-model checkpoint, including commands, RNG, outcome and final unit state. It then buys a club with actual crowns, deploys against woodland raiders, completes another battle and reloads. Total native journeys: three complete battles, plus that one model comparison. The six new archer screenshots were visually inspected for readable controls and messages.

## Save compatibility and scope

Schemas remain company 12 / battle 9. v0.12 and v0.13 saves keep their current state; corrected firing rules apply immediately to ongoing modern battles, so future outcomes may differ from the old build. Saves with pre-v0.12 historical weapon rules retain their old ray behavior until their next deployment.

This patch does not claim the planned v0.14 enemy/encounter work, direct attacks on camps, aggregated armour feedback or any new equipment content. The screenshot's earlier movement failure cannot be reconstructed exactly without that save. Tests establish the corrected rules and messages, not the unknown original cause of that particular step.

## Package

Source import, archive CRC, clean extracted import and a complete smoke battle are checked. Generated Godot caches and player saves are excluded. Benign software-display VSync warnings are allowed; script errors and failed assertions are not.
