# Battle Brothers 2 — living overworld 0.31

A Godot source prototype of a thirty-day mercenary campaign: three random founders, layered armour, physical weapons and ammunition, personal stats/talents/perks, individual initiative and a generated overworld.

**Start a new company for roaming-band decisions and physical caravan raids.** Existing 0.30 saves keep their original campaign rules. The Living Bands pack and its Living Trade dependency are now integrated with 0.30 progression; Farm Supply is not included.

## Play

1. Extract the archive. Import `project.godot` in **Godot 4.4.1**, the tested version, then run with the editor's F5. This is source, not a standalone executable.
2. Choose **New company** and enter a seed, or press **R** to roll one. Three founders start with modest gear, 300 crowns, 24 food, 20 tools, 6 medicine and 60 ammunition. Recruit up to six living companions.
3. Start with the Crossing Outlaws contract. Keep a supply/wage reserve and consider a fourth companion. Visible camps and encounters show troop type and count. Stronger enemies do not scale to your equipment or level.
4. Click ground to travel; select discovered sites and **Set course**. Unknown terrain, roads and sites stay hidden. **Space** pauses the map; **1/2/3** change speed. Sightings, arrival and contact pause automatically.
5. Click a visible roaming party to pursue it. Its sidebar identifies the troops, activity and surviving headcount. Small bands can flee; dangerous bands may hunt you. Pursuit stops when sight is lost. **Stop & pause** or right-click cancels movement.
6. Select a caravan under attack and choose **Intervene**. Reach the raiders to fight or intimidate them. Freed cargo resumes its actual journey to town; it is not company food. Driving raiders away alone pays no bounty. An abandoned wreck can be reached and inspected for tracks to its camp.
7. After a fight, recover, train and equip loot. Worn armour and shields repair over time using tools; food permits HP recovery; medicine treats temporary injuries. Temples speed injury treatment. Lower-paying guarded delivery jobs let you work while recovering. Road security can change before arrival.
8. **Company & Equipment** offers armour and weapon comparisons, training, bags, trading and service histories. Armour comparisons show current/max protection and fully repaired capacity changes. Town services require physical presence.
9. In battle, the gold portrait acts. **Space** waits; **F** ends that fighter's activation. **I** or double-click an ally for paused, read-only inspection. Normal equipment swaps cost **4 AP**; Quick Hands and Bags and Belts retain their existing rules.
10. **F5/F9** saves/loads people, gear, battles, partial recovery, routes, freight and band casualties. Finish day thirty debt-free and fulfil four contracts or remove every raider band.

## What changed

- Finite camp parties scout wider routes, hunt vulnerable visible companies, flee stronger ones, raid freight and return home to rest. A strength estimate guides their decisions; it does not alter combat stats.
- Dead band members remain dead after withdrawal. Wounded survivors recover only after physically reaching camp. Clearing a camp removes that generation's roaming party. A failed assault leaves it active.
- Autonomous caravans now travel physically. Raiders must catch them and break their guards before hauling food back to camp. Goods cannot fund a camp until they arrive. Intervention, patrol protection or camp destruction can free them.
- Missing-caravan rumours, wreck inspection and visible return tracks connect trade losses to their responsible camp. Evidence supplies a camp clue without revealing surrounding terrain.
- Party rosters use 0.30's smaller, graded enemy groups. Starts, armour prices, guarded escort work, passive recovery, equipment, ammunition, perks and tactical rules are retained.
- Wagons, wrecks and bands remain clickable when their markers overlap a site's larger selection area. Their detail panels remain selected while travelling from town.

[Living bands](LIVING-BANDS.md) · [Living trade](LIVING-TRADE.md) · [0.30 progression](CAMPAIGN-0.30.md) · [validation](VALIDATION.md).

![A caravan under attack](living-raid.png)

## Balance and limits

The same two cautious campaign policies were rerun across eight seeds: **13 of 16 companies reached a successful ending**, with **113 fulfilled contracts, 48 battles, 45 deaths and 29 replacement hires**. The policies know destination coordinates, use the production combat AI and prefer guarded delivery work. No money, equipment, damage, wins or casualties were fabricated. Three companies wiped out; one surviving company finished with only one mercenary. These results expose risk and viable recovery routes, not final human difficulty balance. [Full records](month-campaigns-0.31.json).

There is still one finite field party per camp generation, three towns, three camps and three discoveries. Funded camp reoccupation retains its four-day quiet period. No independent armies, field recruitment, farm raids or moving camps were added. NPC caravan defence uses a four-hour timer; player fights use real tactical combat. Persistent raiders keep casualties and health, while their equipment still comes from the existing encounter generator. Pre-battle deployment and additional battlefield variety remain later work.

## Saves and retained systems

New native companies use campaign schema **26**, progression **1**, traffic **2** and band roster **2**. Existing 0.30 saves retain their prior rules and exact snapshots. Separate schema-24 trade/schema-25 band previews are distinguished from main saves, migrated without rerolling maps or parties, and retain their original trade/roaming decisions and movement. They adopt the standard passive-recovery migration at camp. The filename remains `user://ashen-company-save.json`; battle schema 20 and inventory/perk formats are unchanged.

Bodies retain six layers and helmets five parts. Combat reports total armour and HP damage. There are eight trainable attributes, three talent-star levels, 69 authored perks and ten weapon groups. Backgrounds influence probabilities without excluding builds. Equipment, combat, people, progression, perks, recovery, map generation and all data catalogues are byte-identical to 0.30.

Historical references: [0.30 validation](VALIDATION-v0.30.md), [0.29 maps](PROCEDURAL-MAPS-v0.29.md), [0.28 opening](OPENING-0.28.md), [combat baseline](COMBAT-BASELINE-0.16.md), [ammunition](AMMUNITION-0.27.md).
