# Validation — layered armour prototype 0.11

Tested with official Godot 4.4.1 on Linux x86-64. Native tests use a 1440×900 window, OpenGL compatibility, Mesa software rendering and isolated save directories. This validates the source project, not standalone exports or final human balance.

## Final suites

| Suite | Checks | Failures | Scope |
| --- | ---: | ---: | --- |
| `tests/run.gd` | 1,160 | 0 | Core tactics; 200 baseline-army battles |
| `tests/fields.gd` | 486 | 0 | 160 baseline-army battles across fields/objectives |
| `tests/world.gd` | 953 | 0 | Regional accounting, patrols, contracts and older-save migration |
| `tests/company.gd` | 1,167 | 0 | 30 generated-company month attempts; 67 actual battles |
| `tests/progression.gd` | 80 | 0 | XP, perks, scars, recruitment, old memorials and replay protection |
| `tests/formations.gd` | 564 | 0 | Orders, group movement, exact costs, migration; 120 baseline-army battles |
| `tests/relationships.gd` | 123 | 0 | Social accounting and compatibility; 80 paired ridge battles (40 frozen v0.7) |
| `tests/playability.gd` | 42 | 0 | Exact forecasts, real feedback and one generated-company escort battle |
| `tests/people.gd` | 10,203 | 0 | 250 generated populations / 9,000 people; identity, costs, growth, gear, persistence and migration |
| `tests/armor.gd` | 2,454 | 0 | 50 populations, all 35 components, ownership, previews, shop, damage, repair, corruption and 3 battle runs (one current, one paired current/old) |
| `tests/armor_ui.gd` | 77 | 0 | Generated company: real preview/fit/purchase/compatibility/storage/exchange input; 1 battle; persistent damage and paid repair |
| `tests/people_ui.gd` | 50 | 0 | Generated people: seed entry, profiles, earned growth, recruitment, reload and ending; 2 battles |
| `tests/ui_flow.gd` | 48 | 0 | Older-save compatibility: full month, equipment, supplies and world consequences; 2 battles |
| `tests/playability_ui.gd` | 37 | 0 | Older-save compatibility: guide, forecast, combat feedback and reload; 1 battle |
| **Total** | **17,444** | **0** | **631 model battle runs and 6 native battles** |

Model runs comprise **590 current-rule battles, 40 frozen v0.7 battles and one frozen v0.10 battle**. The latter and its migrated current-rule counterpart are a paired continuation. Casualty/XP fixtures, failed diagnostic attempts and the release smoke battle are excluded. Repeated accounting and round-trip assertions contribute to check totals; these are not all distinct gameplay scenarios.

Only the four native suites listed above were rerun for this release. The other native journeys and earlier balance reviews remain historical evidence in `VALIDATION-v0.10.md` and the older reports, not additional v0.11 test counts.

## Assemblies and component identity

Every body kit has six component slots and every helmet five. Fifty generated companies exercise varied compatible outfits, unique ownership and saved identity. The broader people suite checks 250 initial companies and 9,000 generated people. All 35 components are individually previewed, committed and saved, comparing appearance definitions and protection/load totals with the preview. The exhaustive component test explicitly supplies catalogue inventory; it does not pretend the entire catalogue was earned in play.

A piece belongs to at most one assembly, and a worn kit belongs to one soldier. Stored kit children do not also appear as loose stock. Fitting, removing, storing, re-equipping and exchanging preserve item IDs and condition. The tests reject shared children, nested kits, wrong slots, missing parts, nonzero container durability, invalid candidate gear and forged purchases. Removing a component from an already empty equipment slot does not create a new kit.

Helmet compatibility is enforced on both additions and removals. A visor prevents replacing its required bascinet or removing that shell; removing the visor first permits the change. Failed operations leave the complete snapshot unchanged.

## Preview and costs

