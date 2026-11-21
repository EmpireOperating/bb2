# Procedural burial sites and discovery

Adds six persistent undead sites alongside Blackbarrow, The Fallen Watch and King's Sepulchre. The three landmarks retain their original rooms, enemies, rewards and progress. No party scaling, spells, resurrection, permanent-stat potions or new factions.

| Family | Number | Floors | Rooms per floor | Rewards |
| --- | ---: | ---: | ---: | --- |
| Small barrows | 3 | 1 | 4–6 | Modest caches; 20% named-item chance in the final chest |
| Burial complexes | 3 | 2–4 | 8–12 | Guaranteed named final item; optional guarded treasury on each floor, with a one-in-three named-item chance |

Two complexes have threat 2; the third has threat 3. Barrows have threat 1 and two or three undead in the final room. Complex guards vary with seed, threat and depth, up to twelve enemies. Their wardens use the existing undead rules, not copies of the three landmark bosses. Existing boss-tactics behavior remains available at the landmark finales.

The entrance positions, names, floor counts, connected graphs, ordinary loot, traps, rosters and named rolls are seeded once and saved. The upper-left side room is always an optional leaf, ensuring its guards cannot block the required route. Other doors form different branches and occasional loops. Existing rubble shortcuts and hidden caches can appear. The three existing crypt battlefields are reused; this patch does not add tactical terrain art.

## Discovery and expedition rules

- Burial rumours at towns mark the nearest unknown entrance. Already visited, naturally visible or completed sites are skipped.
- Victorious non-dungeon battles whose fixed seed is divisible by four can reveal one unknown procedural site. Eligible opened chests have a fixed half-chance; guarded treasuries always try to reveal a site.
- Recovered maps are automatically read. The entrance and journal are updated; the surrounding terrain stays hidden. Maps are not inventory objects or trade goods. No map is awarded when all six procedural entrances are known.
- Loot and settlement guards prevent repeated claims. Reloading the same pre-fight save and replaying the same battle gives the same discovery and rewards.
- Cleared rooms, opened chests, traps, shortcuts, casualties and enemy wear persist through retreat, return visits and Save/Load. Opened final chests mark sites completed, while unsearched side rooms remain available.
- Battles remain frozen in campaign time. Exploration and ordinary four-hour rests retain the 0.36 supply/calendar rules. No added whole-day food charge.
- These are nine finite sites per region, not endlessly respawning dungeons. Nothing restocks or resets when the company leaves.

## Save compatibility

New supported companies generate dungeon rules version 3 with all nine sites. Version 1 and 2 saves still load without alteration. A version 2 company adopts the six additions by asking for a burial rumour while safely in town; existing named reward identities and site progress remain unchanged. Expansion refuses pending encounters, active dungeons and unsupported older rosters. Version 1 dungeon companies keep their original behavior.

Version 3 saves require this code or a subsequent compatible release. Older builds cannot understand the new schema. The new rules still use the campaign's existing save container. The original three sites are validated against their frozen version 2 generator; the new sites are checked against the procedural generator and reject altered immutable geometry, roster, rewards or discovery state.

## Implementation boundaries

Production changes are limited to `src/dungeon_variety.gd`, `src/dungeons.gd`, `src/campaign.gd` and `src/dungeon_view.gd`, plus the new script UID. Extra enemy deployment columns prevent collisions when a generated twelve-unit roster contains more than nine melee fighters or archers.

No main release was published or merged. The integration pack is based on the latest main retrieved for this work: `Battle-Brothers-2-Prototype-0.36.zip`, Library version 41, SHA-256 `9da5ebe8062aa224b4a16f11b17881e700ff88adaa0098bf9cf701132e9d505a`. Its local baseline commit is `91ce308b495646fa9178b3b3131c2dce6fba95a4`.

The previously delivered Dungeon Boss Tactics patch was applied first, producing local prerequisite commit `93ea7ea6477bcb426247a7b23064f50a8c87e4e2`. This pack includes that exact prerequisite patch for an integrator who has not applied it yet. Do not apply it twice. No additional battle-clock patch is needed on 0.36.

The separate Expanded Region and later recovery/economy work were not incorporated. Placement uses the loaded region's town list and overworld dimensions, but this pack's validation used the main 0.36 region. Retest placement, discovery and shared campaign settlement code when combining other patches.

## Validation

See `DUNGEON-VARIETY-VALIDATION.md` and the pack's evidence folder for actual checks, prepared native expeditions, earned careers and screenshots. Prepared test fixtures declare their supplies, gear and XP; they are not economic balance evidence. Earned careers begin with ordinary founders and obtain recruits, equipment and levels through normal rules. Automated careers know routes and use production combat AI, so successful runs do not establish human difficulty or a universal win rate.
