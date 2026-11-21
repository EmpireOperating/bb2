# Living trade — isolated follow-up to the procedural map preview

This slice connects actual caravan and raider positions to cargo loss, player rescue, camp stores and town delivery. It builds on the delivered procedural-map integration pack (commit `5479b341d3c949bfa090937fd4b4704088a18010`), whose underlying game baseline was 0.27. It does not merge the other chat's 0.28 early-game work or replace the main prototype.

## Play

Start a new preview company. Seed **1** reproduces the native test: wait in Mosscross until W002 is visibly attacked, select its wagon and choose **Intervene**. The party is pursued while visible; losing sight stops pursuit. Reach it to open the existing tactical encounter. Victory rescues the cargo; the food stays with its caravan and is credited to the destination on arrival. The normal scout-battle reward is paid once.

For the unanswered-raid loop, let the raiders win. A wreck appears at the actual attack position. **Local rumours** prioritizes reports of missing shipments before the earlier discovery rumours. Travel to a wreck, **Read the tracks**, then **Follow tracks to camp**. Reading clues identifies the responsible camp without revealing surrounding terrain. The follow action is a normal physical journey to that camp, not a teleport. Visible sections of the recorded return trail are drawn on the map.

The save path is `user://ashen-company-living-trade-preview.json`. This does not overwrite either the main build's save or the earlier procedural preview's save. The preview remains a Godot 4.4.1 source project.

## Simulation rules

1. Waiting shipments launch on their existing economic schedule. Autonomous wagons then move at 14 map units/hour, modified by the existing terrain costs. They follow real navigation paths through their road's camp waypoint and onward to the destination.
2. Each camp's existing field party can seek unguarded freight on its associated trade road within a 250-unit detection radius. No extra enemies or free replacement parties are spawned.
3. A raid requires the party to reach within 18 map units of the wagon, outside a town's 45-unit shelter radius. The caravan stops. Its defence takes four world hours to break while raiders remain in contact. This is an aggregate NPC defence timer; player intervention launches normal tactical combat.
4. Successful raiders haul the cargo home physically. Cargo remains in transit and unavailable for camp recruitment/expansion until they arrive. Only then does the existing world ledger record it as seized food. The camp can spend that food under the existing rules.
5. Intervening during the attack or return journey can rescue the shipment. Victory removes that finite party, resumes the actual cargo from its current position and protects the rescued shipment for the remainder of its trip. Retreat does not rescue it or grant a reward.
6. Clearing a camp cancels its field missions and releases held cargo. The wagons still have to travel to their destinations. Stationed patrol protection can also abort a raid. Deliveries feed the same town stocks and treasuries as before.
7. Wrecks and tracks are evidence, not a repeat-loot source. Rumours, inspection, map knowledge and return tracks persist in saves.

The world owns all cargo, town food, camp food, spending and treasury accounts. `Traffic` owns movement, targets, defence timers, hauling, evidence and pursuit. The daily world simulation does not also move or seize autonomous freight when physical trade is enabled. New physical freight events update the company journal and trigger the existing autosave path.

Normal travel uses the existing fixed three-minute ticks. Pausing or opening a management screen freezes it. Instant legacy travel/rest helpers and the existing one-day battle settlement advance freight through one day of background ticks, without moving the company, charging upkeep twice or opening off-screen player battles. Post-battle escape grace is preserved. Council decisions still happen once at the existing day boundary.

## What stays deliberately limited

- One finite field party per camp generation, inherited from the map preview. A surviving party can raid again; defeating it does not generate a free replacement. Funded field-party recruitment is a later extension.
- Three towns, three camps and the existing discovery templates. No additional town-count or border-invasion system.
- Autonomous caravan interception is physical. Existing direct raids on town stocks and council patrol decisions remain daily economic rules.
- Existing paid escort contracts retain their ambush-stop/delivery flow and are distinct from autonomous caravan rescues.
- Tactical combat, equipment, ammunition, people, stats and perks retain the earlier baseline. No balance buffs were added to make rescue tests win.
- Evidence supplies an actionable camp clue. It does not yet implement survival skills, tracking uncertainty, branched trails or dialogue choices.
- The older full-month difficulty limitations remain. Ledger conservation and valid saves across a month do not establish that every seed is equally easy or enjoyable.

## Integration boundaries

| File | Change |
|---|---|
| `src/traffic.gd` | Physical wagons, finite-party missions, raid/return/rescue rules, evidence, pursuit, snapshot validation |
| `src/traffic_view.gd` | Raid/wreck rendering, caravan and evidence panels, intervention and trail controls |
| `src/campaign.gd` | Explicit capability on setup, physical clock ownership, rescue settlement, journal events, candidate-state restore |
| `src/overworld.gd` | Optional mission destinations and background movement; physical wagon positions for presentation |
| `src/world.gd` | `spatial_trade` capability bypasses the old daily autonomous movement/seizure loop |
| `src/main.gd` | Enable new companies, separate preview save, UI controls and state labels |
| `src/procedural_view.gd` | Inspected evidence can mark its camp without revealing terrain |

`Campaign.setup(company_seed, map_seed, true)` opts in. The third argument defaults to false, retaining existing callers and model fixtures. The preview UI opts in; the established `--smoke` fixture remains classic.

Physical-trade campaigns use **preview campaign schema 24** and a separate `traffic.version = 1` component. Prior procedural campaigns remain schema 23 and retain daily trade; classic campaigns remain schema 22. Loading them does not reroll geography, convert freight timing or alter an ongoing battle. The world ledger schema remains 2, overworld schema 1, tactical battle schema 19 and perk pool version 5.

**The merger must reconcile campaign schema numbers with the current main branch.** These numbers belong to the isolated 0.27-derived preview chain and must not be treated as a globally reserved schema after another chat's changes. Keep the trade component version and an explicit capability/migration decision; never infer physical trade merely from the presence of a generated map. All candidate objects are validated before any live state is replaced.

The incremental patch applies after the delivered procedural-map patch. The pack also includes a cumulative text patch from delivered 0.27 for review, plus the full source preview. On a later main build, merge shared campaign/clock/renderer hunks with the other chat's changes rather than replacing the project directory. Preserve their passive recovery, starts, equipment, weapon-switch and fog work.

## Verification

See the pack's `VALIDATION.md` and logs for final counts. New suites cover six full-month physical economies; mid-raid and mid-return roundtrips; real rescue combat; interrupted/retreated rescues; protection; finite rewards; camp victory followed by physical delivery; and malformed-state rejection.

`tests/traffic_ui.gd` uses a real seed-1 new company and actual mouse/key actions. It waits for a naturally occurring raid, follows and fights the raiders, verifies rescue and delivery, then starts a second company to investigate a naturally occurring wreck and follow its tracks. It installs no positional, resource, enemy or victory fixtures. Model branch tests explicitly identify their fixtures. Native screenshots in `docs/traffic-*.png` come from those UI journeys.
