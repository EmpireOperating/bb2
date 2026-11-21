# Battle Brothers 2 — unified playtest 0.45

A Godot source prototype with randomized mercenaries, layered armour, individual initiative and a living, open-ended campaign.

## One combined build

This is the main prototype with the delivered world/raider and dungeon branches integrated. Extract this single archive; do not overlay earlier integration packs.

- Six towns, physical trade and material freight, farms, workshops, council-funded patrols and repairs.
- Resource-dependent raiders and camps, physical founding expeditions, recovery, personal danger memory, fading footprints and timed camp reconnaissance.
- Nine dungeon sites with themes, distinct enemies and tactics, persistent exploration, keys and locked treasuries, one-time stairwell supplies and an expedition journal.
- Existing layered armour, weapon actions, ammunition, perks, company development, contracts and trade.
- Landmark directions from the town where you actually ask, dated local reports and remembered leads.

[Integration, validation and playtest assessment](docs/UNIFIED-0.45.md) · [Previous README](docs/README-v0.44.md)

## Play and compatibility

Extract this archive, import `project.godot` in **Godot 4.4.1**, and run with F5. This is source, not a standalone executable.

**Start a new company to test the complete current feature set.** Seed 1 is the documented opening UI journey; any seed is selectable. Older companies still load with their saved maps, progress and generation rules. They do not silently gain the new raider rules or regenerated dungeons. The existing main save slot is retained.

Use **Local Rumours → Destinations → Read Directions**. **Bookmark Directions** keeps a short note on the map; **Lead Journal** reopens the full directions. North is up. Follow named bridges and waystones as ordinary exploration reveals them. Conditions can change before arrival.

Overworld: WASD/arrows or middle drag pan; mouse wheel or −/+ zoom; Home follows the company. Space pauses; 1/2/3 change speed. **In battle, Space waits / F ends activation.** F5 saves; F9 loads.

Use **Market · Cargo & Supplies → Trade Goods** to trade, **Town Work** for material needs and inbound cargo, and **Trade & Roads** for shipments. Towns buy, consume and ship real goods; raiders can capture them and camps can contain material loot.

For a first playtest: hire a fourth companion, buy provisions, take nearby work, fight, return and resupply. Then try camp observation and a dungeon expedition, including withdrawal and return. F5/F9 can be tested during travel, combat and exploration. Battles pause campaign time; travel, scouting and recovery consume time and supplies.

This remains a prototype. Map labels can crowd around clustered sites, and balance needs human feedback. Automated test results establish specific behavior, not human win rates or a finished difficulty curve.
