# Validation — weapons prototype 0.12

Tested with Godot 4.4.1 on Linux x86-64. Native tests use a 1440×900 window, OpenGL compatibility, Mesa software rendering and isolated save directories. This validates the source project; standalone Windows/macOS exports and final human balance remain untested.

## Final suites

| Suite | Checks | Failures | Scope |
| --- | ---: | ---: | --- |
| `tests/run.gd` | 1,160 | 0 | Core tactics; 200 baseline-army battles |
| `tests/fields.gd` | 486 | 0 | 160 baseline-army battles across fields/objectives |
| `tests/world.gd` | 953 | 0 | Regional accounting, patrols, contracts and older-save migration |
| `tests/company.gd` | 1,134 | 0 | 30 generated-company month attempts; 62 actual battles with new equipment |
| `tests/progression.gd` | 80 | 0 | XP, perks, scars, recruitment, old memorials and replay protection |
| `tests/formations.gd` | 564 | 0 | Orders, group movement, exact costs, migration; 120 baseline-army battles |
| `tests/relationships.gd` | 123 | 0 | Social accounting and compatibility; 80 paired ridge battles (40 frozen v0.7) |
| `tests/playability.gd` | 42 | 0 | Exact forecasts, real feedback and one generated-company escort battle |
| `tests/people.gd` | 10,206 | 0 | 250 generated populations / 9,000 people; identity, costs, growth, advertised gear and persistence |
| `tests/armor.gd` | 2,469 | 0 | 50 populations, all 35 components, ownership, previews, shop, damage, repair, corruption; one current fight and a paired historical continuation |
| `tests/weapons.gd` | 809 | 0 | All nine action families, reactions, switching, ammo, reloads, shields, loot, corrupt saves; 21 current fights including checkpoint replay and a paired historical continuation |
| `tests/weapons_ui.gd` | 38 | 0 | 1 real battle; native shop, equip, carried switch, riposte, crossbow shot/reload, spent ammo refill and actual recovered gear |
| `tests/weapons_compat_ui.gd` | 126 | 0 | 2 real battles; exact historical continuation, native purchase, new-rule deployment and saved settlement |
| `tests/people_ui.gd` | 51 | 0 | Generated people: typed seed, profiles, earned development, full month and reload; 2 real battles |
| `tests/armor_ui.gd` | 77 | 0 | Native preview, fit, purchase, compatibility, storage/exchange, damage and paid repair; 1 real battle |
| **Total** | **18,318** | **0** | **649 model battle runs and 6 native battles** |

The model total comprises **85 battles using the new weapon rules**, **522 baseline/historical weapon-rule battles in the current engine**, and **42 frozen-engine battles** (40 v0.7, one v0.10, one v0.11). The baseline suites deliberately retain their original armies and weapon rules so tactical and migration regressions remain comparable. They are not evidence for new-weapon balance. The six native battles comprise five new-rule fights and one historical continuation.

Declared duel/casualty fixtures, diagnostic attempts and the clean-release smoke battle are excluded from battle counts. Repeated accounting and round-trip assertions contribute to check totals; these are not all distinct scenarios. Only the four native suites listed here were rerun for v0.12. Earlier reports and other screenshots remain historical evidence, not additional current test counts.

## Distinct actions and physical equipment

Focused fixtures exercise every weapon family: paid riposte with a two-reaction cap, spear entry reactions, shield splitting and loss of linked support, mace current/next-turn AP loss, paired hammer damage tradeoffs, dagger preservation of all armour pools, polearm drag/minimum range, aimed bow shots and crossbow shooting/reloading. Invalid actions leave state and RNG unchanged. Costs include the same personal and armour modifiers shown in the UI.

Switching tests preserve the actual previous weapon and crossbow loaded state. Two-handed switches require space to stow an offhand shield; full carried slots cause atomic refusal. Restoring rejects shared physical IDs within or across units, invalid ammunition quantities, forged loaded flags, inconsistent derived weapons and impossible stances. Shield wear, spent ammunition, switched slots and reload state survive active saves and settlement.

Town weapon purchases charge the exact quote once and put a physical item in stores. Fitting is separate. Ammo refills charge only missing rounds and refuse full packs without mutation. Shield repair uses the same aggregate tool calculation as worn armour; ammo is excluded from tool repair.

