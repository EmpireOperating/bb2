# Three-town hinterlands — isolated integration slice

Based on integrated campaign 0.33, not a replacement for the balance or dungeon branches. New companies enable three farmsteads and three physical council patrols. Existing saves retain their saved one-town or older capabilities exactly.

## What is playable

- Each existing generated town has one reachable farm, a visible footpath through explored terrain, physical harvest carts and one distinct adjacent threatening camp. The layout follows the saved map seed. Farm clearings remain separated; new dungeon entrances avoid all three.
- Food reaches the local market only when the actual cart arrives. Production, rural stores, stolen loads, deliveries and consumption balance across all towns. Farms can be raided independently while other towns continue receiving food.
- Every council forms, pays, heals and replaces its own guards. Parties depart and recover at their actual home town. Coverage stays near paid, surviving guards; the old abstract road-wide protection is disabled for all three councils. Two patrols assigned the same road cannot claim the same band simultaneously.
- Farm Supply and Town Guard select the town currently visited. Their town tabs become available through exploration. Each visible farm and guard remains directly selectable on the map.
- Town reports record the day and whether the farm was damaged; remote conditions do not silently refresh that report. A report marks the farm, not the responsible bandit camp or surrounding terrain. Reach an actually raided farm and inspect its tracks to identify that camp. The resulting route is available through Follow Tracks to Camp. Evidence records the raid date and generation, not the camp's current strength. The learned camp location persists when later attacks leave new evidence.
- A recovery commission belongs to its own council: 60 crowns held in escrow, safe repairs, 24 fresh food delivered after repairs, and payment back at that town. Recovered loot and old deliveries do not complete it. Cancelling refunds that same council. Three commissions can coexist.
- Camp clearance retains the existing four-day minimum quiet interval and food-funded reoccupation by a mature neighbouring band. Defeating a field patrol does not clear its main camp. Guards withdraw if the company takes over tactical combat, as in 0.33.

## Regional supply

| Town role / stable ID | Working farm output | Town consumption | Harvest cart |
| --- | ---: | ---: | ---: |
| Farming / ashwick | 24/day | 6/day | 24 |
| Market / stonecross | 4/day | 8/day | 4 |
| Mining / dunmere | 6/day | 6/day | 6 |

Displayed town names come from the seed. The market town's four-food kitchen garden is the one new production source; it remains dependent on imports. The other farms move existing abstract production into physical deliveries. Initial rural stores are transferred from town stock: 24, 4 and 6, with no new starting food. Existing data files and combat/progression rules are unchanged. The new capability derives output as `max(4, configured production)`; cart loads are capped at 24.

## Controls

Start a new company in the preview. In a town, choose **Farm Supply** or **Town Guard**. Visit the farm, inspect actual raid tracks, follow them, guard the farm, or accept local recovery work. **Support the Guard** spends 90 company crowns into the selected local treasury; wages and recruitment still take time. F5/F9 preserves all regions together.

The preview uses `user://ashen-company-hinterlands-preview.json`, separate from the main game's save. Load older files through an explicit backup/copy if testing compatibility; there is no automatic adoption of three-town rules for an existing company.

## Save and integration boundary

- Campaign wrapper stays 31. Farm and guard component version 2 explicitly identify the regional capability. Their version-1 data continues to load and round-trip unchanged.
- `Campaign.setup` has one additional optional final argument, `hinterlands=false`. The preview's two new-company entry points pass true. Existing callers retain their original behaviour.
- `farmstead.gd` owns one town's state. `farm.gd` aggregates all three while preserving the inherited first farm's public fields for old consumers. Use `farm.for_town(town)`, `farm.all()` and `farm.raid_for(party_id)` for regional code.
- `world.physical_sites` is derived from saved farm/guard capabilities, never independently trusted from a save. `world.has_physical(faction)` replaces singleton faction comparisons.
- World farm supply keeps its original first-town fields, plus two keyed regional entries. The world ledger checks the sum, and every farm cross-validates its own stores and output.
- The only dungeon change is its occupied-position list during entrance placement. Preserve the dungeon chat's other work when merging.
- `main.gd`, `campaign.gd`, `world.gd`, and `bandits.gd` have small integration edits. Keep the balance chat's changes to their current versions. The standalone preview title and save filename are intentionally separate; choose the final main-build title/path during integration.

## Verification and boundaries

See `HINTERLANDS-VALIDATION.json` and the merge pack's `validation/` logs. New checks cover 64 generated layouts, independent production/deliveries, per-council funding, actual raid transitions, local commissions, stale reports, trail discovery, corruption rejection and old capability saves. Six thirty-day observer simulations use extra **company** money/food solely to keep the observer alive; council resources, food, patrols and bandits are unmodified. They are world-simulation checks, not earned campaign wins. A separate entrance-position and extra-rations fixture verifies two days of dungeon rest, outside raids/production, all three ledgers and composed saves on two seeds.

The native seed-1 journey uses an ordinary three-founder New Company, real mouse/key controls and actual travel to all three towns and farms, reaching day four. No position, funds, supplies or battle outcomes are injected in that journey. It encounters no tactical battle, and it inspects evidence from the mining town's real raid. A separate native action suite declares company-position fixtures to isolate each council's support, commission escrow/cancellation and F5/F9; its raids and money still come from production rules.

**Balance handoff:** all six observer months ended with each council patrol having defeated its initial roaming band, with no guard setback. This produces a quieter late month under baseline 0.33 strength rules. No difficulty certification is claimed. Field bands remain finite per camp generation; active camps do not automatically conjure replacement parties. Reoccupation still requires the existing neighbouring-band conditions. Broader camp recruitment or outside reinvasion is a separate feature, not implemented here.

Other retained limits: three towns/camps, thirty-day prototype, one farm per town, farm carts cannot independently be attacked once launched, town-stock raids still use the existing daily abstraction, and no mines/logging production, guard equipment simulation, allied tactical guards or regional population pool.
