# Battle Brothers 2 — company progression 0.30

A Godot source prototype of a thirty-day mercenary campaign: three random founders, layered armour, physical weapons/ammunition, personal stats/talents/perks, individual initiative and a generated overworld.

**Start a new company to use 0.30 balance.** Existing saves keep their original prices, enemy rules, people, geography and progress. No silent rebalance of a campaign already underway.

## Play

1. Extract the archive. Import `project.godot` in **Godot 4.4.1**, the tested version, then run with the editor's F5. This archive contains source, not a standalone executable.
2. Choose **New company** and enter a seed, or press **R** to roll one. Three founders start with modest gear, 300 crowns, 24 food, 20 tools, 6 medicine and 60 ammunition. You can recruit up to six living companions.
3. Start with the Crossing Outlaws contract. Consider a fourth companion and keep a supply/wage reserve. Contract boards and visible enemies show troop type and count. Veteran deserters are a deliberate risk.
4. Click ground to travel; select discovered sites and **Set course**. Unknown land, roads and sites stay hidden. **Space** pauses/resumes the map; **1/2/3** choose travel speed. Arrival, sightings and contact pause automatically.
5. After a fight, recover, train, equip loot and check the next job. Armour/shields repair over time using tools; food permits natural HP recovery; medicine treats temporary injuries. Town temples speed injury treatment. **Guarded-road deliveries** provide lower-paying work while recovering during travel. Security can change before arrival.
6. **Company & Equipment** provides layered armour, weapon comparisons, training, carried gear, trading and service histories. Armour comparisons show current/max protection and changes in fully repaired capacity. Town services require physical presence.
7. In battle, the gold portrait acts. **Space** waits; **F** ends that fighter's activation. **I**, Inspect companion, or double-clicking an ally opens a paused read-only inspection. **4** opens formations, **5** explains hit odds, **6** opens weapons and carried equipment.
8. Normal equipment swaps cost **4 AP, no fatigue**. Quick Hands grants the first eligible free swap each round; shields still cost AP. Bags and Belts grants two extra carried slots and removes carried load except two-handed weapons.
9. In game, **F5/F9** saves/loads people, gear, battles, markets, routes, partial recovery, discovery and progression rules. At the end of day thirty, survive debt-free and fulfil four contracts or remove all raider bands.

## What changed

- **Smaller scouts and graded garrisons.** Thugs lead into outlaws, mixed raider bands and veteran deserters. Enemy composition follows site, band strength and encounter type; it never scales to your party's level or equipment. Scouts are separate from camp garrisons.
- **Equipment prices have room to progress.** Short mail starts at 160 crowns, riveted mail 260, heavy mail 520; local conditions and reputation modify quotes. Purchase screens and resale/replacement values use the same rules. The existing catalogue covered the needed steps, so no filler equipment was added.
- **Guarded-road escort jobs.** Existing waiting caravans can hire you even after their road has been cleared or protected by patrols. They pay less than dangerous escort work, require physical delivery, and can become dangerous if security changes. No duplicated cargo or repeat payout.
- **Higher rewards for tougher camp contracts.** Woodland clear jobs add 50 base crowns; deserter clear jobs add 110. First-camp pay is unchanged.
- **Rebuilding guidance.** Company plan identifies available guarded work or the next loading day, subject to food supply. Ended-company equipment and cosmetic items have clearer labels.

[Progression rules and prices](CAMPAIGN-0.30.md) · [validation and limits](VALIDATION.md).

## What the month trials establish

Sixteen legal automated campaigns across eight map/company seeds reached the successful month ending: **124 contracts, 102 battles, 19 deaths and 19 replacement hires**. Both a four-person policy and one expanding toward six remained viable. The smaller companies generally bought mail earlier; expanding companies spent more on recruitment and finished with less body protection per fighter.

These policies use guarded delivery work, train, equip loot, preserve cash and avoid under-equipped veteran assaults. They know destination coordinates. Results demonstrate viable routes through the month; they are not a human difficulty study, an exhaustive strategy comparison, or proof that every seed/build is balanced. The eight baseline runs with the prior campaign rules all wiped out; encounter, price and work-availability changes were tested together, not isolated experiments.

![The quoted first-mail purchase](month-mail-price.png)

## Retained systems

Bodies have six armour layers and helmets five parts. Combat reports total armour and HP damage; individual components retain condition for equipment and recovery. Weapons keep their authored reach, damage, armour effectiveness, penetration and action costs. Enemy loot comes from killed opponents' actual remaining equipment; routed enemies retain theirs.

The eight trainable attributes are Health, Stamina, Resolve, Initiative, Melee skill, Ranged skill, Melee defence and Ranged defence. Three talent-star levels affect saved growth rolls. There are 69 authored perks and ten weapon groups; backgrounds influence tree probabilities without excluding builds. New people retain varied identities, stats, talents and perk combinations.

Company ammunition refills physical packs outside battle: one supply unit per arrow/bolt, three per throwing weapon. Shortages allow partial whole-round refills. Supplies can be purchased and looted. Bolas remain damaging bundles without entanglement.

Each generated region has three towns, three camps and three discoveries. Rumours mark approximate search areas; watchtowers reveal ground; caches award finite supplies. Cleared camps have a four-calendar-day quiet period before a funded surviving band can reoccupy them. Complete clearance prevents outside respawns. Wagons and patrols travel on schedules; their economy settles daily. Independent caravan interception remains future work.

The combat, armour, weapon, people, perk, recovery, map-generation, world and navigation modules and data catalogues are unchanged from 0.29. Battle Brothers-inspired stats do not imply identical overall game balance.

## Saves and scope

New native companies use campaign schema **25**, progression version **1**. Older campaigns remain on their original schema/rules, including 0.29's generated schema 24 and classic schema 23. Stored maps are never rerolled. The save filename remains `user://ashen-company-save.json`. Battle schema 20 and existing inventory/perk schemas are unchanged.

The game remains a thirty-day prototype. Larger regions, additional tactical maps, a deeper injury catalogue, arbitrary town counts and post-level-11 progression are outside this release. Tactical combat and veteran-camp difficulty still need human playtesting.

Historical references: [0.29 validation](VALIDATION-v0.29.md), [0.28 opening rules](OPENING-0.28.md), [combat baseline](COMBAT-BASELINE-0.16.md), [ammunition](AMMUNITION-0.27.md).
