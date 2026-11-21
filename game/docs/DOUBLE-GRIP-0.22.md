# Double Grip — 0.22

**Historical report:** `survived` counted fighters still on the field, excluding living escapees. See [0.23 corrections and AI trace](ENGAGEMENT-AI-0.23.md) before interpreting the shield-line draws as build balance.

One-handed melee weapons now receive **×1.25 regular and armour damage with an empty offhand**. No perk purchase is required. Both factions use the same rule. It is a separate multiplier applied to the two independent damage rolls before final damage rounding; it does not increase accuracy, penetration, AP or fatigue costs.

Puncture and fixed-condition Split Shield receive no bonus. Ordinary dagger Stab, paid mace/hammer attacks, Riposte, spear reactions and withdrawal reactions qualify when the weapon and offhand qualify. Two-handed weapons, bows, crossbows and throwing weapons do not. A shield in a carried slot does not block the bonus; equipping it does. A broken equipped shield no longer blocks Double Grip or Duelist, while the physical item remains available for repair. This latter eligibility correction is included in the paired comparison.

Duelist still adds 25 percentage points of penetration; its value has not changed. Its penetration and Double Grip damage combine normally. Existing temporary perk damage bonuses retain their additive grouping and are then multiplied by Double Grip. For example, 40 regular damage with +55% in temporary bonuses becomes 77.5 before the final HP calculation. Armour, headshots and mitigation can make actual HP loss differ from the displayed weapon range.

## Visible feedback

Weapon comparison damage includes Double Grip for the proposed loadout, on both the current and candidate sides. Falchion 40–55 becomes 50–69; arming sword 40–45 becomes 50–56. Preview notes explain the bonus and exclusions. The battle sidebar displays **DOUBLE GRIP · +25% DAMAGE** whenever active. It is an equipment status, not a perk-tree entry.

![Native equipment comparison](double-grip-comparison.png)

## Matched comparison

**1,296 fights, 54 career checkpoints, eight distinct generated mercenaries.** Six roles × three generated careers × levels 3/6/11 × three opponent types × two seeds × both sides × bonus off/on. The AI is identical on both sides of every pair. All 54 profiles match the prior release, and all 648 disabled-bonus rows exactly reproduce the shipped 0.21 current-AI results, including damage, hits, fatigue, ammunition, survival and outcome.

These are flat-field 3v3 encounters. The tested mercenary uses real generated stats/stars, saved growth and legal perk purchases, with explicitly granted test XP. Two supporting allies and opponents are authored controls. Equipment budgets and existing kits are unchanged. Draws reach the ordinary 30-round limit and remain in the results. No extra weapon archetypes or unusually strong recruits were substituted.

| Rules | Fights | Team wins | Losses | Draws | Tested fighter survives |
|---|---:|---:|---:|---:|---:|
| 0.21 baseline | 648 | 321 | 227 | 100 | 267 |
| 0.22 Double Grip | 648 | 280 | 267 | 101 | 243 |

### Level-11 sword duelist

Each row covers the same three falchion duelists, two seeds and two sides: 12 encounters. Wins describe the team; survival and damage describe the tested fighter.

| Opponent | Rules | Wins | Losses | Draws | Survives | Hits / attacks | HP damage | Armour damage |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Rushers | Baseline | 2 | 10 | 0 | 2 | 29 / 33 | 309 | 1282 |
| Rushers | Double Grip | 1 | 11 | 0 | 4 | 21 / 29 | 424 | 1009 |
| Shields | Baseline | 0 | 1 | 11 | 10 | 38 / 81 | 326 | 1687 |
| Shields | Double Grip | 0 | 0 | 12 | 10 | 45 / 86 | 717 | 2292 |
| Heavy | Baseline | 5 | 5 | 2 | 7 | 104 / 135 | 796 | 2724 |
| Heavy | Double Grip | 4 | 6 | 2 | 7 | 86 / 119 | 906 | 2737 |

The sword-duelist result is limited to these three generated falchion builds. It does not establish the strength of axe, mace or hammer duelists. Higher damage changes subsequent actions and RNG consumption, so observed hit rates across a whole fight can differ even though the accuracy formula is unchanged. Support fighters and enemies also receive the bonus whenever eligible. An improved matchup is not proof of universal balance.

### All roles

| Role | Baseline wins / 108 | Double Grip wins / 108 | Baseline draws | Double Grip draws |
|---|---:|---:|---:|---:|
| Shield | 58 | 49 | 14 | 16 |
| Duelist | 46 | 39 | 24 | 25 |
| Polearm | 55 | 45 | 17 | 17 |
| Bow | 48 | 44 | 11 | 11 |
| Crossbow | 54 | 46 | 15 | 13 |
| Hybrid | 60 | 57 | 19 | 19 |

## Saves and scope

Existing companies and recruits are retained. New encounters use battle schema 16. Saved ongoing battles at schema 15 or earlier retain their original damage and AI until completion; subsequent deployment uses the new rules. Campaign schema remains 20 because its structure and progression are unchanged. Three 0.21 campaigns are continued against a frozen copy of the delivered battle implementation, preserving commands, RNG, wounds, casualties and settlement exactly. Existing 0.20 and older continuation suites also pass.

No AI decisions, perk catalogue values, weapon stats, recruitment, progression, equipment costs or armour formulas were retuned. The only production source files changed are battle rules and the UI. This restores one missing baseline mechanic, not complete Battle Brothers parity.

Reproduce: `godot --headless --path . --script res://tests/build_balance.gd -- --double-grip`. Add `--role=duelist` for the duelist subset. The original command without `--double-grip` retains its historical AI-only comparison with Double Grip disabled.

[Full profiles/results](double-grip-results.json) · [Battle CSV](double-grip-battles.csv) · [Release validation](VALIDATION.md)

Design references: [Overhype introduction of Double Grip](https://www.indiedb.com/games/battle-brothers/news/progress-update-fatalities-new-weapons-and-more); [community mechanics reference: 25% and Puncture exclusion](https://battlebrothers.fandom.com/wiki/Double_Grip_%28Status_Effect%29). Our existing action modifiers and perk values are documented prototype rules, not a claim of exact vanilla parity.

![Native battle status](double-grip-battle.png)
