# Farm supply preview

This isolated follow-up proves one rural supply chain: a generated farm outside the starting town, physical harvest deliveries, an existing band raiding it, interrupted production, and recovery after intervention. The full source preview is 0.27 plus the procedural-map, living-trade and living-band slices. It is not the main 0.29 build.

## Playing the slice

Open **Farm Supply** on the map, or click the discovered farm. The report shows its production, stored harvest, town stock, food price and recovery commission. Travel to the farm, its threatening camp, or its town using the report. **Guard & Rest** starts the ordinary 24-hour world-clock rest while at the farm; raids, wages, food use and other parties keep advancing.

The farm supplies the starting town's existing 24 food/day. Production goes into farm stores, then a cart carries 24 food into town along a reachable terrain-aware route. Town food and market prices change only when the cart arrives. Initially 24 existing town food is moved into farm stores; neither initial food nor daily production is duplicated.

The closest camp on a road serving that town owns the threat. Its existing roaming party may divert to the farm when it sees an opportunity. A raid requires the party to reach the farm, then remain for four world hours. Production stops during the attack. A completed raid takes up to 24 stored food, interrupts production, and starts 48 hours of required safe repairs. The same party physically hauls the harvest home; the camp receives it only on arrival.

A stronger approaching company can drive the band off. Defeating it or clearing its camp also frees carried harvest. Recovered food travels to town in a cart, without an immediate bounty or company rations. Repairs progress while the responsible road is protected, its field party is defeated, or a sufficiently strong company is within 60 map units of the farm. Leaving it threatened pauses repairs. Harvest resumes at a later daily production tick, followed by travel time to town.

After a raid, the town can reserve **60 council crowns** for a recovery commission. It can coexist with a normal contract. Accept and collect in the client town. Payment requires repairs plus arrival of 24 newly harvested food from the current incident or later; pre-raid carts and recovered stolen cargo do not qualify. A further raid resets delivery progress. Cancellation returns the reserved money to the council. The commission itself grants no XP, equipment or campaign-win credit.

## Integration ownership

- `farm.gd` owns placement, farm stores, harvest carts, raid progress, repairs and the commission. Placement is derived from the generated map without changing its nine location records or consuming campaign RNG.
- `World` remains the food and treasury authority. Its optional `farm_supply` dictionary accounts for food outside town and the current daily output. `World.tick()` books production once; `Farm.daily()` distributes that booked amount and launches the cart. Farm, cart and carried loot totals are checked against the world ledger on load.
- `Overworld` remains the movement and terrain authority. Existing three-minute ticks move carts and the existing band. `Bandits` checks farm orders after its strength/return decisions; `Traffic` excludes a party already raiding the farm. No extra band or tactical enemy roster is spawned.
- `Campaign` owns clock advancement, battle settlement and atomic save loading. Both normal map ticks and accounted background battle/rest/travel days advance the farm. Tactical contact freezes the contested raid. Pausing or opening company management freezes the map clock.
- `FarmView` owns the farm report, map drawing and controls. The map header now fits Farm Supply, Local Rumours, Councils and Trade without overlapping hit targets.

`Campaign.setup(company_seed, map_seed, live_trade, living_bands, rural_supply)` adds an optional fifth argument, default false. The preview UI opts in. Historical callers and schema-23/24/25 saves keep their original behaviour without silently adding a farm.

New farm saves use campaign schema **26** and farm component version **1**, with a separate `user://ashen-company-farm-supply-preview.json`. World remains version 2 with an optional extension; the campaign reader rejects that extension in older campaign schemas. Candidate objects validate before committing a load. Reconcile these numbers and the extension with the integrating branch: **26 is a preview allocation, not a globally reserved save version.**

The incremental patch targets living-bands commit `92db4935369e79b45141fe434a1a1e13867cceea`. Preserve the other chat's starting gear, passive recovery, weapon switching, fog, progression and intervening save changes. Review the hooks in `campaign.gd`, `world.gd`, `bandits.gd`, `traffic.gd` and `main.gd`; do not overwrite the main project with the full preview. Combat, equipment, perks, progression, people generation, map generator and world balance data were not edited for this slice.

## Deliberate limits

One farm supplies one town. This is the foundation for more producers and goods; it does not yet add mines, lumber camps, village populations or a general production network. Local harvest carts physically travel, but are not independently ambushable or selectable in this slice. Existing inter-town caravans retain their own attack/rescue system. Farm placement uses traversable nearby terrain and does not paint a new permanent road; its known route is drawn as a dashed path.

Safety is assessed against the farm's assigned camp and existing road protection. There is no general territorial influence simulation. Existing daily town-stock raids remain in the world model. There is no farm garrison, farm tactical scene, rebuilding-material requirement, or independent enemy equipment inventory.

Numbers are initial tuning. The full preview still uses the earlier heavily equipped starting company. A strong-looking company is not guaranteed a tactical victory: the actual journey tests include two lost camp fights and a completed seed-7391 recovery. Test difficulty and commission economics again after merging the other chat's starting-equipment changes.

## Validation

Run with Godot 4.4.1, for example `godot --headless --path . --script tests/farm.gd`.

| Test | Result / coverage |
| --- | --- |
| `tests/farm.gd` | 43 checks; conservation, actual production/delivery delay, natural raid, shortage/price, timed recovery, one payment, atomic corrupt-load rejection and exact older saves |
| `tests/farm_edges.gd` | 766 checks; interrupted hauling, rescued/late cargo exclusion, safe guarding, refund once, mid-raid continuation, 64 reachable generated farm layouts and six complete 30-day economies |
| `tests/farm_journeys.gd` | 26 checks; ordinary starting companies, public travel/contract APIs and legal tactical combat; seed 7391 completes camp clearance, repair, delivery and collection on day 7; seeds 7 and 8 lose their camp fights |
| `tests/farm_ui.gd` | 24 checks; native mouse/key journey with ordinary seed 7391, real world time, tactical victory, collection on day 7 and F5/F9 throughout; see the native log and actual `farm-*.png` captures |
| Existing regression checks | Bandits 585; bandit edges 47; traffic 599; traffic edges 20; traffic camp 49; procedural 14,798; overworld 1,339; overworld/perk compatibility 33; ammunition/perk compatibility 81; perk progression 226 — all pass |

The long economy tests add company money/rations only to prevent hunger/debt ending the simulation early. The edge test declares company-position fixtures to isolate intimidation and guarding; model recovery explicitly declares a camp-clearance fixture. The native journey and separate actual battle journeys do not inject resources, casualties or victory results.

**Known baseline test issue:** `tests/world.gd` fails its old v0.3/v0.4 migration checks and then accesses a missing `kind` key at lines 159/325. Running it on unchanged living-bands commit `92db493` produces byte-identical failure output. Its paired current-world economy checks run first; the historic migration script does not complete and was stopped by a timeout. Both logs are included. This preview does not claim that suite passes or change those old migrations. Current generated/farm saves and the listed compatibility fixtures pass their dedicated tests.

Earlier screenshots and historical validation documents remain evidence of their respective slices, not proof that every old native script passes with farms enabled.
