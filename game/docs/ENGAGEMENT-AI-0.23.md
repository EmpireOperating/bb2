# Engagement AI — 0.23

## Defect and correction

The 0.22 sword-duelist/shield benchmark had 12 draws. Tracing all 12 revealed that the last attack occurred in rounds 3–15, followed by inactivity until the 30-round limit. Spear fighters repeatedly selected Brace and ended their activation while waiting for the opposing line to advance. Wounded melee fighters avoided every adjacent enemy position, so they stopped re-engaging. The old results did not isolate shield defence or duelist damage.

Spear AI now checks whether it can move into range and pay for a primary attack before choosing Brace. Route AP, route fatigue and attack costs must all fit. A spear holding the objective can still brace defensively. Planning uses no RNG and mutates no unit state. Existing stance actions still pay their full costs.

Wounded melee positioning now penalizes contact with multiple enemies rather than any contact. Melee Footwork is used to reduce an outnumbered engagement; low HP alone no longer causes a one-on-one escape/re-entry loop. Ranged escape, rescue Rotation and Indomitable remain available. Both faction controllers use these changes. This does not provide a full tactical search or guarantee safe decisions.

Damage formulas, Double Grip, accuracy, Phalanx, Shieldwall, perk values, equipment, generated stats and the 30-round limit are unchanged. No opponent was weakened to produce the result.

## Matched results

**1,296 fights: 648 prior-policy and 648 corrected-policy encounters.** Six roles, three generated careers per role, levels 3/6/11, three authored opponent types, two seeds and both faction controllers. All 54 career checkpoints are unchanged and represent eight distinct generated people. All 648 prior-policy rows reproduce the delivered 0.22 results exactly, after explicitly mapping the corrected survival field names.

These are flat-field 3v3 trials with two authored supporting allies. Test XP is explicitly granted through production progression; attribute gains and perk purchases are legal. Equipment spending limits and actual kits are unchanged. Results describe these fixtures, not universal build strength or campaign pacing.

| Policy | Fights | Team wins | Losses | Draws | Draws ending with ≥5 attack-free rounds |
|---|---:|---:|---:|---:|---:|
| Previous | 648 | 280 | 267 | 101 | 70 |
| Engagement | 648 | 373 | 249 | 26 | 0 |

### Level-11 falchion duelists

Each row covers the same three fully trained sword builds, two seeds and two sides. These are team outcomes, not one-on-one duels.

| Opponent | Policy | Wins | Losses | Draws | Alive | Escaped alive | Remain on field | HP damage | Armour damage |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Rushers | previous | 1 | 11 | 0 | 5 | 1 | 4 | 424 | 1009 |
| Rushers | engagement | 3 | 9 | 0 | 6 | 1 | 5 | 687 | 1493 |
| Shields | previous | 0 | 0 | 12 | 12 | 2 | 10 | 717 | 2292 |
| Shields | engagement | 6 | 5 | 1 | 7 | 3 | 4 | 1076 | 2861 |
| Heavy | previous | 4 | 6 | 2 | 10 | 3 | 7 | 906 | 2737 |
| Heavy | engagement | 7 | 2 | 3 | 9 | 2 | 7 | 1557 | 3802 |

The previous claim that only ten duelists survived the shield tests was incorrect: all twelve had positive HP, but two escaped. Historical `survived` meant still on the field. Current reports separate **alive**, **escaped**, **dead** and **remaining**. This is a reporting correction; no combat or escape rule changed.

| Duelist | Seed | Side | Result | Last attack by either team | End round |
|---|---:|---:|---|---:|---:|
| Helga | 71 | 0 | win | 16 | 16 |
| Helga | 71 | 1 | loss | 15 | 15 |
| Helga | 211 | 0 | win | 12 | 12 |
| Helga | 211 | 1 | loss | 11 | 11 |
| Berta | 71 | 0 | win | 18 | 18 |
| Berta | 71 | 1 | loss | 16 | 16 |
| Berta | 211 | 0 | win | 15 | 15 |
| Berta | 211 | 1 | loss | 16 | 16 |
| Ilse | 71 | 0 | win | 15 | 15 |
| Ilse | 71 | 1 | loss | 24 | 24 |
| Ilse | 211 | 0 | draw | 30 | 30 |
| Ilse | 211 | 1 | win | 23 | 23 |

### All roles

| Role | Previous wins / 108 | Corrected wins / 108 | Previous draws | Corrected draws |
|---|---:|---:|---:|---:|
| Shield | 49 | 69 | 16 | 2 |
| Duelist | 39 | 62 | 25 | 4 |
| Polearm | 45 | 60 | 17 | 4 |
| Bow | 44 | 44 | 11 | 10 |
| Crossbow | 46 | 72 | 13 | 3 |
| Hybrid | 57 | 66 | 19 | 3 |

The two controllers use different broader positioning policies; side is recorded for every encounter. More decisive combat can increase deaths or change win rates on either side. A 6/12 team win result in this small shield matchup is not proof of perfect balance.

## Native play and saves

Native timer tests verify a spear moving and then attacking, a wounded sword fighter re-engaging and attacking, paid escape/Rotation/Indomitable, and mid-activation F5/F9. A normal seed-2 campaign journey still completes a victory, spends battle-earned growth and a perk point, and reloads exactly. Native screenshots were inspected.

Current battle schema is 17; campaign schema remains 20. Existing in-progress battles preserve their original AI and damage rules. New encounters use the corrected policy, including in old companies. Three trained 0.22 continuations match a frozen copy of delivered battle code through commands, RNG, casualties and settlement; earlier readers remain unchanged.

Reproduce with `godot --headless --path . --script res://tests/build_balance.gd -- --engagement-ai`. Add `--role=duelist` for the subset. The historical AI-only and Double-Grip-only modes keep the new policy disabled, preserving those comparisons.

[Full profiles and outcomes](engagement-results.json) · [Battle CSV](engagement-battles.csv) · [Release validation](VALIDATION.md)

![Native spear advances and attacks](engagement-spear-attack.png)

![Native wounded duelist attacks](engagement-wounded-attack.png)
