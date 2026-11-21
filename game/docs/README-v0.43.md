# Battle Brothers 2 — landmark directions 0.43

A Godot source prototype with randomized mercenaries, layered armour, individual initiative and a living, open-ended campaign.

## New in 0.43

Town leads now give written directions from the place where you heard them, via named bridges and roadside waystones. **Read Directions** replaces **Show Search Area**. Bookmarks keep the words handy without moving the camera, revealing terrain or placing a destination circle.

For example: “From Stonewick, follow the road generally east to Hare Waystone.” Later steps name the bridge, the next waystone and the destination. Named features appear when ordinary exploration reveals them. Nearby towns can use the departure town alone as their landmark.

[Feature and verification](docs/LANDMARK-DIRECTIONS-0.43.md) · [Previous README](docs/README-v0.42.md)

## Play and compatibility

Extract this archive, import `project.godot` in **Godot 4.4.1**, and run with F5. This is source, not a standalone executable.

Existing saves keep their map, resources, company, dated reports and progress. An old town search pin becomes a text bookmark. A new company is only needed if you want the expanded six-town geography and your old save predates it.

Use **Local Rumours → Destinations → Read Directions**. **Bookmark Directions** keeps a short note on the map; **Lead Journal** reopens the full directions. North is up. The notes refer to their original town, not your current position. Reports can go stale; contracts and prices may change before arrival.

Overworld: WASD/arrows or middle drag pan; mouse wheel or −/+ zoom; Home follows the company. Space pauses; 1/2/3 change speed. **In battle, Space waits / F ends activation.** F5 saves; F9 loads.

Use **Market · Cargo & Supplies → Trade Goods** to trade, **Town Work** for material needs and inbound cargo, and **Trade & Roads** for shipments. Towns buy, use and ship real goods; raiders can capture them and camps can contain material loot.

This release updates the regional-news town leads from 0.42. Separate discovery, caravan and dungeon rumours retain their existing systems; separately supplied integration packs are not bundled into this release.
