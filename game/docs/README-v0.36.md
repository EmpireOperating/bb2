# Battle Brothers 2 — continuing campaign 0.36

A Godot source prototype: randomized mercenaries, layered armour, physical weapons and ammunition, individual initiative and a living generated region.

**New campaigns continue beyond day 30.** Recruits, markets, contracts, wages, recovery, farms and camps keep running. Twenty living mercenaries; twelve deployed.

## New in 0.36

- Battles pause campaign time everywhere. Victory, defeat and retreat add no days, upkeep, healing or repairs. Rewards, casualties, wounds, XP, wear and ammunition still settle immediately.
- Weekly recruits and road bounties continue after the fifth week. Ordinary contract deadlines retain their full duration when crossing day 30.
- A surviving older month-end company has a **Continue campaign** button. No resources, gear, recruits or health are granted. Wiped and disbanded companies cannot continue.
- Dungeon rest takes four hours and uses normal midnight rations/wages. The former extra full-day ration charge every four hours is removed. Recovery still needs time, tools, medicine and food; exploration still consumes scouting supplies.
- Escort caravans finish their committed leg even if a camp re-forms behind them. This fixes a delivery/save failure found in a fresh campaign.

## Play

1. Extract the archive, import `project.godot` in **Godot 4.4.1** and run with the editor's F5. This is a source project, not a standalone executable.
2. A new company still starts with three random founders, modest gear, 300 crowns, 24 food, 20 tools, 6 medicine and 60 ammunition. Recruit gradually; all living mercenaries need wages and food.
3. Open **Company & Equipment → Formation & Reserves**. Drag a companion to a front/back position or into reserves. Alternatively select a companion, then click a destination. Dragging onto an occupied position swaps the occupants; a reserve displaces the occupant into reserves. Changes save immediately.
4. Up to twelve companions occupy the eighteen available positions (two rows of nine). Positions express a front and back line, facing the enemy. New recruits fill the field until twelve, then join reserves. Backgrounds never restrict where you place anyone.
5. Reserves recover normally and retain their equipment. They take no combat damage and receive no combat XP. They do not replace casualties in the middle of battle. Fallen companions are removed from future formation positions.
6. Formation editing locks once an encounter is pending. Assign at least one fighter before setting out; time stays paused while everyone is in reserve. Hunting-party ambushes scatter the deployed group without changing your saved formation; reserves remain off the field.
7. In battle, the gold portrait acts. **Space** waits; **F** ends that activation. Use the turn-order arrows when more than twelve fighters are queued. **I** or double-click an ally opens paused inspection, including all twelve deployed companions. Ordinary weapon swaps cost **4 AP**; Quick Hands and Bags and Belts retain their rules.
8. **F5/F9** saves/loads the company, lineup, reserves, equipment, ongoing battles and overworld. On the map, **Space** pauses and **1/2/3** set speed. Select visible sites or ground to travel; right-click stops. Unknown terrain and roads remain hidden.
9. Start with thugs and manageable work. Armour repairs and healing happen over time using supplies; temples treat injuries. Guarded deliveries offer lower-paying work while recovering. New campaigns have no final day. A wipe or three unpaid days still ends the company.

## Saves and content

F5/F9 keeps the existing `ashen-company-save.json` identity. Older active companies retain their saved geography, people, equipment, dungeon tiers and month objective; at month end their survivors can continue. All active battles now use zero campaign time. Already-settled saves receive no retroactive refund. Open-campaign saves require 0.36 or newer.

The integrated three-town region, hinterlands, living camps, named drops, dungeon choices, unrestricted perks, passive recovery, ammunition and overworld formation remain. The separate **Expanded Region** map pack was inspected for conflicts but is not merged in this release.

[Current behavior, progression evidence and limits](docs/CAREER-0.36.md) · [Previous release](docs/README-v0.35.md)

Historical audits describe their own versions; their battle clocks and economic outcomes are not current balance claims.
