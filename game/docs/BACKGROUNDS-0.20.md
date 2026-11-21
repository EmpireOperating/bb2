# Open builds — 0.20

**Historical generation rules.** The current ten-group draw is documented in [0.26](HAMMER-DAGGER-0.26.md).

A background describes a past occupation. It changes selection odds without granting an exclusive class or excluding any perk group. New people receive four of six weapon groups, two of three armour groups, two of four styles and two of four character groups. Six fundamentals are shared. Duplicated perks appear once. All 1,620 group combinations have positive probability for every background; they contain 35–42 unique perks. Each character still buys at most ten.

Every selected group is drawn without replacement from its category. Groups listed below have weight 2; every other group has weight 1. A 2:1 weight is a per-draw preference, not twice the final inclusion probability. Individual groups can be absent even when favoured.

| Background | Weapon preferences | Armour preferences | Style preferences | Character preferences |
|---|---|---|---|---|
| Militia | Spear, Sword, Crossbow | Medium, Heavy | Shield | Trained, Tough |
| Poacher | Bow, Throwing | Light | Swift, Marksman | Fast, Vigorous |
| Woodcutter | Polearm, Throwing | Medium | Power | Tough, Vigorous |
| Deserter | Sword, Crossbow | Medium | Swift | Trained, Fast |
| Caravan guard | Spear, Crossbow | Medium | Shield | Trained, Vigorous |
| Farmhand | Spear, Polearm | Light | Power | Tough, Vigorous |
| Gravedigger | Polearm, Crossbow | Medium | Shield | Tough, Trained |
| Outrider | Bow, Sword | Light | Swift, Marksman | Fast, Trained |

## What determines a build

Starting stats retain their existing background ranges. Any of the eight stats can receive a talent; this change neither weights nor rerolls stars. Independent random streams generate the tree and final weapon kit. Stats and equipment do not decide tree access. A recruit may have strong ranged growth and melee options, or arrive carrying a sword with Bow and Throwing groups. There is no hidden class flag. Random personal pools still limit which perks that individual can learn; they do not limit weapon use.

Gear is chosen after the tree. The primary weapon comes from one of the four represented weapon groups, with mild occupation and current-skill preferences. One-handed kits may have shields; ranged and polearm kits receive a melee backup. Bow/crossbow ammunition matches the weapon. These equipment preferences never feed back into the tree or stars. Founder safeguards may substitute a sword or spear and shield to keep at least three melee shields and at most two ranged primaries; the tree stays exact even if the substituted weapon lacks a mastery. At least two founders retain mail. Other weapon families remain available through equipment and shops.

The exact tree is visible before hiring. Hiring, equipping a different weapon, opening the screen and saving/loading cannot reroll it. Existing 0.19 soldiers and all their generated weekly offers keep their exact options and purchased perks. The whole 36-person company population is generated at company creation, so the new algorithm requires a new company. Earlier migration rules and the explicit demo presets are retained.

## Observed variation

The production generator was sampled across 200 seeds: 1,200 founders and 6,000 weekly offers. Every individual group appeared and was absent within every background. The table shows actual inclusion counts, not theoretical probabilities or combat performance.

| Background | People | Distinct trees | Bow present | Spear present |
|---|---:|---:|---:|---:|
| Caravan guard | 890 | 563 | 513 | 742 |
| Deserter | 911 | 613 | 555 | 539 |
| Farmhand | 930 | 603 | 540 | 755 |
| Gravedigger | 923 | 592 | 538 | 537 |
| Militia | 852 | 529 | 460 | 679 |
| Outrider | 897 | 569 | 758 | 509 |
| Poacher | 914 | 583 | 765 | 526 |
| Woodcutter | 883 | 584 | 512 | 539 |

Identity, raw combat stats, all stars and future stat-growth rolls match the same-seed 0.19 population exactly. Historical preliminary equipment draws are consumed only to preserve that population sequence, then replaced by the independently selected final kit. Existing recruitment price and wage formulas are unchanged; kit/career economic balance remains a prototype consideration.

[Machine-readable sample](background-generation-v0.20.json) · [Validation](VALIDATION.md)

![Actual prehire tree](background-recruit-tree.png)
