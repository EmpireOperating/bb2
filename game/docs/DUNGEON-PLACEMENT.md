# Dungeons across the expanded region

Built against Prototype 0.42, Library version 47 (SHA-256 d9453478d01cdd12e6477b19119bd9bec73f7056fc4617a10ddac799df941716), with the boss tactics, dungeon variety, world vault keys and earned-vault audit prerequisites ported onto it. Regional news is retained. This is a separate integration pack; the main archive is not replaced.

## Player behavior

New entrances on the expanded region are placed by travel time from the nearest town, using the company's actual pathfinding, terrain costs and movement speed. They avoid roads and keep at least 80 world units from existing sites/farms and one another.

| Sites | One-way travel from nearest town | Role |
| --- | --- | --- |
| Three small barrows | 5–14 hours | Shorter supply runs; one reachable from the starting town within 14 hours, at least one in each district |
| Blackbarrow, Fallen Watch, two tier-two procedural complexes | 14–28 hours | Longer expeditions with multiple floors and better final rewards |
| King's Sepulchre and the tier-three procedural complex | 28–48 hours | Two remote high-tier sites, one in each district |

These are placement bounds, not player-facing difficulty gates or promised safe journeys. Road encounters, exploration, fighting losses, room actions and recovery can extend a trip. Return paths can differ in cost. Enemies, loot tables, named-item chances, supplies and combat rules retain their prerequisite behavior; strength does not scale with the company. Barrows can still kill inexperienced founders.

Keys name dungeons without revealing entrances or terrain. Maps and discovery retain their existing roles. The key journal's View Entrance button now centers the expanded camera on an already-known entrance. It does not issue a travel order or reveal fog. Regional-news keyboard/modal handling coexists with the key journal.

## Persistence

Only generation of new entrances in geography version 3 uses these placement bands. Old fixed/small maps use their previous placement. Loading any existing dungeon preserves its exact location, rooms, enemy wear, key state, loot and named rewards, even on an expanded map. The older version-two adoption flow may add six new sites but never moves its existing three. No schema bump or forced migration is necessary: complete entrance coordinates were already saved.

## Verification

- Twelve world seeds, including 999999999: 1,734 checks, zero failures. All 108 entrances reachable from all six towns; reproducible layouts, distinct positions, both districts populated, Save/Load and no company scaling. Travel validation independently issues actual overworld orders and reads the company's remaining travel time.
- Measured nearest-town times: barrows 5.01–13.39h, middle sites 14.35–27.79h, remote sites 28.16–39.41h.
- Separate compatibility run: 8 checks, zero failures, on four unchanged earned fixtures: old boss, vault entry, vault retreat, and the 0.42 expanded-region/news company. Snapshot round trips are exact.
- Existing regression suites: vault keys 102; dungeon variety 3,699; boss tactics 153; earned-vault return 26; expanded region 28; regional news 66. All zero failures. These are this pack's reruns, not inherited claims from the old evidence.

## Fresh-company audit

Four fixed seeds use the existing earned-vault policy with `--expanded --known-garrison`, ordinary three-founder starts and no grants or forced victories. Horizon 45 days; stop on successful vault return or actual loss. Every crown reconciles. All four runs completed: 757 checks, zero failures. A simulation loss is a recorded outcome, not a test failure.

| Seed | Outcome | Living / deaths | Crowns | Completed barrows |
| --- | --- | --- | --- | --- |
| 1 | Vault treasure brought home on day 36 | 6 / 2 | 867 | 2 |
| 71 | Company wiped out on day 4 | 0 / 4 | 199 | 0 |
| 592 | Unpaid wages caused disbanding on day 40 | 5 / 3 | 0 | 1 |
| 789 | Unpaid wages caused disbanding on day 34 | 6 / 5 | 0 | 2 |

Seed 1 returned to a previously fought vault and recovered a 742-crown chest; its successful return trip took 3.10 days and netted 756 crowns after wages, gear purchases and equipment sales. It had lost two mercenaries during earlier vault attempts. Both completed barrows in that career yielded named equipment; the vault itself did not. Other barrow return trips sometimes earned a profit, sometimes lost money after casualties and recruitment.

The policy knows town coordinates and current remote prices for trading, so it is an optimistic economic benchmark, not an information-limited human win rate. Dungeon destinations require actual discovery/maps; keys reveal no location. There is no matched pre-placement control on the expanded map, so these results do not establish that placement improved survival. No earned high-tier remote clear was demonstrated. They do establish reachable shorter expeditions and an earned retreat/recovery/return vault success in the new geography. Balance remains punishing.

The JSON reports are written immediately before the final two Save/Load assertions; terminal logs contain the final check counts. Reports and exact earned checkpoints are included, with no failed exploratory runs mixed into the evidence.

## Reproduction

Use Godot 4.4.1. Import the project once with `godot --headless --editor --import --quit`. Run `godot --headless --script tests/dungeon_placement.gd`; `-- --compat-only` runs only the preserved-save cases. For each seed in 1, 71, 592, 789 run `godot --headless --script tests/earned_vault_hunt.gd -- SEED 45 expanded --known-garrison --expanded`.

The new native script is `tests/dungeon_placement_ui.gd`. It uses a declared six-person gear/XP/supply fixture and real UI controls, battles, travel, paid supplies, recovery and Save/Load. Its result is mechanics evidence, not an earned campaign. The completed native run passed 32 checks with zero failures: six survivors returned home on day 4 with 2,909 crowns from the declared 3,000-crown start. It exercised actual battle withdrawal, paid tools and 24-hour recovery, re-entry with exact enemy wear, victory and travel home. It also checked unknown-key restrictions, a mapped remote entrance, pan/zoom and F5/F9 at four checkpoints. Four screenshots are included. No final chest was collected in this mechanics run.
