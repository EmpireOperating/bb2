# Battle Brothers 2 — town industry 0.38

A Godot source prototype with randomized mercenaries, layered armour, individual initiative, a generated region and an open-ended campaign.

## New in 0.38

Trade goods now have specific uses in the world, with production orders, labour costs and persistent inventories.

| Cargo | Uses |
| --- | --- |
| Lumber | Farm and town repairs, freight wagons, shields, weapon shafts and ammunition |
| Iron | Weapons, armour, tools, ammunition and wagon fittings |
| Grain | Mill and bakery output: usable town rations |
| Hides | Leather armour, shields and wagon harnesses |
| Cloth | Clothing, padded armour, overclothes and medical dressings |
| Furs | Warm clothing, bedding and mantles |
| Salt | Preserving surplus town food |
| Silk | Prosperous household demand and fine overclothes |

- Real raids create repair needs. Damaged farms require materials and council funding before safe repair time can count down.
- Freight dispatch requires a vehicle. Captured vehicles remain unavailable; builders use lumber, iron and hides for replacements. Delivered wagons return after their return journey time.
- Equipment stock persists. Buying an item empties that shelf; replacements require workshop inputs and labour. Weekly changes still affect the available selection, but do not create replacement stock.
- Local raw production has storage limits, costs wages and slows under hardship. Grain, hides and cloth production also depends on working farms.
- Household clothing wears out. Silk orders require prosperity; essential shortages and damage take priority over workshop expansion.
- Prices respond to stock and affordable orders. No funds or missing inputs means work waits. Merchant purses, council accounts and company cargo remain distinct.

Open **Market · Cargo & Supplies** in town. **Trade Goods** has two pages; **Town Work** explains current inputs, who pays, and what is missing. Towns manage production automatically. Trading cargo does not directly feed or repair the mercenary company.

## Play and compatibility

Extract this archive, import `project.godot` in **Godot 4.4.1**, and run with F5. This is source, not a standalone executable.

Three random founders start with modest equipment. Company capacity remains 20 living / 12 deployed. Campaigns have no day-30 cutoff. Battles pause world time; travel and rest consume time, wages and food. Company repairs and healing remain passive.

Existing 0.37 saves retain money, equipment, cargo, debts, contracts and resource histories. They adopt the new town industry, material stocks and freight capacity without any company grant. Older companies still adopt the economy on returning to camp. The save remains `user://ashen-company-save.json`; wrapper 33 now contains economy schema 2. Use this build or newer for new saves.

**Space waits / F ends activation** in battle. On the overworld, Space pauses and 1/2/3 change speed. Formation and reserves are managed from Company & Equipment. F5 saves; F9 loads.

Native trade, material purchases, a live camp battle and save/load were exercised. Four fresh 45-day automated careers produced two survivors, one wage disbanding and one wipe. This is a challenge sample, not proof that every company size is balanced.

[Industry rules, evidence and limits](docs/INDUSTRY-0.38.md) · [Previous release](docs/README-v0.37.md)
