# Validation — equipment progression prototype 0.13

Tested with Godot 4.4.1 on Linux x86-64. Native journeys use a 1440×900 window, OpenGL compatibility, Mesa software rendering and isolated save directories. This validates the source project, not standalone Windows/macOS exports or final human balance.

## Final checks

| Suite | Checks | Failures | Scope |
| --- | ---: | ---: | --- |
| `tests/run.gd` | 1,160 | 0 | 200 baseline-army tactical battles |
| `tests/fields.gd` | 486 | 0 | 160 baseline-army battles across fields/objectives |
| `tests/world.gd` | 953 | 0 | Regional economy, six world months, interventions, contracts and old-save migration |
| `tests/company.gd` | 1,181 | 0 | 30 generated-company month attempts; 63 actual battles |
| `tests/progression.gd` | 80 | 0 | Earned XP, perks, wounds, scars, recruitment and replay protection |
| `tests/formations.gd` | 564 | 0 | Orders, movement, support, migration; 120 baseline-army battles |
| `tests/relationships.gd` | 123 | 0 | Social accounting and 80 paired ridge battles, including 40 frozen v0.7 |
| `tests/playability.gd` | 42 | 0 | Forecasts, feedback, guide and one complete escort battle |
| `tests/people.gd` | 10,206 | 0 | 250 generated populations / 9,000 people; identity, advertised variants, gear and persistence |
| `tests/armor.gd` | 2,462 | 0 | 50 populations, all 35 components, preview/ownership/shop/damage/repair; one current and two paired historical battle runs |
| `tests/weapons.gd` | 854 | 0 | Nine family mechanics, reaction/cost/ammo/switching checks; 21 current battles and two historical continuation runs |
| `tests/equipment_economy.gd` | 214 | 0 | All 23 primary/special actions, markets, buying/selling/repair, corruption; 16 new fights and two v0.12 continuation runs |
| `tests/equipment_economy_ui.gd` | 33 | 0 | One real battle; native variant purchase, sale review, switch, actual recovered kit repair and sale |
| `tests/equipment_compat_ui.gd` | 126 | 0 | Two real battles; exact old continuation, paid new variant and new enemy deployment |
| `tests/people_ui.gd` | 51 | 0 | Two real battles; generated profiles, earned growth, hiring, full month and reload |
| `tests/armor_ui.gd` | 77 | 0 | One real battle; native fitting, purchase, compatibility, storage/exchange, damage and repair |
| **Total** | **18,612** | **0** | **668 model battle runs and six native battles** |

Model counts comprise **102 battles with new v0.13 equipment generation**, **523 baseline or historical-equipment continuations in the current engine**, and **43 frozen-engine battles** (40 v0.7, one each v0.10/v0.11/v0.12). These categories are not all new-equipment balance evidence. Five native fights use current generation; one continues an old v0.12 battle with its existing gear.

Declared duel, condition, purse-exhaustion, casualty and economy fixtures, diagnostic attempts and the release smoke battle are excluded from battle totals. Repeated round trips/accounting assertions contribute to check counts; these are not all distinct gameplay situations. Only the four native suites listed above were rerun for this release. Older reports and other native test scripts remain historical evidence.

## Weapon variants

All 23 weapons perform both their primary and family action in explicit cost fixtures, including actual AP/fatigue payment, matching ammunition consumption and save/load. The short sword performs three attacks in nine AP; the greatsword can perform one and gives up the shield. Heavy crossbow shooting plus its six-AP reload consumes a complete turn. Family mechanics remain covered by the existing weapons suite: shield damage, riposte limits, spear reactions, stagger, armour destruction, puncture preservation, hook, aimed shot, loaded state and carried-slot constraints.

Founders and recruits receive attainable ordinary variants without fixed identities or premium weapon grants. The population suite retains 250 companies / 9,000 people, original shield/ranged viability constraints, advertised carried/ammo loadouts, growth and save validation. Armour continues to use all 35 components and the same physical condition/ownership rules.

## Market and transaction checks

Browsing stock, sale quotes and repairs is read-only and consumes no RNG. Fixed weekly stock survives daily world changes, purchases and reloading; a new week captures current conditions and renews stock IDs. Pure market fixtures isolate town specialties, food shortage, raid pressure, prosperity and premium rotation. Active town saves must contain their current market book.

Purchases debit company crowns and credit the merchant purse by the same quote. Selling credits company crowns and debits the purse by the same quote. Prices depend on condition, market tier and reputation. An immediate buy/resell loses money. The merchant refuses an unaffordable sale atomically. Equipped/carried items and children still inside a stored assembly cannot be sold separately. Whole-kit sales erase every child exactly once; repeated sales and stale price confirmations leave the state unchanged.

