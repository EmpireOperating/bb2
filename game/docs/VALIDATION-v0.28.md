# Validation — humble beginnings 0.28

41,356 assertions, zero failures in final recorded runs across 20 suites. Counts include repeated assertions, not unique scenarios. Godot 4.4.1 on Linux.

Built on the complete delivered 0.27 source (Library revision 30). This adds opening gear/economy, timed recovery, inventory costs and Bags, battle inspection, and fog presentation while retaining the prior overworld and all ten weapon groups.

| Suite | Checks | Evidence |
|---|---:|---|
| `opening` | 148 | Six seeded three-founder starts, supplies and gear, thugs, actual fights, camp/battle/aftermath save roundtrips and timed recovery |
| `opening_balance` | 336 | 96 paid-command AI opening battles; 48 seeds with three founders and the same 48 with an affordable fourth recruit; return, provisions, recovery and first-week saves |
| `opening_compat` | 63 | Three captured delivered 0.27 companies: original camp/battle/aftermath fields, exact commands/RNG/casualties, settlement and camp adoption |
| `inventory` | 31 | Both controllers, four-AP swaps, Quick Hands, Wait, wooden shield defence, two-handed shield stowing, extra bag load/refill, quiver conservation and live swapped-bag saves |
| `recovery` | 21 | Paused/partial hours, reload continuation, travel/camp rates, tool-credit conservation, shortages, temple injury care, permanent scars, store queues and midnight |
| `background_generation` | 27,570 | 6,600 people over 200 seeds; original identity/stats/stars/growth retained, every group possible for every background, 32 earned-point careers and old saves |
| `perks` | 134 | Shared perk progression, purchases, costs, pools and saves |
| `ranged_perks` | 7,513 | Ranged arithmetic, careers, physical ammunition and older continuations |
| `hammer_dagger` | 94 | Both controllers/offhands, costs/damage, chain/debuff timing, AI, preview purity and older continuations |
| `axe_mace` | 73 | Perk arithmetic, stagger, AI, live saves and older settlement |
| `double_grip` | 448 | All 26 weapons and both controllers, damage channels/exceptions, shields, swaps and frozen 0.21 combat continuations with historical company gear |
| `ammunition` | 291 | Ammo conservation, paid attacks/reloads, whole-round partial refills, purchases, salvage, retreat, malformed saves, 12 real fights and older continuations |
| `ammunition_perk_compat` | 81 | Three delivered 0.26 careers with paid live hammer/dagger effects: preserved fields, exact combat/settlement and camp adoption |
| `equipment_economy` | 269 | 26 weapons, markets, purchases/sales, queued repairs, merchant accounts, 15 fresh fights and historical companies |
| `overworld` | 1,339 | Routes, terrain, crossings, physical services, pause/clock, pursuit/evasion, encounters, escorts, camps and corrupt saves |
| `overworld_perk_compat` | 33 | Three delivered 0.25 spatial saves: original position/clock/scouts, exact combat and settlement plus explicit migrations |
| `turns` | 2,822 | 24 campaign fights, 12 paired map/objective continuations and three old saves |
| `opening_ui` | 23 | Native three-person roster, opaque fog and hidden hitboxes, Bags, temple purchase, F5/F9 and paused read-only enemy-turn inspection |
| `opening_journey_ui` | 15 | Native hire, contract, unexplored movement, discovered-site selection, legal AI contract victory, return, earned mail purchase/fit and F5/F9 |
| `ammunition_ui` | 52 | Native purchase, partial refill, five paid ranged attacks, reload, aftermath and F5/F9 |

## Opening trial

| Party | Fights | Wins | Losses | Deaths | Entire party lost | Survivors |
|---|---:|---:|---:|---:|---:|---:|
| Three founders | 48 | 43 | 5 | 28 | 3 | 116 / 144 |
| Hire a fourth | 48 | 48 | 0 | 13 | 0 | 179 / 192 |

These are 48 deterministic seeds played both ways by the legal combat AI, not human playtests. No victory or damage result is forced. The model trial uses the retained day-based travel helper, then purchases food and rests through the first week when the company survives. The raw rows are in [opening-balance-0.28.json](opening-balance-0.28.json). This demonstrates an initial viable progression step, not final difficulty or a complete month-long economy balance.

The separate native opening journey uses real map movement/contact processing and production UI handlers: hire the fourth companion, accept the first contract, explore, select the discovered ford, arrive, fight, return to Ashwick, buy and fit short mail, and save/load. Its final run wins one contract battle, returns on day 3 with four survivors, and does not force victory or grant XP, gear or money. Initial travel targets the ford coordinates as a route fixture; the test is not a human navigation study.

Native opening inspection and inventory screenshots explicitly use an earned-point provider with declared test XP to exercise Bags and Belts; the recovery screen uses declared damage/injury fixtures. The ammunition UI suite also declares equipment fixtures. Enemy processing is verified stopped during inspection, and F/Space cannot act through the modal. Screenshots were inspected at 1440×900 under Mesa; the unsupported-VSync warning is nonfatal.

## Compatibility and limits

The 0.27 fixtures were captured by executing the originally delivered archive, not synthesizing a current save with an old version number. Its camp, mid-battle, final battle, settled aftermath and returned-camp records preserve every original field after migration. Older captured 0.23–0.26 campaigns are retained and exercised by the relevant suites. Historical market reconstruction excludes new opening-only catalogue entries so old ledgers remain valid.

Campaign schema is 23, battle 20, personal pool 6 and overworld 1. Old ongoing encounters keep their saved tactical costs and settlement; timed recovery starts at camp. The next deployment uses current swap costs. Old character trees and recruitment offers are not rerolled; a new company is required for the modest opening and new Bags option.

Obsolete test assumptions were replaced explicitly: historical fixtures use historical six-person companies; fresh population comparisons map the three founders and original 30 recruits by their preserved draw positions; repair checks wait for world time; shops do not assume a free starting armoury. Inventory saves cover both extra bags occupied, an actual paid swap and exact reload.

The previous 432-fight hammer/dagger matrix was not rerun; see [0.26 validation](VALIDATION-v0.26.md). [0.27 validation](VALIDATION-v0.27.md) remains historical. Only the suites in the table are claimed as new 0.28 runs; older UI/whole-campaign scripts may retain their original start/repair assumptions.

The injury model remains generic Deep wound plus permanent scars. Temple care speeds temporary injuries; it does not remove scars. The map remains one fixed region and the campaign still ends after 30 days. Bolas do not entangle. This is a Godot source project, with no native executable export.

Archive CRC, clean extraction/import and normal-start smoke checks pass. No Godot cache, player saves or temporary tooling is included.
