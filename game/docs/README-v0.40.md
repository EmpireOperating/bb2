# Battle Brothers 2 — early economy audit 0.40

A Godot source prototype with randomized mercenaries, layered armour, individual initiative, a generated region and an open-ended campaign.

## New in 0.40

This is a balance-audit release, with improved automated company decisions, complete cash accounting and reproducible earned saves. Gameplay economics and combat difficulty remain unchanged from 0.39.

Across eight seeds: traders survived 8/8, mixed companies 6/8, and compact mercenary companies 0/8. A further eight mercenary runs allowed recruitment up to six after the first paid victory; none survived. These are policy outcomes, not human win rates. The combat-only path needs further investigation, particularly available work after clearing the early camps.

A native fresh-company test bought cargo for 172 crowns, sold it for 255 after real travel, hired a fourth mercenary for 107, and retained 267 crowns. Save/load passed throughout.

[Full audit, financial breakdowns and limitations](docs/ECONOMY-AUDIT-0.40.md) · [0.39 material caravans](docs/MATERIAL-FREIGHT-0.39.md) · [Previous README](docs/README-v0.39.md)

## Play and compatibility

Extract this archive, import `project.godot` in **Godot 4.4.1**, and run with F5. This is source, not a standalone executable.

Three random founders start modestly equipped; company limits remain 20 living / 12 deployed. Battles pause world time. Repairs and healing remain passive. The campaign has no day-30 cutoff.

0.39 saves are unchanged; earlier migration paths remain supported. Save wrapper 33 / economy schema 3 is unchanged. No grants are made when loading.

**Space waits / F ends activation** in battle. On the overworld, Space pauses and 1/2/3 change speed. F5 saves; F9 loads.

Open **Market · Cargo & Supplies → Trade Goods** for trade, **Town Work** for material needs and inbound cargo, and **Trade & Road Report** for physical shipments. Towns buy, use and ship real goods; raiders can capture them, and camps may contain sellable material loot.
