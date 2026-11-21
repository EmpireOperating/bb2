# Raider survival and the shared food economy

Isolated branch `world/raider-survival`, based on camp-reconnaissance commit `c0c5c0a87a142d673d328ae75ad82c3d10e905a4`. This is a separate integration slice for the merging chat, not a replacement for the newer main build. Reconcile it with that build's town economy, trade goods, progression, perks and dungeon changes.

## What changes in play

Raiders now need food for the people who actually exist. Residents, recruits in training and reserves eat from the camp's existing food stores. Field parties carry their own rations. A hungry band can seek freight, return for available provisions, accept somewhat greater risk, or stop in quiet woodland to forage. Paid healing, recruitment, threat growth and reoccupation must leave a food buffer.

A freight raid still requires physical interception and the ordinary four-hour defence timer. Success transfers a limited amount of the actual caravan cargo into the band's pack. A partly looted caravan continues with its remaining food and is protected against another raid on that journey. An emptied caravan is plundered. The band must physically return home to deposit excess food. Farm raids retain their existing physical harvest-and-return mechanism; well-supplied bands skip them.

Camp destruction only settles the defenders present. An away party remains on the map with its existing ID, members, wounds, position and carried food. It becomes displaced, can raid visible freight, flee, hunt a weaker visible company, forage and be fought. It receives no replacement members or camp healing. If another group later occupies its old site, the displaced party keeps its original occupation identity and remains independent.

Winning a field battle recovers that band's remaining rations once. A camp victory recovers loose stored food and the packs of participating home defenders; captured town wagons still return to their towns. Existing money rewards and occupation-specific named-equipment promises are unchanged. Save/reload cannot reroll named loot or refill food.

Visible party details describe hunger/displacement qualitatively. No remote stock counter was added. Existing footprints still fade and expire on their original four-hour schedule.

## First-pass rules

| Rule | Value / behavior |
|---|---|
| Initial provisions | Three days per initial living camp population, entered once in `World.initial_food`; two days of each initial field party's share starts in its pack. |
| Daily upkeep | One food per living person. Field mouths are charged to packs, including while home; they are not also charged as residents. |
| Camp foraging | At most two food per day while at least one permanent resident lives; existing nearby guard pressure can prevent it. |
| Field foraging | A hungry band resting in unguarded woodland can gather enough for today's shortfall, at most two food. It provides no surplus, healing or members. |
| Provisioning | At home, retain two days of field rations, deposit excess and load shortages while protecting two days of resident food. No remote transfer. |
| Carry capacity | Six days per living field member. Casualties do not delete existing supplies, but the smaller group cannot take more until below capacity. |
| Investment buffer | Three days of the occupation's current living population, beyond the existing food cost of care/recruitment/growth/expansion. |
| Hunger | A short ration increments consecutive hungry days; a full ration resets them. From the third hungry day, lose 120/1000 health per day. Deaths persist. Starving reserves/trainees can desert; spent training food is not refunded. |
| Raid risk | Ordinary freight threshold: 100 power; hungry threshold: 60. Hungry groups tolerate somewhat stronger visible company/guard pressure and weight nearer food more heavily. Existing guard combat and strong-company escape still take priority. |
| Targets | Visible, unguarded freight outside town sanctuary, including a visible neighbouring route. Distant town stocks and caravan positions are not queried to choose a target. |
| Camp loss | No automatic defeat of away bands. An occupation with no living residents, recruits or attached field members can become abandoned. |

Small groups can subsist locally. Successful raids provide the surplus for faster rebuilding and growth; subsistence does not imply free reinforcement. Larger populations consume more than the camp's fixed forage yield. These values are tunable first-pass rules, not final economy balance.

## Shared accounting and integration hooks

There is no raider market, currency, pricing simulation or parallel town stock. Food remains in `World` throughout camp storage, cargo theft, carrying, unloading and consumption. Local forage enters the existing `produced` counter. Recovered player food leaves the world through the existing `sold`/player-transfer counter. Every save continues to enforce:

`food_total = initial_food + produced - consumed - sold - raider_consumed`

`World.raider_supply` version 1 adds party-keyed packs with `food`, `loaded`, `looted`, `foraged`, `eaten`, `lost`, `returned`, and `recovered`. Each pack has its own stock-flow equation; world totals also include it. In this mode, caravan `spent` includes food transferred into a pack, so downstream integration must not interpret every increment as immediate consumption. A band's remaining food lost to non-player defeat is explicitly booked as lost/consumed.

