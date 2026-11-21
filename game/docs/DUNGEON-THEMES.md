# Persistent dungeon identities

Newly generated procedural dungeons use one coherent theme across their room graphs, tactical fields, undead formations, names and treasure weighting. These are mundane undead expeditions; no spells, resurrection, new factions or permanent-stat consumables are introduced.

| Theme | Exploration and fighting | Named treasure |
| --- | --- | --- |
| Burial mound | One floor, 4–6 compact rooms. Two or three defenders, at least two lightly equipped thralls. Tight battlefield with a central passage. | Existing 20% final-chest chance; sword, spear, mace, mail or nasal helmet. |
| Buried garrison | 2–4 floors, 8–12 rooms per floor. Central gallery, branching corridors and cross-doors. Shield guards screen spearmen; archers cover outer galleries. | Guaranteed final named item; weighted 80% weapons, 20% armour. |
| Royal crypt | 2–4 floors, 8–12 rooms per floor. Central approach and secluded tomb branches. Narrow tactical approach, armoured guards and fewer heavy sentinels. One fewer defender per encounter than the corresponding garrison roll, minimum three. | Guaranteed final named item; weighted 80% armour, 20% weapons. |

The first two procedural complexes guarantee one garrison and one royal crypt in each new world. The remote complex chooses between those two themes from its saved seed. The three small sites remain mounds. The original named landmarks retain their existing layouts, rosters, boss tactics and rewards.

Complex vaults retain a one-in-three chance of an additional named item. Vaults remain optional leaves off the entrance on each floor; their matching keys must come from the world. The ordinary route and final reward never require a vault key. Mechanical traps, supply caches, rubble shortcuts, scouting costs, wages, recovery costs and frozen battle time retain their existing rules. Treasure probabilities describe weighted rolls, not a guarantee that each garrison drops a weapon or each royal crypt drops armour.

## Persistence and discovery

Dungeon schema version 5 selects the new generator. It stores complete generated floors as before and validates immutable content against that version's deterministic algorithm. Original generation versions 1–4 remain readable without migration, renaming, relocation, rerolling loot or healing guards. An existing version-two company adopting the six extra sites receives new themed additions; its original three sites remain exact. Existing version-three or version-four worlds retain their existing six additions. To see themes in a world that already generated all nine sites, start a new company.

No party level, equipment, wall clock or combat RNG participates in generation. Site theme and threat do not change after retreat, training, loading or returning. New terrain uses distinct field IDs so existing tactical saves retain their old battlefields. New field IDs require the expanded roster and the dungeon elimination objective.

The entrance, underground map and known-site journal notes show the theme and broad preparation advice. A key for an unknown entrance exposes only the dungeon's name, including any thematic wording in that name. It supplies no separate theme metadata, directions, coordinates, floors, guards or room information. Maps still locate entrances; room notes still require observation.

## Implementation

- `src/dungeon_themes.gd`: frozen version-five generator, terrain and rank placement.
- `src/dungeon_variety.gd`: new-site selection and versioned names/descriptions/floors; legacy generator retained.
- `src/dungeons.gd`: version-five dispatch, canonical validation and deployment.
- `src/battle.gd`: themed field construction and save validation; existing maps remain unchanged.
- Dungeon view, expedition projection and journal view: discoverable theme presentation.

Royal encounter composition was reduced after a full-route prepared-party trial exposed excessive attrition. This does not change the individual undead stat tables or the general economy. Final verification results, preparation assumptions and observed casualties are recorded in the integration pack README and logs. Automated trials are not human playtests or estimates of fresh-company survival rates.

## Reproduce

Use Godot 4.4.1. Import once, then run from the game root:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/dungeon_themes.gd
godot --headless --path . --script tests/dungeon_variety.gd
godot --headless --path . --script tests/vault_keys.gd
godot --headless --path . --script tests/expedition_journal.gd
godot --headless --path . --script tests/dungeon_placement.gd
godot --headless --path . --script tests/dungeon_tactics.gd
godot --headless --path . --script tests/regional_news.gd
godot --path . --audio-driver Dummy --script tests/dungeon_themes_ui.gd
```

The native test uses an isolated save directory when run in validation. It creates declared level-four/six prepared companies with ordinary equipment and supplies, travels through production rules, then drives real entrance, room, key, combat, chest, retreat-to-entrance and F5/F9 controls. AI drives both sides of the three actual battles. It does not claim an earned campaign opening. The domain full-route tests separately use twelve level-eight veterans and paid recovery between fights to exercise entire garrison/royal routes and exact named reward claims without keys.
