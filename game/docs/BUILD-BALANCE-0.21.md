# Generated build comparison — 0.21

**Historical report:** `survived` counted fighters still on the field, excluding living escapees. See [0.23 corrections and AI trace](ENGAGEMENT-AI-0.23.md) before interpreting the shield-line draws as build balance.

This pass found and fixed AI decisions. It does not establish that all builds are equally strong. Perk values, damage formulas, equipment prices and personal generation remain unchanged.

## Actual changes

- One-hex spears close to one hex. Polearms use their actual reach. Previous enemy spear positioning could wait at two hexes and never attack.
- Switching from an empty ranged weapon to a melee backup updates the enemy movement role immediately.
- Sword AI uses a primed Double Strike instead of automatically spending the remaining AP on Riposte. Riposte is considered for En Garde or multiple adjacent threats.
- Both controllers can pay for Rotation to exchange an endangered fighter with a healthy ally, Footwork to reduce engagement pressure, and Indomitable when wounded or outnumbered with incoming melee activations. Decisions use visible state and consume no planning RNG.
- Patient Hunter can wait for a viable distant aimed shot, then actually use the aimed attack. Each actor still waits at most once per round.
- Wounded fighters with escape perks penalize positions that immediately put them back into melee.

These are heuristics, not a tactical search engine. Ordinary campaign raider equipment/perk rosters were not expanded. Active-perk opponent behaviour is verified using declared trained fixtures; enemies only use abilities they possess. The normal campaign also benefits from the reach, switching and sword-decision fixes.

## Method

**54 generated careers, 8 distinct people, 1,296 completed battles.** Each of six roles takes the first eligible founder from each of three campaign seeds. Eligibility checks the required perk groups only; it does not select high stats, stars or a preferred background. A person can appear in multiple roles. Checkpoints are levels 3, 6 and 11. XP is explicitly granted through production progression; all attributes use their original saved rolls, every perk is purchased legally, and every trained career passes normal save validation. This does not establish that level 11 is naturally reachable in the 30-day slice.

Each career faces three authored opposition types (rushers, shield line, heavy armour), with two fixed supporting allies. Two battle seeds are mirrored across both faction controllers. Each encounter runs once with the retained old AI and once with the new AI, using identical starting people, equipment and seed. This is a flat-field 3v3 test, not a campaign-economy or terrain benchmark. Opposition/support stats are authored controls; only the tested mercenary is a generated career.

Common equipment ceilings are **400 / 600 / 800 crowns** at levels 3 / 6 / 11. Spending and unused reserves are recorded per career. These are equal spending limits, not identical kit prices: some light builds cannot usefully spend the entire ceiling. Existing starting kit and recruitment prices are not rewritten by this experiment. A low-level hybrid uses a shortsword and second javelin bundle to fit the same 400-crown limit.

Progression loadouts matter. The trial sword fighter keeps a shield until learning Duelist and medium protection until learning Nimble. Removing them earlier produced fragile fighters in the pilot. This is a test build policy and documented build advice, not automatic player equipment switching. Other roles train their declared three-attribute choices, visible in the source and full report.

## Paired AI results

| Policy | Fights | Tested team wins | Draws | Tested mercenary survives |
|---|---:|---:|---:|---:|
| Previous | 648 | 324 | 206 | 196 |
| New | 648 | 321 | 100 | 267 |

The tested mercenaries executed 10 Rotations, 276 Footworks, 13 Indomitables and 341 Waits under the new policy. Opponents/support allies also use their learned abilities; the counts here cover the tested mercenary only. Lower draws mostly reflect improved engagement decisions; the similar overall win count is not evidence of equal build strength.

## Roles at each checkpoint

Each row contains 36 fights: three generated careers × three opponents × two seeds × two sides. HP/armour damage and fatigue/ammunition are per-fight averages for the tested mercenary. Fatigue generated includes incoming-hit fatigue; it is not just weapon spending. Survival and team victory are deliberately separate.

### Level 3

| Role | Wins | Draws | Survives | HP damage | Armour damage | Fatigue generated | Ammo used |
|---|---:|---:|---:|---:|---:|---:|---:|
| Shield | 22/36 | 6 | 19/36 | 29.7 | 119.1 | 153.8 | 0.0 |
| Duelist | 20/36 | 5 | 5/36 | 13.4 | 83.3 | 139.5 | 0.0 |
| Polearm | 16/36 | 7 | 5/36 | 28.4 | 69.4 | 99.3 | 0.0 |
| Bow | 17/36 | 3 | 8/36 | 28.9 | 75.0 | 156.9 | 3.9 |
| Crossbow | 18/36 | 5 | 14/36 | 33.8 | 84.1 | 137.0 | 2.8 |
| Hybrid | 27/36 | 6 | 10/36 | 39.6 | 116.1 | 140.9 | 4.6 |

