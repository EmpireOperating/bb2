# Battle Brothers 2 — integrated campaign 0.34

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

## New in 0.34: road bounties

Town boards now offer **outlaw hunts** and **stolen-arms recovery** from day 8, followed by **mercenary blockades** from day 15. Postings refresh weekly. Each shows its fixed enemy force, destination, pay and deadline. Accept at a town, travel to the named landmark, then deploy from the accepted-contract panel. These fights are separate from the local camp garrison.

Base rewards are **440 / 650 / 980 crowns**, adjusted by the client's reputation when signing. Victory earns the quoted payment and ordinary battlefield salvage. Retreat, abandonment and expiry close that posting unpaid. Your company's level, gear and headcount never scale these forces or gate acceptance.

[Contract rules and balance evidence](docs/ROAD-CONTRACTS-0.34.md) · [Previous release](docs/README-v0.33.md).

![Weekly road bounties](docs/road-board-road_blockade.png)

## Existing saves

Existing companies and battles load with their original rules. At camp, open **Formation & Reserves** to enable the twenty-person roster and assign your surviving company. Finish an ongoing battle or pending encounter first. No restart or reroll is required. This adoption is saved immediately; retain a separate backup if you want to continue that file in an older build.

New companies enable farm supply, physical patrols, named equipment and persistent undead dungeons alongside formation/reserves. Existing saves keep their capabilities and original rules; start a new company to get the entire combined world. Burial rumours can add dungeons to an existing company between encounters. Save compatibility and integration details are in `docs/INTEGRATION-0.33.md`.

Companies already using the current campaign-progression rules gain the new postings automatically; no restart or reroll is needed. Very old saves keep their original progression rules. Six-slot legacy lineups can take the five- and six-enemy jobs; enable Formation & Reserves for the eight-enemy blockade. Use 0.34 for saves carrying a new road bounty: older executables do not understand these active contract kinds.

## Integrated world additions

- **Farm Supply:** physical harvest carts, raiding bands, shortages and recovery commissions. The first farming town supplies the tested rural economy; this is not yet an all-town farm simulation.
- **Town Guard:** funded patrols travel, fight raiders, return with casualties and recover. You can approach and engage their attackers; guards do not join the tactical battlefield as allied units.
- **Burial Rumours:** discover three persistent undead complexes. Explore connected rooms and floors, fight, retreat and return. Enemy losses, damaged equipment, cleared rooms and opened chests persist. Time, wages and supplies continue underground.
- **Named equipment:** nonmagical craftsmanship bonuses, stable names and provenance. Final dungeon chests contain reserved rewards that cannot be rerolled by reloading; equipment comparisons, repairs, combat and sales use their rolled values.

Dungeons retain enemy losses, damaged gear and cleared rooms between visits. The original integration test uses a declared prepared company; the later [midgame review](docs/MIDGAME-BALANCE-0.33.md) also reproduces a full first-dungeon clear with an ordinary company, earned recruits, gear and progression. Six entered and four returned. No spells, resurrection or stat potions are included.

## Scope and limits

The battlefield, initiative queue, inspection, equipment targets and settlement support twelve fighters per side. The opening keeps its thugs, while the new road bounties field five, six or eight enemies. This release adds paid opportunities for growth; it does not establish final difficulty for a fully developed twelve-person company. Special-origin roster limits are not included.

The three towns, three camps, three discoveries and thirty-day campaign remain. Living trade and bands, passive recovery, armour layers, weapon maths, ammunition, talents and unrestricted perk development are retained.

[Formation details](docs/COMPANY-ROSTER-0.32.md) · [Integration and validation](docs/INTEGRATION-0.33.md) · [Previous release](docs/README-v0.32.md) · [Living bands](docs/LIVING-BANDS.md) · [Living trade](docs/LIVING-TRADE.md).

## Early-campaign balance review

[The ten-day review](docs/EARLY-BALANCE-0.33.md) adds 48 ordinary campaign runs, 16 town controls and a native earned-upgrade journey. That review left combat, prices, payouts and starting resources unchanged. No equipment ratings or readiness gates were added. Results and limitations are included; these are automated policies, not a guarantee of human difficulty.

## Midgame progression review

[The midgame review](docs/MIDGAME-BALANCE-0.33.md) continues all 41 surviving opening companies, records 53 policy runs and 18 matched dungeon branches, and validates an earned full dungeon clear, return to town and named weapon comparison in the native game. It identifies limited growth beyond six as an unresolved progression question. That review added tests, earned checkpoints and evidence without changing gameplay. Version 0.34 now adds intermediate contracts in response to that finding.