`src/raider_needs.gd` owns needs and decisions. The optional sixteenth setup argument on this branch is `raider_survival=false`, after `camp_reconnaissance`. Merge by parameter meaning, not position. It requires the reconnaissance capability and its existing living-camp/tracking/progression prerequisites. Setup runs after reconnaissance; field and resident feeding run during camp daily upkeep before recruits transfer into parties; buffered world growth runs afterwards. This charges an assigned recruit once on assignment day. New-company UI enables it, while `--smoke` keeps the legacy path.

The optional root component `raider_needs` version 1 stores occupation/day hunger records and each band's lost-home day. `World.raider_supply` and this component must be present together. Living-camp records gain `deserted` and `cancelled` only with the capability. Restore validates population/training accounting, pack identities and balances, timestamps and defeated-party food. The existing campaign and overworld wrapper versions are unchanged. Older saves omit the capability and retain their exact old behavior; there is no automatic conversion of an established economy.

Main integration points:

- `World`: camp withdrawal without consumption; portable transfers, food totals and restore; skip old flat upkeep and abstract town-stock raids in this mode; apply buffered growth after feeding.
- `Campaign`: setup, midnight ordering, paired save restore, battle food settlement, region security, original-generation displaced encounters.
- `Overworld`/`Bandits`: keep away parties when a camp closes; provision at physical home arrival; needs-directed movement and freight decisions.
- `Traffic`/`Farmstead`: real cargo transfer, surviving freight, displaced-party missions and need-sensitive farm attacks.
- `CampLife`/`CampRecon`: population upkeep, buffered investment, recruit losses and participating home-party food settlement.
- `BanditView`/`main`: qualitative party state and isolated preview save `ashen-company-raider-survival-preview.json`.

## Limits and next integration work

- Displaced groups do not found new camps, join another camp, merge, barter, recruit, or fight rival bandit factions in this slice. Existing food-funded reoccupation remains an abstract transition between known sites after its existing delay; it is not a physical founding expedition.
- Farm raids still use the original camp-associated party and return route. A camp's fall releases an unfinished farm haul through the existing recovery path. Displaced parties can raid freight but do not start a new farm-raiding network.
- Theft targets the food resource available on this branch. Connect newer trade-goods cargo through the same transfer hooks when merging; do not invent duplicate food stock or prices.
- Permanent residents retain the reconnaissance system's persistent casualty slots. There is no new resident healing service. Tactical battles still freeze campaign time.
- Freight traces use the existing wagon-raid evidence marker even for a partial theft. They do not grant a permanent route to the raider; footprints retain their independent expiry.
- The 20-day observer runs show field populations becoming much smaller under patrols and hunger. Merge against the developing town economy and tune provisions, deliveries, guard pressure and recruitment together before treating the result as final balance.

## Validation

See `raider-validation/summary.json` and its raw logs for exact check counts and results. `tests/raider_survival.gd` declares position, resource and battle-damage fixtures explicitly, and verifies real transfer/settlement paths, hunger, finite members, displaced raids, original-generation reoccupation encounters, one-time recovery, old-save preservation and atomic malformed-save rejection.

`tests/raider_observation.gd` runs seeds 1, 7 and 27 through day 21 with company-survival grants only. Seed 7 has a declared day-six camp-clearance stimulus; the other worlds receive no intervention. Daily food/treasury balance and periodic exact JSON round trips are checked. `raider-observation.json` records the resulting raids, feeding, forage and population counts. It is a mechanics observation, not a difficulty claim.

`tests/raider_survival_ui.gd` uses native X11 rendering and normal input: watch, physical departure, approach, legal camp combat, victory, selection/pursuit of the surviving band, and F5/F9 before, during and after. It declares home-rest, approach, survival-grant and final visibility fixtures. Combat uses ordinary founders/gear and legal tactical AI, without injected damage/results. Screenshots are `docs/raider-native-*.png`.

Run with Godot 4.4.1:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/raider_survival.gd
godot --headless --path . --script tests/raider_observation.gd
godot --path . --script tests/raider_survival_ui.gd
```

Regressions cover camp reconnaissance, living camps/named loot, band AI, freight, fading tracks, regional recovery, hinterland dungeons and battle clock behavior. The isolated integration patch is verified against its exact parent tree; automatic application to a newer main build is not assumed.
