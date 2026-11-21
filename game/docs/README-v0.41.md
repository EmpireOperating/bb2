# Battle Brothers 2 — expanded region 0.41

A Godot source prototype with randomized mercenaries, layered armour, individual initiative and a living, open-ended campaign.

## New in 0.41

New companies explore a map four times the former area: six towns, six farms/councils, ten caravan routes and 10–12 camps. Independent town markets, workshops, material caravans and world-funded contracts work across both districts. Pan, zoom and follow controls make the larger map navigable.

With the unchanged eight-seed test policy, mercenary survival rose from 0/8 to 1/8. In a separate four-seed comparison that searches every town, survival was 0/4 on the small map and 4/4 on the expanded map. These are policy outcomes, not human win rates or a claim that balance is finished.

[Full comparison, native journey and validation](docs/EXPANDED-REGION-0.41.md) · [0.40 audit](docs/ECONOMY-AUDIT-0.40.md) · [Previous README](docs/README-v0.40.md)

## Play and compatibility

Extract this archive, import `project.godot` in **Godot 4.4.1**, and run with F5. This is source, not a standalone executable.

Start a **New company** for the expanded region. Existing saves keep their original maps and progress. Three random founders start modestly equipped; company limits remain 20 living / 12 deployed. Repairs and healing remain passive. Battles pause world time. The campaign has no day-30 cutoff.

Overworld: WASD/arrows or middle drag pan; mouse wheel or −/+ zoom; Home follows the company. Space pauses; 1/2/3 change speed. **In battle, Space waits / F ends activation.** F5 saves; F9 loads.

Open **Market · Cargo & Supplies → Trade Goods** to trade, **Town Work** for material needs and inbound cargo, and **Trade & Roads** for shipments. Towns buy, use and ship real goods; raiders can capture them and camps may contain material loot.
