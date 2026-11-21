# Validation — individual turns and eight attributes 0.14

Godot 4.4.1 on Linux x86-64. Native input runs in a 1440×900 window with Mesa software rendering and an isolated save directory. This validates the source project, not standalone Windows/macOS exports or final human balance.

## Checks rerun

| Suite | Checks | Failures |
| --- | ---: | ---: |
| `tests/turns.gd` | 3,616 | 0 |
| `tests/turns_combat.gd` | 204 | 0 |
| `tests/archer_rules.gd` | 396 | 0 |
| `tests/equipment_economy.gd` | 280 | 0 |
| `tests/turns_ui.gd` | 37 | 0 |
| **Total** | **4,533** | **0** |

Only the above suites were rerun for this release. Earlier broader checks remain historical evidence in the versioned validation reports. New turn suites explicitly enable individual initiative; older regression fixtures intentionally retain their historical turn rules where appropriate.

## Stats and turn ownership

The model checks 60 seeded populations, eight attribute fields and aptitudes, actual equipped stamina capacity and initiative, and fixed automatic recovery. It exercises alternating faction ownership, Wait retaining AP/fatigue, one Wait per round, no duplicate recovery or AP, delayed ordering, end activation, round boundaries, stance expiry, dead queued/delayed units and personal exhaustion. Ordinary commands cannot spend another fighter's activation.

Separate melee/ranged skills and defences, defensive diminishing returns, morale states/resolve, stagger, fatigue affordability and equipment burden are covered. Switching cannot erase accumulated fatigue even when capacity falls below it. New save validation rejects malformed queues atomically, without altering the live game. Twelve paired map/objective continuations compare uninterrupted and restored play.

The combat suite executes all 23 weapon variants under individual turns. Actual mace stagger reduces the target's later AP; paid Riposte and Spear brace reactions occur outside the owner's activation without granting ordinary AP. Spear brace stops the chosen movement path while retaining the target's unspent AP. A further 120 ranged lanes cover five ranged weapons, both armies, both hex-row parities and all six directions; adjacent allies are not hit or treated as enemies. Capture objectives score once per completed round despite waiting. Twenty equal-initiative fixtures demonstrate deterministic saved order and first actors from both sides.

## Actual campaign fights and compatibility

Twenty-four fresh first-contract model journeys accept work, travel, deploy, fight and settle with new stats and individual initiative: **22 victories, 2 defeats, 0 draws**. These automated first-job outcomes are not a full campaign balance claim. Equipment, injuries, XP and saves are checked through settlement. Three old 0.13 active-fight continuations are compared against the frozen old engine. They retain their old turn mechanics and RNG; subsequent deployments use individual turns. The later-deployment compatibility fixture explicitly positions the company at its next contract location rather than claiming an ordinary-input travel journey.

The older archer regression suite adds 396 checks and three completed model battle runs. The equipment economy suite covers 15 fresh fights and one checkpoint replay, 14 wins, 96 actual recovered-item sales, 14 recovered weapon variants and two upgraded 0.12 runs. These historical-rules fixtures protect equipment ownership and existing combat compatibility.

## Native player journey

A fresh seed-1 company is operated through ordinary native UI input, with no injected resources, equipment, victories or battlefield positions. The journey inspects founder and recruit profiles; previews and confirms a starting-store billhook; checks armour/weapon stamina and initiative totals; and saves/reloads the company. It accepts Clear Blackwater Ford, travels there and deploys with an enemy acting first.

Only the active fighter receives AP. Clicking an inactive company member or a queue portrait inspects without granting control. Formation controls restrict orders to the active fighter. W delays an activation while keeping AP and fatigue; F5/F9 preserves the waited queue. Enter finishes one fighter. The weapon action panel shows actual personal costs. One complete native battle ends in victory, settlement reloads, and genuine earned XP buys the displayed Initiative increase. The developed company saves and reloads identically.

The final founder, recruit, weapon comparison, armour comparison, enemy-first queue, waiting queue and development screens were visually inspected. The header and all eight stat rows fit the tested window.

![Eight trainable attributes](initiative-founder.png)

![Mixed queue with an enemy acting first](initiative-enemy-first.png)

![Waiting and current activation](initiative-wait-queue.png)

![Equipment burden in the comparison](initiative-weapon-preview.png)

![Earned Initiative development](initiative-development.png)

## Save and package

Campaign schema 13, battle schema 10. Older ongoing battles finish under their old mechanics; the next deployment uses individual turns. Eight-stat migration preserves identities, equipment, condition, recruits and history without rerolls. New saves retain active actor, queued scores, normal/delayed turns, waiting/finished flags, AP and RNG.

The package is imported, ZIP CRC-checked, extracted into a clean directory, reimported and smoke-tested through a complete battle. Generated Godot caches and player saves are excluded. Script errors and failed assertions are not accepted; the software-display VSync warning is benign.

## Remaining scope

This is a BB-inspired stat/turn foundation. The existing layered armour/padding damage formula, 20% head-hit chance, 1.3 head-damage multiplier and authored abilities remain custom. Broader encounter/AI tuning, full armour/penetration conversion, direct camp attacks without contracts and additional damage-feedback work are not included in this release. Automated victories do not establish final human difficulty.