## Actual fights, loot and checkpoint replay

The first-contract sample uses 20 different generated company seeds: **17 victories, three defeats, 44 recovered items/assemblies and eight encountered weapon families**. Every family is covered separately by action fixtures. All fights use normal commands, costs and deterministic combat rolls; no wins or resources are injected. A saved/unsaved pair adds one repeated current fight to the model count.

Each victory checks recovered counts against killed enemies' actual equipment. Surviving routed enemies provide no loot. Every recovered armour child retains its definition and final condition; every surviving mercenary retains their actual ammunition, shield wear and switched loadout. Repeated settlement cannot award again. One complete uninterrupted fight and its JSON checkpoint continuation finish with identical campaign snapshots, including loot order and new item IDs. Recovery now walks canonical equipment slots rather than JSON dictionary insertion order.

The native weapons journey uses real mouse input to inspect without committing, fit both carried slots, buy a mace at its quoted price, equip a crossbow/bolts, activate riposte, switch weapons, move to a legal firing position, shoot and reload. It saves/loads during the battle, wins through ordinary legal combat, opens actual enemy loot, returns to town and equips a recovered weapon. The shooter falls in that fight; the journey then equips and refills her genuinely spent, salvaged bolt case on a survivor. It neither grants ammunition nor manufactures a casualty fixture.

![Weapon inspection before equipping](weapons-armory.png)

![Native crossbow action and target equipment](weapons-crossbow-shot.png)

![Equipment recovered at actual final condition](weapons-loot.png)

## Companion and armour regressions

The people suite checks 250 generated populations and 9,000 distinct-within-campaign people, including new advertised weapon, carried and ammo loadouts. Existing identities and development remain stable. Armour tests retain all 35 components, physical ownership, compatibility, exact previews, kit transfers, corruption checks and per-component damage/repair. The native armour journey buys and transfers real gear, fights, then repairs a surviving outfit with actual tools.

The generated native month now uses **seed 1** for earned-growth coverage: the first victory leaves all six founders alive, Caspar spends actual earned XP, and the company reaches day 31 successfully after two battles. No promotion is granted artificially. The previous seed-7392 unmodified company lost its first fight under the automated policy (two deaths) and disbanded on day 21 after three battles. That diagnostic exposed an obsolete test assumption that the old seed must win immediately; it is documented rather than counted as a passing growth test. Seed 7392 remains in the separate modified weapon/armour journeys.

Thirty model month attempts complete **62 battles** and produce **25 successful months, two contract shortfalls, two unpaid disbands and one total company loss**. This is one automated policy, not a human win-rate estimate. New weapons, enemy outfits, ammo prices, reactions and the deterministic recovery rate still need human playtesting.

## Existing saves

Campaign schemas 2–10 pass through frozen v0.11 validation before upgrading to schema 11; battle schema is now 8. Existing armour parts, personalities, progression, relationships and world state are preserved. Previously indestructible shields gain full condition; old ranged soldiers gain matching ammunition; carried slots start empty.

An ongoing old fight retains its historical weapon rules through settlement. The genuine guarded v0.11 fixture and migrated version finish with identical commands, RNG and outcome; the native compatibility journey also compares HP, armour, padding, helmet, fatigue, morale, positions and kills for every unit. Its next deployment enables new weapon rules and physical enemy equipment. The native journey buys a hammer with actual crowns before that next fight and verifies saving after it. Old ongoing enemies do not retroactively gain lootable assemblies. A separate v0.10 armour continuation remains paired against its frozen engine.

## Known scope

Nine authored weapon families and 35 armour components use original vector placeholder art. Weapon quality tiers, weapon crafting, material-specific armour resistances, directional coverage, general weapon durability and rare affixes are not implemented. Shields and armour have condition; ammunition has a remaining-round count. Carried equipment adds no separate weight. Ammunition packs are fixed during battle. All killed enemies' equipment is recovered on victory; there is no drop-chance model or equipment selling yet. Boots, gloves, separate leg slots and rings remain deferred.

## Release verification

The release script imports the source, checks ZIP CRC, extracts into a new directory, imports that clean copy and runs its smoke battle. The package contains source, data, fonts, documentation and tests; generated Godot caches and personal saves are excluded. Native screenshots are visually reviewed. The software-display VSync warning is benign; script errors and failed checks are not accepted.
