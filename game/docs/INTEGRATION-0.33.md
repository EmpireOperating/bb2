# Integrated campaign 0.33

The main 0.32 formation/reserve build is the baseline. Farm Supply and Physical Patrols were applied incrementally from their respective bases. The recovered Dungeons reference supplies Named Equipment and Dungeons, adapted to the current roster and campaign rules. No older preview replaces the main project.

## Conflicts resolved

- Preserved twenty living mercenaries, twelve field positions, reserves, modest three-founder starts, progression, combat, ammunition and recovery.
- Separated save wrappers from reused preview version numbers. Current campaign wrappers: named 29 (`campaign_rules`), dungeon 30 (`dungeon_base_version`), farm/patrol 31 (`world_base_version`). The underlying roster schema remains 27. New expanded named/crypt battles use 23; ordinary expanded battles retain 21. Old named 26/27, dungeon 28 and farm/patrol 26/27 are recognized by their explicit capability fields.
- Replaced six-slot assumptions in dungeon population, settlement and validation with the tactical roster's player/enemy slot counts. Undead cannot overwrite companion slots. Reserves remain off-field.
- Farm and guard clocks run during dungeon actions. Their contact ordering matches ordinary background travel. A company underground cannot protect a nearby farm through its overworld marker.
- Farm geometry ignores later-added dungeon markers when reconstructing a save. New dungeon placement keeps distance from the farm.
- Kept old band rules loadable; removed a duplicate validation that rejected version-one preview bands.
- Arranged six overworld report/rumour buttons without overlap. Preserved terrain-specific movement refusal messages and blocked empty formations from entering/scouting dungeons.

## Source integrity

The Named Equipment and Dungeons Library archives end before their ZIP central directories. Complete entries were recovered from local headers and checked against CRC and declared lengths. All recovered dungeon source/data files also matched the included SHA-256 manifest. Missing tail content was test/fixture/report/patch material, not runtime source. Historical fixtures were retained from main 0.32; new integration tests cover the recovered runtime. No incomplete compressed entry was used.

## Compatibility and verification

See `validation-0.33.json` and its passing logs for the exact release test runs. Model coverage includes composed saves, twelve-person crypt deployment with eight reserves, named items, farms, physical patrols, recovery, ammunition, ranged attacks, initiative and original campaign continuations. Actual original 0.32 camp, active battle and aftermath fixtures were exported from the untouched 0.32 baseline and replayed on this build. Original farm/patrol preview saves also migrate and round-trip.

Native UI coverage includes a two-floor dungeon expedition with four actual victories, retreat/re-entry with enemy wear, named chest, and F5/F9; patrol reports/recovery/intervention; and twenty-person formation/reserve editing, twelve-person combat, inspection and saves. The dungeon expedition explicitly provisions ordinary gear, supplies and level-four progression. Patrol intervention positions the company next to a real ongoing patrol fight; casualties and tactical outcomes are not injected. Roster stress tests fund hiring and position encounters against a still-living band.

Farm model/edge/journey scenarios use original six-founder preview start fixtures to retain their historical balance assumptions. Combined three-founder behavior is exercised separately by the native campaign and integration tests. These are functional checks, not a final difficulty certification for early campaigns or twelve-person endgame companies.

## Gameplay scope

New games enable all four additions. Existing saves preserve their capabilities and rules; start a new company for the entire integrated world. An existing company can learn burial rumours between encounters to adopt dungeons. Named items are nonmagical crafted equipment. Dungeons persist across visits and consume time/supplies; undead do not flee. There are no spells, resurrection or stat potions. Farm/patrol simulation covers the first farming town; other councils retain their abstract systems. Physical guards withdraw when the company takes over rather than joining tactical battles.
