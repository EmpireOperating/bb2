# Expedition journal

Based on Prototype 0.42, Library version 47, plus the five Dungeon Placement integration patches. This replaces the Keys & Vaults screen with an Expeditions screen. It is a separate merge pack, not a release or main-archive replacement.

## What the player gets

- A paginated list of discovered entrances and dungeons named by carried keys. Unknown key destinations show only the name and entrance-unknown status, with no room, floor, location or budget controls.
- Notes showing the deepest floor actually entered, visited/cleared room counts, observed surviving guards and unsearched rooms. A final chest recovered status does not claim every side vault is empty.
- A room diagram for visited floors: only seen chambers and connections, including cleared rubble shortcuts. Unvisited rooms have unknown contents. Inspected locked doors show key status without exposing their garrisons. Room details remember surviving enemy types and counts after retreat, and update after victory or looting.
- Keys grouped by known dungeon, retaining carried/missing, visited/unvisited and permanently unlocked door states. Floor labels on known-dungeon keys come from the existing key inscription.
- A supply planner from the company's current position to the selected entrance and onward to a chosen discovered town. Adjustable allowances: 0–7 extra exploration/recovery days and 0–20 new rooms. It shows food/wage requirements, carried resources and shortfalls. Planning does not spend or reserve anything.

## Information and estimates

Travel estimates are returned only when both endpoints and every point/midpoint on both production paths are explored. A dungeon map alone does not survey terrain. If the engine's chosen path crosses unknown ground, the whole estimate is withheld, even if a different longer familiar route might exist. The planner does not expose undiscovered towns, paths, distances or travel times.

Both legs use normal terrain costs and company movement speed; each is rounded up to the next three-minute step. New rooms add one hour and the existing scout ration cost. A basic half-hour exit is included; an already-active dungeon adds its known floor exit cost, and leaving a different current dungeon is also included. Deeper future exploration, searches, cleared-room traversal, stairs, hazards and detours must be covered by the player's extra-day allowance.

The clock counts actual midnights from the current hour, not rounded calendar days. Rations use all living company members, including reserves. Wages use their current wages plus existing arrears. Tools, medicine, ammunition, purchases, recruitment changes and unexpected delays are additional. Battles consume no world time. This is a planning estimate, not a readiness gate or a guarantee of survival.

## State and compatibility

The journal projects existing campaign observations; it stores no duplicate dungeon state and makes no campaign schema change. Existing room visits, enemy wear, keys, unlocked doors, searches and rewards remain authoritative. Four unchanged earned saves, including a 0.42 expanded-map/news company, load and round-trip exactly.

Selected tab/site/floor and budget allowances are transient UI choices. They remain during the current app session, including F5/F9, but reset on relaunch. Expedition progress itself is saved in the existing campaign data. Reading the journal pauses the world and disables camera shortcuts. View Entrance retains the prior camera-centering behavior for known entrances, and is unavailable underground.

Enemy strength, procedural layout, loot/drop rates, supply prices, wages and healing are unchanged. This work does not rerun or claim a new fresh-company balance audit.

## Verification

- `tests/expedition_journal.gd`: 59 checks, zero failures. Key-first/name-only behavior; mapped-but-unsurveyed routes; hidden content noninterference; read-only state/RNG; real battle damage, retreat and return victory; unsearched/looted transitions; remembered shortcuts; production midnight/ration/wage reconciliation; unknown route segment; exact older saves.
- Existing domain regressions rerun: vault keys 102, dungeon variety 3,699, placement compatibility 8, regional news 66; all zero failures.
- `tests/expedition_journal_ui.gd`: 32 checks, zero failures in rendered Godot. Declared key/map/survey fixtures exercise discovery, supply controls, shortages, nine-entry pagination and camera navigation. Separately, the exact earned day-29 retreat checkpoint is loaded without grants: five survivors return to three wounded archers, win one real battle, disarm the trap and collect 656 crowns. The journal updates before/after looting and preserves its observations through F5/F9. Ends at the vault on day 29 with five survivors and 952 crowns; no new journey home or fresh career is claimed.
- Seven screenshots of the final key-only, unsurveyed-route, supply, keys, remembered guards, cleared vault and recovered treasure screens were visually inspected. The overview's final wording received a grammar-only edit after that native run.
- `tests/vault_keys_ui.gd -- --journal-only` now uses explicit map discoveries as well as keys for the paginated expedition list; result is recorded separately in the pack evidence.

Use Godot 4.4.1. Import once with `godot --headless --editor --import --quit`, then run `godot --headless --script tests/expedition_journal.gd`. Native scripts require a real display and isolated user-data directory. New tests do not grant resources in the earned continuation; initial discovery/pagination fixtures are explicitly separate.
