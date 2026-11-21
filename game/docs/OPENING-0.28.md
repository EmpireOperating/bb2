# Humble beginnings — 0.28

Implemented on the complete delivered 0.27 project. The free-roaming overworld, all ten weapon groups, ammunition supply, layered armour comparisons, initiative, talents and development remain.

## A company worth building

Three founders receive cheap physical equipment, with their original independent identity/stat/talent rolls. All 30 saved recruitment offers also use modest kits. Names and rolls retain the old population draw sequence: the first three of the former six founders are kept and the original recruit identities remain. Equipment selection does not change generated perk groups. At most one founder starts ranged, and at least one melee founder has a shield. A ranged founder can later specialize in any available build.

| New item | Capacity / defence | Load | Base price |
|---|---:|---:|---:|
| Wool tunic | 12 body base | 1 | 10 |
| Leather jerkin | 30 body outer | 3 | 30 |
| Thick felt cap | 12 helmet padding | 1 | 10 |
| Simple iron helmet | 35 helmet shell | 3 | 25 |
| Wooden buckler | 16 condition; 8 melee / 8 ranged defence | 5 | 15 |
| Wooden round shield | 24 condition; 12 melee / 12 ranged defence | 8 | 28 |

Prices are base catalogue values; shops retain economic modifiers. Existing heater shields still provide 20 melee / 15 ranged defence with 40 condition and 12 load. Portraits distinguish the smaller buckler and wooden round shield.

Founders and ordinary recruits start with linen/light quilting, occasional leather outer protection, felt caps or simple iron helmets. Weapons are short swords, militia spears, hatchets, clubs, knives, short bows or bolas. Ranged kits carry a knife. Mail and plate are progression purchases or loot. The new company receives 300 crowns, 24 rations, 20 tools, 6 medicine, 60 ammunition and one spare knife.

Blackwater Ford uses bandit thugs: two scouts, or `min(4, 2 + threat)` enemies in a camp/contract fight. At initial threat this means three opponents. Thugs use cheap weapons and thin clothing, with occasional leather, caps or bucklers. Other areas retain stronger raiders/deserters. The initial clear contract pays 190 crowns before reputation modifiers. New-company contract rewards grant four tools and one medicine, without the old automatic premium armour item.

## Recovery over world time

| Mechanic | Travelling or uncamped | Camping |
|---|---|---|
| Natural HP healing | 1 HP per hour | 2 HP per hour |
| Equipped armour/shield repair | 4 condition per companion per hour | 6 per companion per hour |
| Queued company stores | 4 condition per hour across one shared queue | 6 across the queue |

Natural HP recovery requires enough food to feed the living company. It requires no medicine. Armour and shield repair needs tools: **one tool supplies 12 repair points**. Worn kit, carried shields and explicitly queued stores participate. Repair attempts are shared across queues one point at a time; unused tool credit persists. Empty tools stop repairs after credit is exhausted. No equipment durability is restored merely by opening a panel or completing a battle.

Movement, scouting interruptions and camping use the same fixed world clock. An hour is 20 three-minute steps. Pausing, inspection and company screens do not advance recovery. Midnight does not apply a second day's recovery. The older day-based travel/rest helper used by model tests applies 24 hours for the elapsed day; tactical battle settlement retains its day cost without extra healing.

The existing generic **Deep wound** lasts one to three injury days. Each 24 treatment hours consumes one medicine, charged when that treatment day begins. Food is also required. Temple care costs **40 crowns per injured companion** and doubles temporary-injury treatment progress until healed; medicine is still used. Temple care does not instantly restore HP or remove permanent scars. This is a small injury model, not a port of the full Battle Brothers injury catalogue.

`Trade & Salvage → Queue repairs` starts timed work for a stored component, kit or shield. A second click cancels it; equipping or selling removes the relevant stored entry. Healthy items leave the queue. The displayed tool amount is an estimate before shared offcut credit, not an immediate charge. Company screens report recovery estimates and supply shortages.

## Inventory and inspection

New battles charge **4 AP / 0 fatigue** for ordinary swaps. Quick Hands provides the first eligible free swap each round. Hybridization retains its throwing-related free swap and shares that allowance. Waiting does not reset it. Any shield exchange, including putting away a shield to draw a two-handed weapon, costs AP. The shield needs another unlocked empty bag slot.

**Bags and Belts** is a shared tier-one perk in newly generated personal pool version 6. It adds `carry3` and `carry4` and removes carried equipment load except for two-handed weapons. Equipped load is unchanged. Extra bags support weapons, shields and ammo packs, including refills and ownership/save validation. Loaded crossbows remain physical items with their own loaded state. Both controllers use the same costs and shield definitions.

**I**, the Inspect companion button or double-clicking a friendly fighter opens live stats, equipment, learned perks and active effects. It works during enemy activation and pauses processing while open. It is read-only: F and Space do not spend a turn through the modal. Escape closes it; F5/F9 remain available.

## Exploration

Opaque fog covers unknown cells and map boundaries. Roads, terrain, routes, place icons and hitboxes are hidden there. Reports filter unknown sites. Contracts provide destination names and rough bearings without exposing geography. Once an icon is discovered, select it and use Set course to enter that site; clicking arbitrary ground alone is a wilderness destination.

![Unknown land conceals roads and places](opening-world.png)

![Read-only live combat equipment](opening-inspection-equipment.png)

![Earned mail fitted after the first contract](opening-earned-mail.png)

## Save compatibility and limitations

Campaign 23 adds `opening_rules`, `recovery` and `recovery_pending`; battle 20 enables new inventory costs. Overworld schema 1 is unchanged. Old companies retain their original opening rules, six-founder roster, equipment, markets and saved trees. Old ongoing encounters finish with their saved tactical behavior and settlement; timed recovery begins at camp. Their next battle adopts current swap costs. Old saved personal pools do not receive a forced new choice or reroll; begin a new company for Bags and Belts and the modest opening.

The world is still one fixed region with six locations, a six-person living roster limit and the 30-day prototype ending. Bolas do damage without entangling. The new cheap gear is an opening progression pass, not a complete rewrite of late-game prices or balance. See [validation and trial limits](VALIDATION.md).
