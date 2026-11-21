# Validation — company progression 0.30

3,708 assertions, zero failures in 11 final recorded suites. These are repeated assertions, not that many unique scenarios. Godot 4.4.1 on Linux. The source is based on delivered 0.29, revision 32.

| Suite | Checks | Evidence |
|---|---:|---|
| `month_campaigns` | 2,287 | Sixteen full-month policies across eight seeds: real routes, contracts, combat, recovery, training, recruitment, purchases, sales and endings |
| `prior_rule_baseline` | 349 | Eight companies using the final policy driver and retained 0.29 campaign rules |
| `campaign_progression` | 262 | Versioned prices/saves, graded kits/counts, finite guarded deliveries, reoccupation, corrupt-rule rejection and captured original 0.29 continuations |
| `merged_maps_compat` | 150 | Original 0.28 and isolated-map saves: all original fields, ongoing battles and settlement |
| `inventory` | 31 | Four-AP swaps, Quick Hands, bags, shields, load/refill and live inventory saves |
| `recovery` | 21 | Partial hours, tools, shortages, medicine, temples, scars, repair queues and midnight |
| `ammunition` | 291 | Ammo conservation and refills, 12 fresh battles and earlier continuations |
| `equipment_economy` | 269 | Retained catalogue and historical economy: 26 weapons, trades/repairs, 15 fresh fights and old companies |
| `opening_native` | 27 | Native 0.30 start, hire, two real battles, first mail, recovery, discovery/search and save/load |
| `progression_native` | 15 | Declared quiet-region fixture: real guarded-delivery UI, mail purchase quote/charge, planner and save/load |
| `earned_month_view` | 6 | Load an actual earned day-31 company through F9, inspect roll/memorial, save and reload |

## Full-month results

| Policy | Successful endings | Contracts | Battles | Deaths | Replacement hires |
|---|---:|---:|---:|---:|---:|
| Expand toward six | 8/8 | 61 | 49 | 10 | 10 |
| Keep four | 8/8 | 63 | 53 | 9 | 9 |

Both policies begin with a fourth hire, use actual three-minute world steps, take repeated clear/recover/escort jobs, train earned attributes/perks, equip loot, buy layered upgrades, sell surplus, provision, recover and reach the actual month ending. The larger policy expands toward six; the lean policy keeps four. No extra resources, stat bonuses, forced victories, reset casualties or teleported travel are used. Every reported death is retained and all nineteen are eventually replaced. The hire ledger counts each person, including multiple replacements after a single fight. [Full rows and hire/purchase histories](month-campaigns-0.30.json).

These policies exploit available guarded delivery work and avoid veteran camps unless adequately equipped. They know map coordinates and use the production combat AI. All sixteen succeeding is evidence of viable cautious strategies, not final difficulty or proof that every build/seed is fair. The baseline runs use the final policy driver against retained prior campaign rules: all eight wipe out after one or two jobs. Prices, encounters, work availability and the policy's response to their labels vary together; do not attribute the difference to one mechanic. [Baseline rows](month-baseline-0.29.json).

Expanding companies finish with mean body capacity 81.5 per mercenary; four-person companies finish with 119.0. That is a tradeoff within these purchasing policies, not a universal optimum. Mail purchases range from early first-contract upgrades to late-month acquisitions. Loot contributes additional armour. Top-tier equipment and veteran assaults are not exhaustively balanced by this sample.

## Native evidence and fixtures

The opening native journey enters a seed through New company, hires, accepts a contract, travels, fights two actual encounters, inspects in combat, saves/reloads, buys/fits mail, recovers, surveys/searches and reloads completed discovery. Mail purchase/fit and recovery use production campaign methods; the other interactions use UI controls. It grants no resources or wins.

The guarded-delivery UI test uses an explicitly cleared-region fixture to isolate a peaceful caravan route. Real controls accept the shipment, travel via the checkpoint to the destination, buy short mail at the new quoted price and reload. It does not establish an organically cleared region. Screenshots show the current quote, planner guidance and consistent purchase charge.

The month-end UI test loads an actual earned seed-198 result: seven fulfilled contracts, two deaths and two replacements, six living members at day 31. It uses F9 and checks the roll/memorial, equipment and exact save/reload. It does not simulate a whole month through native clicks. A separate one-company replay reproduces this result; it is a duplicate showcase, not an extra independent member of the sixteen-company cohort.

Native screenshots were inspected at 1440×900 using software OpenGL. Unsupported V-Sync warnings are nonfatal. Cosmetic equipment and unavailable ended-company items no longer display misleading weapon/two-hand labels.

## Compatibility

The v0.29 compatibility fixture is captured by executing the original delivered archive, not by modifying current snapshot version numbers. Three original companies retain camp/battle/aftermath data, commands, RNG, casualties and settlement exactly. Older 0.28/preview compatibility tests also pass.

New native games explicitly enable campaign schema 25/progression version 1. Missing, unknown or mistyped versions are rejected before mutation. Prior saves retain their rule version, prices and geography; no automatic difficulty conversion is attempted. The save filename is unchanged. New-company creation is required to use this release's balance. Third-party tooling can call `Campaign.setup(seed, map_seed, true)`; the omitted third argument retains historical behavior.

Combat, people, perk, armour, weapon, recovery, world, map-generation and navigation implementations and all data catalogues remain byte-identical to 0.29. Only campaign orchestration/UI plus the new balance module change production behavior. The older full weapon matrices and 128-map generation sweep were not rerun; see [0.29 validation](VALIDATION-v0.29.md). The compatibility inventory/economy suites still use their original rule versions, while new rules are exercised by the month/progression/native suites.

## Release checks

Archive CRC, clean extraction, complete resource import, normal generated startup and the retained combat smoke check pass. The archive excludes Godot caches, generated import metadata, player autosaves and temporary tooling. The documented earned end-state JSON is an explicit replay artifact, not a user's save. This is a source project without standalone platform exports.
