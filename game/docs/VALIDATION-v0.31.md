# Validation — living overworld 0.31

4,461 assertions, zero failures in 16 final suites. Counts include repeated assertions, not that many unique scenarios. Tested with Godot 4.4.1 on Linux. Main base: delivered 0.30, Library revision 33. Incoming: Living Bands pack, commit 92db493, including its Living Trade dependency. Farm Supply is not integrated.

| Suite | Checks | Evidence |
|---|---:|---|
| `month_campaigns` | 2,004 | 16 companies, eight seeds, two unchanged cautious policies; actual travel, upkeep, battles, purchases, losses and endings |
| `living_integration` | 104 | Merged rosters, midnight recovery/upkeep, atomic rejection, original 0.30 and separate-preview save continuation |
| `bandits` | 585 | Strength decisions, scouting, persistent casualties, repeat encounters, corruption and six supplied month-long world simulations |
| `bandit_edges` | 52 | Visibility, grace, recovery, abandoned cargo, protection, three real camp wins and explicit voluntary camp withdrawal |
| `traffic` | 599 | Physical raids, hauling, rescue, evidence, delivery, six supplied world simulations and exact roundtrips |
| `traffic_edges` | 20 | Camp/patrol release, interrupted rescue, frame subdivision and single-owner freight timing |
| `campaign_progression` | 262 | 0.30 prices, grades, counts, guarded delivery, reoccupation and original 0.29 saves |
| `merged_maps_compat` | 150 | Original 0.28 and standalone-map saves and combat continuation |
| `inventory` | 31 | Four-AP swaps, Quick Hands, Bags and Belts, load/refill and live inventory saves |
| `recovery` | 21 | Partial hours, tools, shortages, medicine, temple treatment, scars and repair queues |
| `ammunition` | 291 | Ammunition conservation, 12 fresh battles and nine historical continuations |
| `equipment_economy` | 269 | Retained catalogue and prior economy; trades, repairs, 15 fresh fights and old companies |
| `opening_native` | 26 | Actual new company, fourth hire, camp victory, inspection, first mail, recovery, discovery and save/load |
| `band_native` | 18 | Actual visible-band pursuit, flight, catch, tactical victory, permanent party defeat and F5/F9 |
| `retreat_native` | 10 | Actual legal combat kills one raider; UI withdrawal retains survivor recovery, casualty and zero bounty |
| `trade_native` | 19 | Native natural raid, intimidation release, delivery, unanswered raid, wreck inspection and physical follow order |

## Full-month results

| Policy | Successful endings | Contracts | Battles | Deaths | Replacement hires |
|---|---:|---:|---:|---:|---:|
| balanced | 7/8 | 62 | 24 | 25 | 20 |
| lean | 6/8 | 51 | 24 | 20 | 9 |

The two production-policy drivers from 0.30 were retained, with only an explicit living-world capability and output filename added. Each starts with a fourth hire; balanced expands toward six and lean targets four. They use actual routes, upkeep, contracts, legal production combat AI, training, loot, purchases, sales and recovery. No extra company resources, forced damage, wins, rerolled casualties or teleported travel are used. They know map coordinates and favor guarded delivery work while avoiding under-equipped veteran camps. See [all 16 records](month-campaigns-0.31.json).

Thirteen companies succeeded and three wiped out: balanced seed 986 on day 23, lean seeds 198 and 789 on day 9. Lean seed 592 survived with one mercenary after eight deaths and five replacement hires. Forty-five deaths are retained; twenty-nine were replaced. Success is the authored four-contract/debt-free ending, not evidence of a healthy roster. These results do not establish final difficulty or an optimal build.

Compared with the prior release's recorded 16-policy cohort, living-world runs had fewer battles (48 versus 102) and more deaths (45 versus 19). Roaming decisions and physical freight alter encounter timing, training, loot and the economy together. This is an integration observation, not an isolated causal claim. Human early-game playtesting remains necessary. The first eight-company pilot was a subset and is not counted as additional evidence.

## Native journeys

The opening journey uses New company, hires a fourth member, accepts a first camp contract, travels, wins one real battle, inspects a companion, saves/reloads, buys/fits mail with earned crowns, recovers, enquires until it receives a discovery rumour, surveys/searches and reloads. Buying/fitting mail and resting use production campaign methods; the other actions use native controls. Fleeing scouts no longer force the two battles seen in the previous test.

The pursuit journey catches a naturally moving two-thug party, wins real tactical combat and verifies permanent defeat. A separate journey kills one raider through legal combat and uses the actual retreat control while one survives. It confirms zero withdrawal bounty, persistent death, return/recovery and exact F5/F9. No enemy health or victory fixtures are installed in these native journeys.

The trade journey observes an actual raid near the town, selects its overlapping wagon marker, intervenes and intimidates the band. It checks no company bounty/food award, actual cargo release and eventual delivery. A separate new company lets the raid finish, hears a missing-shipment rumour, travels to the wreck, reads its tracks and orders a physical route to camp. No position, resource, cargo or victory fixture is installed. Tactical rescue branches are covered by model tests; the native rescue is intimidation.

Native screenshots were inspected at 1440×900 with software OpenGL. V-Sync warnings are nonfatal. The tests exposed and fixed overlapping site click areas and selection loss when moving away from town. UI controls remain above map-marker hit testing. Historical preview screenshots are not presented as current native evidence.

## Models, fixtures and compatibility

The dedicated band/trade month simulations declare ample company supplies so hunger/debt cannot halt the world. They establish conservation, continuation and state validity, not playable company balance; only the 16 policy trials above measure unaided company outcomes. Model decision tests declare position, casualty, protection and camp-clearance fixtures where needed. Camp edge journeys produced three legal wins; a separate ordinary deployment and voluntary withdrawal covers the failed-assault branch without fabricated enemy damage.

Original 0.30 camp, ongoing-battle and aftermath fixtures were captured by executing the exact delivered archive (SHA256 70b970e851972d9f3480bbae7defd4e7bbcb52f1416bdcc0675d4ca4c6e4b043). Their snapshots, tactical continuation and settlement remain identical and do not enable living-world capabilities. Original 0.29/0.28 compatibility suites also pass.

Both isolated preview families were executed to capture actual original saves. Migration preserves all original fields except the campaign schema number, adds standard recovery state, and retains original geography, six-person starts, rosters, physical movement, AI and tactical/settlement continuation. Healthy preview-world continuation preserves every original field while the newly adopted recovery clock advances. Existing fights keep deferred recovery until returning to camp. New traffic and band components use version 2; old preview components remain version 1. Mixed/corrupt schemas, capacities, ratings and nonempty absent ranks are rejected atomically.

A combined midnight test verifies two hours of rest produce only two hours of repair/healing, one upkeep charge and the same physical freight clock. Existing inventory, ammunition, equipment and recovery suites pass. Tactical combat, armour, arsenal, people, progression, perks, recovery, map generation and all catalogues are byte-identical to 0.30. Full historical weapon matrices and map-generation sweeps were not rerun because those implementations did not change.

## Release verification

The archive passes CRC, clean extraction, full resource import, ordinary generated startup and the retained combat smoke check. It excludes Godot caches, generated import metadata, temporary capture scripts, helper tools and player autosaves. The new startup uses campaign schema 26 with progression 1, traffic 2 and bands 2. This remains a Godot source project; standalone Windows/macOS/Linux exports are not included or tested.
