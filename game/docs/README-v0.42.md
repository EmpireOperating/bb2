# Battle Brothers 2 — regional news 0.42

A Godot source prototype with randomized mercenaries, layered armour, individual initiative and a living, open-ended campaign.

## New in 0.42

**Local Rumours** now gives dated reports about road trouble, farms, overdue shipments and workshop shortages. Actual caravans carry news between towns. A persistent **Lead Journal** remembers what you heard, its source and age, and directions to other towns. **Show Search Area** helps you explore while preserving fog of war.

Three of four information-limited test companies survived beyond day 45 and reached all six towns; one was wiped out on day 6. Payouts, starting equipment and combat math are unchanged. These are automated policy outcomes, not a finished balance claim.

[Feature, tests and screenshots](docs/REGIONAL-NEWS-0.42.md) · [Expanded-region audit](docs/EXPANDED-REGION-0.41.md) · [Previous README](docs/README-v0.41.md)

## Play and compatibility

Extract this archive, import `project.godot` in **Godot 4.4.1**, and run with F5. This is source, not a standalone executable.

Start a **New company** for the expanded region: six towns, six farms/councils, ten caravan routes and 10–12 camps. Existing saves keep their maps and progress; asking for Local Rumours starts their news journal. Three random founders start modestly equipped. Company limits remain 20 living / 12 deployed. Repairs and healing remain passive; battles pause world time. There is no day-30 cutoff.

Overworld: WASD/arrows or middle drag pan; mouse wheel or −/+ zoom; Home follows the company. Space pauses; 1/2/3 change speed. **In battle, Space waits / F ends activation.** F5 saves; F9 loads.

In town, use **Local Rumours → Destinations → Show Search Area** to find new places. Reopen **Lead Journal** on the overworld to review your notes. Reports can go stale; contracts and prices may change before you arrive.

Use **Market · Cargo & Supplies → Trade Goods** to trade, **Town Work** for material needs and inbound cargo, and **Trade & Roads** for shipments. Towns buy, use and ship real goods; raiders can capture them and camps can contain material loot.
