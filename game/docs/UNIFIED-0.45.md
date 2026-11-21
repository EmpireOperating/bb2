# Unified playtest build 0.45

The 0.44 main prototype, latest cumulative world/raider preview, and latest cumulative dungeon patches now run in one Godot project. Earlier integration packs should not be overlaid on this release. Use this build as the base for subsequent work.

## Playtest assessment

Ready for an initial human playtest of the tested flows. No remaining blocking defect was found in the final checks. This is a source prototype for Godot 4.4.1, not a platform executable or a finished game.

Start a new company to exercise every current system. Seed 1 reproduces the verified opening: ordinary three founders and 300 crowns, purchase food, hire a fourth companion, sign the nearby camp contract, travel, win through legal tactical commands, return, purchase tools, read local directions and open the expedition journal. That native journey ended on day 1 with 323 crowns, 53 food and four survivors. Save/load was exercised at the signed contract, battle, aftermath and return. No company resources, recruits, visibility, positions or victory were granted; the travel driver knew the contract marker's coordinates.

No further feature work is recommended before this first playtest. Focus feedback on whether danger and retreat options are understandable, jobs cover real travel/recovery costs, directions and journals are usable, and equipment/perk choices make sense. Map labels still crowd near clustered sites. Difficulty, scouting behavior, founding frequency and dungeon provisioning remain provisional. These tests do not substitute for human judgment about fun or fairness.

## What is included

| Area | Current behavior |
|---|---|
| Main campaign | Existing armour layers, weapon actions, ammunition, perks, progression, contracts, trade, company formation and open-ended campaign |
| Economy and region | Six towns, farms, workshops, material inputs, physical freight and food carts, council funding, patrols and repairs |
| Camps and raiders | Resource-dependent survival and recruiting, physical founding, interrupted expeditions returning and retrying, personal danger memory, observed camp defenders and fading footprints |
| Dungeons | Nine generated sites, themes and boss tactics, multiple floors, map clues and keys, locked treasuries, persistent wounded garrisons, one-time stairwell caches and expedition journal |
| Information | Local dated reports, landmark directions refreshed by asking current locals, persistent text bookmarks and explored-only expedition estimates |

The old Regional Recovery implementation remains available for its historical saves and tests. New campaigns use the current material economy's repair/freight rules, as in the incoming world preview; the older controller is not additionally enabled and does not double-charge repairs.

## Merge provenance

The main input is Library version 49, `Battle-Brothers-2-Prototype-0.44.zip`, SHA-256 `97be07b9794fb9403105e737d48f19f16d4789ba689340e88537bcab48395748`.

The world input is the Raider Danger Memory integration pack and its complete cumulative source preview, head `6a54a6210847b385668479b522a0a8d1a2ffe3fe`. It includes the preceding world/camp/recovery work. The common 0.42 runtime was reconstructed by reversing the documented 0.43 direction patch from the exact 0.43 archive, then the world changes were merged into 0.44. This preserved the newer landmark and local-origin fixes.

The dungeon input is Stairwell Supplies. Its three supplied patches were first applied, with checks, to their exact 0.43 base. Their combined changes were then merged into the world-plus-main project. The only textual conflict was in the battle heading; both the fitted heading and unified version label were retained. The dungeon pack supplies its prerequisite feature chain; earlier features already present in the main prototype remain.

The incoming preview save path was restored to `user://ashen-company-save.json`. The perks laboratory retains its separate path. The latest Library inventory was checked again before packaging; no newer delivered main, world or dungeon input was found. Inventory, handoff manifests and merge records are in `unified-0.45/inputs/`; runtime hashes and the source diff are beside them.

## Fixes found during integration

