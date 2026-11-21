# Battle Brothers 2 — material caravans 0.39

A Godot source prototype with randomized mercenaries, layered armour, individual initiative, a generated region and an open-ended campaign.

## New in 0.39

Towns now buy and physically transport trade goods without waiting for the player.

- Producers sell surplus to buyers with shortages and enough money. The buyer pays for the goods and haulage at dispatch; the producer's actual stock is removed immediately.
- Material wagons use the existing world roads in either direction. The buyer receives stock only when the wagon arrives. Shipments share the material-built vehicle fleet with food traffic.
- Existing raider bands can attack, haul away and capture material wagons. No separate enemies are spawned for a shipment.
- Exposed waiting wagons generate funded escort work. Stolen shipments generate recovery jobs. Defended or recovered cargo continues to its purchasing town.
- After two days in captivity, goods are unpacked into camp stores. Destroying that camp lets the company loot those goods; intact freight is released to its buyer. Signed recovery work keeps its shipment reserved for the buyer.
- Looted trade goods go into normal company cargo and can be sold. Cargo, payment, delivery and loot cannot settle twice through repeated saves or synchronization.
- The road report names the goods and records the buyer's payment. Reports associated with known towns can show unknown endpoints as **Unknown**, without revealing terrain or roads. **Town Work** shows paid cargo on its way.

Open **Market · Cargo & Supplies → Trade Goods** to buy or sell cargo, **Town Work** to inspect material needs and incoming quantities, and **Trade & Road Report** to inspect shipments.

## Play and compatibility

Extract this archive, import `project.godot` in **Godot 4.4.1**, and run with F5. This is source, not a standalone executable.

Three random founders start modestly equipped; company limits remain 20 living / 12 deployed. Battles pause world time. Repairs and healing remain passive. The campaign has no day-30 cutoff.

0.38 saves preserve company money, equipment, cargo, existing industry, merchant balances and food wagons. Adoption creates no free company goods or artificial deliveries. New material trade starts on subsequent days. The outer save wrapper remains 33, now with economy schema 3; new saves need this build or newer. Earlier 0.37 and older migration paths remain supported.

**Space waits / F ends activation** in battle. On the overworld, Space pauses and 1/2/3 change speed. F5 saves; F9 loads.

Native validation covered migration, autonomous delivery, natural capture, a live camp battle, cargo loot, sale and save/load. Four fresh automated careers reached one 45-day survivor, two wage disbandings and one wipe. NPC trade reduces easy margins; this is not a claim that economic balance is finished.

[Material freight rules, evidence and limits](docs/MATERIAL-FREIGHT-0.39.md) · [Previous release](docs/README-v0.38.md)
