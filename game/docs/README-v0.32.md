# Battle Brothers 2 — company formation 0.32

A Godot source prototype of a thirty-day mercenary campaign: random companions, layered armour, physical weapons and ammunition, individual initiative and a generated overworld.

**20 living mercenaries, up to 12 deployed.** Manage your formation and reserves from the overworld's **Company & Equipment → Formation & Reserves**. Battles use that lineup automatically.

## Play

1. Extract the archive, import `project.godot` in **Godot 4.4.1** and run with the editor's F5. This is a source project, not a standalone executable.
2. A new company still starts with three random founders, modest gear, 300 crowns, 24 food, 20 tools, 6 medicine and 60 ammunition. Recruit gradually; all living mercenaries need wages and food.
3. Open **Company & Equipment → Formation & Reserves**. Drag a companion to a front/back position or into reserves. Alternatively select a companion, then click a destination. Dragging onto an occupied position swaps the occupants; a reserve displaces the occupant into reserves. Changes save immediately.
4. Up to twelve companions occupy the eighteen available positions (two rows of nine). Positions express a front and back line, facing the enemy. New recruits fill the field until twelve, then join reserves. Backgrounds never restrict where you place anyone.
5. Reserves recover normally and retain their equipment. They take no combat damage and receive no combat XP. They do not replace casualties in the middle of battle. Fallen companions are removed from future formation positions.
6. Formation editing locks once an encounter is pending. Assign at least one fighter before setting out; time stays paused while everyone is in reserve. Hunting-party ambushes scatter the deployed group without changing your saved formation; reserves remain off the field.
7. In battle, the gold portrait acts. **Space** waits; **F** ends that activation. Use the turn-order arrows when more than twelve fighters are queued. **I** or double-click an ally opens paused inspection, including all twelve deployed companions. Ordinary weapon swaps cost **4 AP**; Quick Hands and Bags and Belts retain their rules.
8. **F5/F9** saves/loads the company, lineup, reserves, equipment, ongoing battles and overworld. On the map, **Space** pauses and **1/2/3** set speed. Select visible sites or ground to travel; right-click stops. Unknown terrain and roads remain hidden.
9. Start with thugs and manageable work. Armour repairs and healing happen over time using supplies; temples treat injuries. Guarded deliveries offer lower-paying work while recovering. Complete four contracts or eliminate every raider band, and finish the month debt-free.

![Company formation and reserves](docs/roster-full.png)

## Existing saves

Existing companies and battles load with their original rules. At camp, open **Formation & Reserves** to enable the twenty-person roster and assign your surviving company. Finish an ongoing battle or pending encounter first. No restart or reroll is required. This adoption is saved immediately; retain a separate backup if you want to continue that file in an older build.

New native companies use campaign schema **27**, roster rules **1** and battle schema **21**. Progression, traffic and band rules remain 1/2/2. Old campaign and battle snapshots retain their historical schema until adoption; an ongoing old battle continues exactly.

## Scope and limits

The battlefield, initiative queue, inspection, equipment targets and settlement support twelve fighters per side. The campaign still uses its existing small authored enemy groups, including thugs in the opening. This release adds room to grow; it does not establish final difficulty for a fully developed twelve-person company. Special-origin roster limits are not included.

The three towns, three camps, three discoveries and thirty-day campaign remain. Living trade and bands, passive recovery, armour layers, weapon maths, ammunition, talents and unrestricted perk development are retained. No Farm Supply, Physical Patrols or Named Equipment pack was added.

[Formation details](docs/COMPANY-ROSTER-0.32.md) · [Validation](docs/VALIDATION.md) · [Previous release](docs/README-v0.31.md) · [Living bands](docs/LIVING-BANDS.md) · [Living trade](docs/LIVING-TRADE.md).