### Level 6

| Role | Wins | Draws | Survives | HP damage | Armour damage | Fatigue generated | Ammo used |
|---|---:|---:|---:|---:|---:|---:|---:|
| Shield | 20/36 | 5 | 24/36 | 53.1 | 182.9 | 278.2 | 0.0 |
| Duelist | 19/36 | 6 | 14/36 | 33.8 | 135.1 | 166.7 | 0.0 |
| Polearm | 21/36 | 3 | 10/36 | 57.2 | 165.9 | 142.6 | 0.0 |
| Bow | 19/36 | 2 | 17/36 | 80.4 | 191.2 | 174.0 | 7.1 |
| Crossbow | 20/36 | 3 | 7/36 | 66.4 | 149.1 | 199.8 | 4.1 |
| Hybrid | 20/36 | 5 | 12/36 | 48.7 | 170.8 | 150.6 | 4.5 |

### Level 11

| Role | Wins | Draws | Survives | HP damage | Armour damage | Fatigue generated | Ammo used |
|---|---:|---:|---:|---:|---:|---:|---:|
| Shield | 16/36 | 3 | 19/36 | 55.0 | 229.2 | 262.0 | 0.0 |
| Duelist | 7/36 | 13 | 19/36 | 39.8 | 158.1 | 209.6 | 0.0 |
| Polearm | 18/36 | 7 | 21/36 | 108.2 | 283.4 | 267.9 | 0.0 |
| Bow | 12/36 | 6 | 22/36 | 110.8 | 259.2 | 282.2 | 8.3 |
| Crossbow | 16/36 | 7 | 24/36 | 123.5 | 222.5 | 320.8 | 5.8 |
| Hybrid | 13/36 | 8 | 17/36 | 78.1 | 256.4 | 206.5 | 4.6 |

## Matchup and cost limits

| Role | Rushers: wins / 36 | Shield line: wins / 36 | Heavy armour: wins / 36 |
|---|---:|---:|---:|
| Shield | 22/36 | 13/36 | 23/36 |
| Duelist | 20/36 | 5/36 | 21/36 |
| Polearm | 22/36 | 11/36 | 22/36 |
| Bow | 16/36 | 9/36 | 23/36 |
| Crossbow | 20/36 | 9/36 | 25/36 |
| Hybrid | 23/36 | 11/36 | 26/36 |

The sample supports different battlefield contributions: shields absorb pressure, ranged/polearm builds deal damage from behind support, and hybrids use finite bundles before changing weapons. It also exposes a continuing weakness: the automated duelist struggles against shield lines, including at level eleven. This does not justify a blanket numerical buff from this small sample; manual flanking, target selection and candidate selection remain untested here. There is no claim that every random recruit is equally suited to every role.

| Role | Level 3 actual spend | Level 6 actual spend | Level 11 actual spend |
|---|---:|---:|---:|
| Shield | 360 | 405 | 711 |
| Duelist | 322 | 506 | 264–461 |
| Polearm | 370 | 554 | 554 |
| Bow | 322–369 | 414–562 | 414–611 |
| Crossbow | 351 | 591 | 640 |
| Hybrid | 393 | 565 | 614 |

## Native play and saves

The native build journey trains an actual generated level-six sword fighter through saved growth and legal perks, equips a budgeted kit, inspects the personal tree, and saves/reloads exactly. Separate declared enemy situations execute Rotation, Footwork and Indomitable through the normal native AI timer. Mid-activation and active-Indomitable saves restore exactly. A normal campaign journey also completes a battle and spends genuinely earned growth and a perk point.

Campaign schema 20; new battle schema 15 selects the new AI. An older in-progress battle continues under its saved AI and still serializes as schema 14. Three 0.20 veteran encounters preserve commands, RNG, casualties, gear, perks and settlement exactly. Existing companies receive the new AI on their next deployment; they do not need to reroll their recruits.

Reproduce the full controlled run with `godot --headless --path . --script res://tests/build_balance.gd`. `-- --role=bow` restricts the run to one role. `tests/tactical_ai.gd` covers paid actions, positioning, switching and old-battle preservation.

[Full profiles and battle rows](build-balance-results.json) · [Battle CSV](build-balance-battles.csv) · [Release validation](VALIDATION.md)

![Declared native enemy rotation fixture](build-enemy-rotation.png)

![Actual generated career after saved training](build-trained-duelist.png)