Stored repair charges the aggregate missing condition in tools and restores the sale value. Empty ammunition cannot be repaired or sold for invented money. Corruption tests reject inconsistent merchant cash, altered stock, duplicate sale entries and missing current books. Purchases, sales, purse balances and repaired conditions survive JSON round trips. One world test directly moved its fixture to another town; it now explicitly initializes that arrival's market, matching what normal travel already does.

Merchant purses are abstract private weekly budgets. Public treasury influences prosperity but is not debited to create those budgets. Food/cargo/council accounting remains conserved and is tested separately; equipment manufacturing is not simulated.

## Real fighting and salvage

The new economy sample plays 15 fresh companies: **14 victories, 32 actual recovered items/assemblies sold, and 15 weapon variants encountered**. A checkpoint replay adds one repeated current fight. Every sale occurs after ordinary battle settlement and travel; no resources or victories are injected. The uninterrupted and checkpoint versions finish with identical campaign state and loot IDs.

The existing weapon sample additionally plays 20 seeds plus one checkpoint replay: **19 victories and 56 recovered items/assemblies**. Its output's historical `families` label now counts 15 concrete weapon IDs, not 15 families; the game has nine families. These are automated policies, not human win-rate estimates.

Enemy generation uses site occupation, formation position, band threat, food reserves and captain status. New enemies carry the actual variants and layered outfits they use. Existing v0.12 enemies retain their existing equipment. A victory can provide no enemy loot when all enemies rout or the objective is captured without kills; the first native diagnostic did exactly that. The final sale journey uses seed 2 to exercise an actual kill-and-salvage path, rather than forcing a death or loot award.

## Native player journeys

The equipment journey uses real mouse/keyboard input to open Ashwick's market, inspect a short sword without mutation, buy at the shown quote, review and confirm sale of a spare axe, save/load, equip the purchased sword in a carried slot, deploy and switch to it for two AP/four fatigue. The action panel then shows the short sword's actual three-AP primary attack. The company wins through legal commands, recovers actual damaged enemy kits, travels to Stonecross, repairs a kit in stores and confirms its whole-kit sale. The final save retains the missing sold items, repair tool cost and both merchant accounts.

![Local variant purchase](equipment-market.png)

![Actual enemy occupation and variant combat](equipment-variant-battle.png)

![Damaged recovered kit before repair](equipment-repair-or-sell.png)

![Repaired kit and sale confirmation](equipment-kit-confirmation.png)

The compatibility journey loads a genuine guarded v0.12 active save. Its complete command sequence, RNG, outcome, HP, armour, padding, helmet, fatigue, morale, positions and kills match the frozen engine. It then buys a current club with actual money and fights a new woodland deployment with current occupational equipment. Both settlements reload successfully. The model suite also continues a genuine v0.12 fight, while existing older migration tests cover schemas back to v0.2.

The generated-person journey uses seed 1: its opening victory has two casualties, Caspar spends earned development, a recruit fills a vacancy, and the company reaches day 31 after two battles but falls short of the campaign objective. The native armour journey still completes fitting, quoted purchase, compatibility rejection, whole-kit transfer, actual battle damage and paid repairs. New trade/action panels were visually inspected; clicks outside the weapon modal no longer fall through to the battlefield.

Thirty full model month attempts complete **63 actual battles**, yielding **24 successful months, three objective shortfalls and three unpaid disbands**. This policy does not exploit the new selling service. Difficulty, salvage pricing, premium availability, heavy weapon reactions and recruitment prices need human playtesting.

## Save and scope

Company schema is 12 and battle schema 9. Old companies validate through frozen v0.12 code before the upgrade. Existing equipment, candidates, conditions, purchased-stock depletion, personalities, progression and world state remain intact. Historical transactions are not fabricated; new merchant books and sale history initialize as needed. New enemy equipment begins on the next deployment. Still older ongoing battles retain their historical weapon-rule behaviour.

This milestone adds 14 authored variants to the original nine, finite weekly inventories/purses, equipment selling and stored repair. It does not add random quality affixes, named/legendary gear, weapon crafting, general weapon durability, buyback, new equipment slots, final art or a full equipment production economy. Shields/armour keep condition; ammo keeps remaining rounds. Current vector art distinguishes families with limited variant silhouette changes.

## Release

The package is imported, CRC-checked, extracted to a fresh directory, reimported and smoke-tested. It contains source, data, bundled fonts, documentation and tests; generated Godot caches and player saves are excluded. The software-display VSync warning is benign. Script errors or failing assertions are not accepted.
