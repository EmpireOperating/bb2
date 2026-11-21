# Battle Brothers 2 — living economy 0.37

A Godot source prototype with randomized mercenaries, layered armour, individual initiative, a generated region and an open-ended campaign.

## New in 0.37

- **Trade Goods:** furs, cloth, silk and salt are dedicated cargo. They are produced and consumed in towns and never feed, heal, repair or equip your company.
- **Supplies:** rations, tools, medicine and ammunition remain separate usable resources, with finite local stocks and prices that respond to scarcity. Food deliveries, raids, local production and player trades affect availability.
- **World-caused contracts:** boards offer actual camp clearances, stolen shipment recovery and exposed loaded wagons. Weekly independent gang bounties are removed from the new economy. Secure roads generate no standing escort subscription.
- Council money is reserved when you sign. Victory or delivery pays that reserve; cancellation, expiry or outside resolution returns it. New jobs require available funds. Promised payment is protected from patrol spending.
- Camps yield actual unpacked food, coins stolen in raids, battlefield equipment and their existing named-drop roll. Roaming parties and unsigned camps no longer create flat cash rewards. Identifiable freight continues to its owner.
- Merchant purses persist across weekly equipment restocks. Company purchases and local retail activity replenish them; equipment and resource sales spend from the same purse.

Open **Market · Cargo & Supplies** from the town panel, or **Company & Equipment → Trade & Salvage**. Switch between **Trade Goods** and **Supplies**. Each row shows company/town quantities and current buy/sell quotes. Transactions update prices immediately. Cargo is included in F5/F9 saves.

## Play and compatibility

Extract this archive, import `project.godot` in **Godot 4.4.1**, and run with F5. This is source, not a standalone executable.

Three random founders start with modest equipment and ordinary company resources. The company limit remains 20 living / 12 deployed. New campaigns have no day-30 cutoff. Battles pause world time; travel and rest consume time, wages and food. Repairs and healing remain passive.

Older companies retain their map, people, equipment, money, losses and signed payment. The native game adopts the economy when loading an open company in camp, or after returning from an older battle. Month-ended survivors can Continue and adopt it then. No company resources are granted. The one already-signed old contract is honoured under its original quote; future boards follow the world.

The save remains `user://ashen-company-save.json`; new economy saves use wrapper 33 and need this build or newer. Earlier model fixtures can still explicitly exercise their historical rules.

**Space waits / F ends activation** in battle. On the overworld, Space pauses and 1/2/3 change speed. Formation and reserves are managed from Company & Equipment. F5 saves; F9 loads.

[Economy rules, evidence and limits](docs/ECONOMY-0.37.md) · [Previous release](docs/README-v0.36.md)
