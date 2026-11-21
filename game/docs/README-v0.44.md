# Battle Brothers 2 — first-month audit 0.44

A Godot source prototype with randomized mercenaries, layered armour, individual initiative and a living, open-ended campaign.

## New in 0.44

Asking **Local Rumours / Ask Locals** now supplies directions from the town where you are asking. Previously the journal permanently retained the first origin, so later inquiries could send you back across the region before beginning a new route. Only destinations actually mentioned by those locals are updated. Dated reports retain their own age and source.

The first-month audit compares mercenary, trader and mixed companies across six seeds before and after that fix. The policies use visible terrain, literal written directions, local boards and remembered market prices. They cannot see hidden destination coordinates or live remote prices. These are automated policy results, not human win rates.

[Results, limitations and reproduction](docs/FIRST-MONTH-0.44.md) · [Landmark directions](docs/LANDMARK-DIRECTIONS-0.43.md) · [Previous README](docs/README-v0.43.md)

## Play and compatibility

Extract this archive, import `project.godot` in **Godot 4.4.1**, and run with F5. This is source, not a standalone executable.

Existing saves keep their maps, resources, companies, reports and bookmarks. No migration or new company is required. After loading, ask locals to refresh directions from your present town. Reading the journal alone does not update information.

Use **Local Rumours → Destinations → Read Directions**. **Bookmark Directions** keeps a short note on the map; **Lead Journal** reopens the full directions. North is up. Follow named bridges and waystones as ordinary exploration reveals them. Conditions can change before arrival.

Overworld: WASD/arrows or middle drag pan; mouse wheel or −/+ zoom; Home follows the company. Space pauses; 1/2/3 change speed. **In battle, Space waits / F ends activation.** F5 saves; F9 loads.

Use **Market · Cargo & Supplies → Trade Goods** to trade, **Town Work** for material needs and inbound cargo, and **Trade & Roads** for shipments. Towns buy, consume and ship real goods; raiders can capture them and camps can contain material loot.

This build continues the 0.43 prototype. Other chats' separate integration packs are not silently merged. Older discovery, caravan and dungeon clue systems retain their existing behavior.
