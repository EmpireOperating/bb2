# Validation — generated marches 0.29

18,180 assertions, zero failures in the final recorded runs across 16 suites. Counts include repeated assertions, not unique scenarios. Godot 4.4.1 on Linux; native UI under Mesa at 1440×900. These are the suites actually rerun on the combined build.

Built by merging the isolated procedural-map pack onto delivered 0.28 (revision 31). The combat, people, perks, weapons, armour and recovery modules, and every data catalogue, are byte-identical to 0.28. Campaign/UI/world/navigation changes reconcile both branches. The release fixes incomplete low-tier enemy kits and diagonal-road travel/ETA costs.

| Suite | Checks | Evidence |
|---|---:|---|
| `procedural` | 15,100 | 128 seeded maps, connectivity/spacing, deterministic generation, first-route bounds, diagonal road ETA versus travel, fog/save/exploration/reoccupation rules |
| `procedural_journeys` | 184 | Eight real generated campaigns: six camp victories, two defeats and seven scout battles; economic conservation and roundtrips |
| `opening_routes` | 328 | 32 ten-day policies over 16 matching seeds; actual spatial travel/contact/combat, recovery, earned mail and upkeep |
| `merged_maps_compat` | 150 | Three original 0.28 and three isolated-preview companies; camp, ongoing battle and aftermath; exact combat/settlement and migration |
| `scout_equipment` | 84 | 12 low-tier encounters, including weapon families without a tier-one item; complete enemy equipment |
| `opening_compat` | 63 | Three captured 0.27 companies: original fields, exact commands/RNG/casualties, settlement and camp adoption |
| `inventory` | 31 | Four-AP swaps, Quick Hands, Wait, shields, extra bags/load/refill and live inventory saves |
| `recovery` | 21 | Partial hours, reload continuation, travel/camp recovery, tools, shortages, temples, scars, queues and midnight |
| `overworld` | 1,339 | Classic routes, physical services, clocks, pursuit/evasion, contacts, escorts and corrupt saves |
| `ammunition` | 291 | Ammo conservation, attacks/reloads/refills, purchases/salvage/retreat, 12 real fights and historical continuations |
| `equipment_economy` | 269 | 26 weapons, markets, trades, queued repairs, merchant accounts, 15 fresh fights and historical companies |
| `perks` | 134 | Shared perk progression, purchases, costs, pools and saves |
| `hammer_dagger` | 94 | Both controllers/offhands, costs/damage, chain/debuff timing, AI, previews and older continuations |
| `playability` | 42 | Forecasts, feedback, guide persistence and a complete escort |
| `opening_ui` | 23 | Native classic-map fog, three-person roster, Bags, temple purchase, F5/F9 and paused enemy-turn inspection |
| `merged_maps_ui` | 27 | Native seeded start, hire/contract, two real battles, inspection, mail upgrade, recovery, rumour/survey/search and saves |

## Opening balance

| Policy | Contract wins | Company wipes | Survivors | Mail purchases |
|---|---:|---:|---:|---:|
| Three founders, direct assault | 12 / 16 | 3 | 31 / 48 | 12 |
| Fourth hire, town recovery | 13 / 16 | 1 | 42 / 64 | 13 |

The sample follows 16 matching company/map seeds in each policy using legal combat AI and actual three-minute overworld steps. The fourth-hire policy returns to town and recovers for 24 hours after scouting fights before attempting the camp. Policies then return, provision, buy/fit mail when earned money permits, and rest/provision through the end of day ten. They do not receive free XP, money, equipment, damage bonuses or forced wins. All contract winners buy and fit their first mail. No surviving company has unpaid wages at the checkpoint. Initial routes in this sample take 6.67–7.77 game hours. [Raw rows](opening-routes-0.29.json).

This is one opening contract plus recovery/equipment purchase and ten-day upkeep, not multiple-contract progression or a month-long economy test. The policies vary party size and recovery decisions together, so their results do not isolate the fourth hire. Test navigation knows destination coordinates; it is not a human wayfinding study. Death and failed contracts remain possible. The 128-map sweep additionally checks connectivity, separation, deterministic generation and first-route travel of at most sixteen hours; it is a sample, not a proof covering every possible seed.

## Native journey

The final generated-map UI run completes 27 checks with two real battles by day five: enter a seed through New company, hire a fourth companion, accept the contract, travel, inspect in battle, save/load, defeat scouts/camp, return home, buy/fit short mail, recover, hear a rumour, survey/search a watchtower, and reload partial/completed exploration. Map movement, recruitment, contracts, inspection, exploration and save controls use real UI input. Mail purchase/fit and safe resting invoke production campaign methods. Combat uses the normal AI with no outcome or resource injection. The finished screenshots are included in [map notes](PROCEDURAL-MAPS.md).

The separate opening UI suite uses declared fixtures for Bags and Belts and temporary injury care. It checks the retained classic-map fog and read-only inspection during an enemy activation, including stopping processing and blocking action keys through the modal. The Mesa V-Sync warning is nonfatal. Screenshots were visually inspected.

## Save compatibility

Compatibility fixtures were captured by executing the actual delivered 0.28 archive and isolated procedural preview, not fabricated by decrementing a current snapshot version. Three seeds from each retain their original people, equipment, geography, economy and ongoing battles. The continuation comparisons preserve commands, RNG, casualties and settlement; 0.28 recovery state also remains exact.

Classic campaigns keep schema 23. Generated campaigns use schema 24 with complete stored region definitions; generator definition 2 applies only to new maps. Definition-one worlds retain their geography. The reader explicitly distinguishes preview schema 23 with a region from delivered 0.28 schema 23 without one, validates each subsystem before committing, and rejects ambiguous payloads. Preview companies retain their six-person roster and adopt timed recovery at camp. Normal saves still use `user://ashen-company-save.json`; the separate preview filename is not automatically selected. A new company is required to get generated geography and the revised opening placement.

The diagonal-road regression compares estimated arrival against actual three-minute travel in both directions. Legacy fixed-map travel retains its old cost path. Old saved ongoing tactical battles are unaffected.

## Scope and packaging

Earlier validation remains historical: [0.28](VALIDATION-v0.28.md), [0.27](VALIDATION-v0.27.md), and [isolated map preview](PROCEDURAL-MAPS-PREVIEW.md). The 6,600-person background sweep, full weapon matrices and all older native suites were not rerun for 0.29. Older whole-campaign scripts can retain their original start/repair assumptions; only the table above is claimed as current passing evidence.

The region still has three towns, three camps and three discoveries. Tactical maps retain their authored templates. The campaign ends after thirty days. Wagons/patrol economics settle daily; independent caravan interception, arbitrary region sizes, deeper injuries and external invasions remain future work. Complete regional clearance prevents outside band spawning. Camp reoccupation is constrained by the four-calendar-day quiet period, funding and patrol rules. This is a source project, with no platform executable exports.

Archive CRC, clean extraction/editor import, normal generated startup and the retained classic-map combat smoke check pass. The archive excludes Godot caches, generated import metadata, player saves and temporary tooling.