Browsing consumes no money, RNG or campaign state. The editor uses the same component totals and personal fatigue rules as deployment. Tests compare actual deployment armour, padding, helmet and load against the committed preview, and check attack/guard, movement and recovery differences at the live cost functions.

Town purchases use the displayed reputation-adjusted price, create one loose physical item and deplete a stable town/week/definition stock ID. Repeated or unaffordable purchases are refused without mutation. Depletion survives saving; a new week exposes a new stable stock ID. Purchasing and fitting are separate user confirmations. The generated native journey buys brigandine for actual crowns before equipping and transferring it.

## Combat damage and repair

One model fight with added plate and reinforcement checks every observed protective loss against the outside-in component order. Settlement preserves each surviving physical item's condition. Active battle JSON reload keeps the exact inventory references and RNG. Forged component conditions, weights, definitions, missing parts and mismatched total load are rejected without replacing the running campaign.

Declared casualty fixtures verify that victory retains a fallen soldier's assembled equipment in stores, while defeat removes the kit and its children. These fixtures are not counted as actual battle wins. Repairs charge the aggregate missing condition once, refuse insufficient tools and restore each worn part to its catalogue maximum.

The native armour journey uses real mouse input to compare and fit shoulder guards, fit a bascinet and visor, inspect a blocked incompatible shell, remove the visor, buy and fit brigandine, store and re-equip a whole body kit, and exchange it with another mercenary. F5/F9 preserves the result. The modified company then fights the ford through normal legal combat, records individual damage, travels to town and repairs a survivor using actual tools. Screenshots are captured from this running game.

![Exact protection and fatigue comparison](armor-body-preview.png)

![Whole kit transfer and recipient costs](armor-transfer.png)

## Generation, campaign and compatibility

Generated people retain their displayed equipment and personal traits when hired. The native generated-person journey uses the real seed controls, profiles, promotion choices, hiring and saves. Combat outcomes use the new armour and fatigue costs. The generated native journey wins the first ford battle with five survivors, develops Dora using earned XP, hires a replacement, and completes two battles before disbanding on day 24 after three unpaid days. These outcomes are from the v0.11 run, not reused historical results.

Thirty model month attempts complete 67 actual battles and produce **19 successful months, four contract shortfalls, six unpaid disbands and one total company loss**. This is one automated policy with generated equipment, not a human win-rate estimate. Layer availability, armour pricing, fatigue thresholds and enemy equipment still need human playtesting.

Migration covers campaign schemas 2–9, including active battles and aftermaths. Old armour pieces become assembly children without changing IDs, condition or owners; old parts retain zero added load. A genuine guarded v0.10 battle and its migrated counterpart continue under the same AI commands and finish with identical RNG, command history, HP, protection, fatigue, morale, positions and kills. Settlement pays the same amount. Old people, relationships, wounds and service records remain intact. Newly acquired pieces use normal load.

The native compatibility month starts from an explicit frozen v0.9 save, then uses the current game's ordinary inputs and combat. It is separate from generated-company testing. Missing optional guide metadata still defaults to hidden hints, and the guide test explicitly enables it before checking persistence.

## Known scope

There are 35 components and original vector drawings, not final character art. Enemies still use baseline armour pools rather than fully lootable assemblies. Contract salvage can award components. Damage pools retain the existing penetration and padding rules; material-specific resistances and directional coverage are not implemented. Armour load does not add a separate maximum stamina stat.

The existing sword, spear, axe, bow and shield remain. The proposed wider weapon catalogue, carried-item slots and ammunition system are not part of this armour milestone. Boots, gloves, separate leg slots and rings remain deferred.

## Release verification

The release script imports the source, checks archive CRC, extracts into a clean directory, imports that copy and runs its smoke battle. The packaged project includes source, data, fonts, documentation and tests; generated Godot caches and personal saves are excluded. Native screenshots are visually reviewed. The software-display VSync warning is benign; script errors and failed checks are not accepted.