1. **Dungeon-map drops without active dungeons.** The new dungeon rules defaulted to version 6 even when the site dictionary was empty. Camp and other battle victories in historical non-dungeon companies could index nonexistent barrows/complexes. The drop function now checks activation first. Camp-loot and ammunition continuations, plus a direct unchanged-state regression, pass without script errors.
2. **Company-screen overlap.** The new Expeditions button covered recovery and equipment help text. It now occupies the unused lower-right area.
3. **Obsolete objective text.** Open-ended companies no longer display the old four-win completion target on their company screen.

Test-only corrections are separately identified: the historical regional-recovery assertion now expects wrapper 35, which the incoming runtime already used to avoid collision with economy saves; the earned-vault UI driver creates its output directory; the fresh UI journey closes the market before selecting town tabs. Initial error logs remain marked as before-fix evidence. Final results below exclude interrupted/failed development runs.

## Current validation

- **27 model suites pass**, covering world rules, founding, danger memory, camp reconnaissance and loot, footprints, dungeon generation/tactics/placement/supplies/keys/journal, shared economy, legacy saves, directions and ammunition. Their 41,421 assertions include repeated seed/room checks; that count is not a count of independent scenarios.
- **Six native UI journeys pass** (139 checks): refreshed local directions; observed raider memory and expiry; camp construction/interception; earned stairwell cache, descent, town recovery and return; earned vault retreat/recovery/return/treasure; and the ordinary fresh-company opening described above. The final company layout was rendered and visually inspected separately.
- **Six 30-day careers pass their accounting/save checks.** All six reached day 31, with zero navigation aborts. Mercenary, trader and mixed policies ran on seeds 1 and 71 using the new raider and dungeon capabilities. These are two maps per policy, not human win rates or a statistically established improvement over 0.44.

| Policy | Seed | End day | Living | Crowns |
|---|---:|---:|---:|---:|
| Mercenary | 1 | 31 | 4 | 191 |
| Mercenary | 71 | 31 | 4 | 1023 |
| Trader | 1 | 31 | 3 | 40 |
| Trader | 71 | 31 | 3 | 141 |
| Mixed | 1 | 31 | 4 | 299 |
| Mixed | 71 | 31 | 4 | 970 |

The fresh career policies retain the earlier visible-terrain, written-clue and remembered-price boundary. They still use generic tactical AI and do not model skilled map-level scout avoidance. They do not traverse every dungeon. The native dungeon continuations load unmodified earned checkpoints from the dungeon branch; they verify those continuations in the merged executable but are not fresh unified careers. The raider/founding native cases retain the incoming explicitly documented observation/geometry/resource fixtures. These fixtures are not balance evidence.

Final result JSON and logs are under `unified-0.45/checks`, `native` and `careers`. Historical branch reports elsewhere in this archive remain historical and are not counted as tests of 0.45.

## Compatibility and reproduction

Old maps, earned items, dungeon geometry, claims, wounds and saved behavior versions are preserved. New companies select raider rules 5 and dungeon rules 6. Existing companies do not silently upgrade their world or reroll their dungeons. Legacy companies without active dungeons remain valid. A newer save is not promised to load in an older executable.

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/unified_campaign.gd
godot --headless --path . --script res://tests/unified_first_month.gd -- mixed 71 replay
godot --path . --audio-driver Dummy --script res://tests/unified_playtest_ui.gd
godot --path . --audio-driver Dummy --script res://tests/dungeon_supplies_ui.gd
godot --path . --audio-driver Dummy --script res://tests/earned_vault_ui.gd
```

Run native test scripts with isolated user data: they intentionally write their test saves. For ordinary play, import `project.godot` in Godot 4.4.1 and press F5. In the running game, F5 saves and F9 loads. The archive contains the whole project and its assets; no integration overlay is required.

## Rendered evidence

![Earned first contract victory](unified-0.45/player-journey/first-victory.png)

![Returned company with clear recovery text](unified-0.45/player-journey/returned-company-final.png)

![Persistent one-time stairwell supplies](unified-0.45/native/dungeon_supplies_ui/dungeon-supplies/native/supplies-available.png)
