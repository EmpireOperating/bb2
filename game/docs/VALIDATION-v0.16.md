# Validation — combat baseline 0.16

Godot 4.4.1 on Linux. **6,508 checks, zero failures** in the suites below. Counts overlap in mechanics and seeded battles; they are regression evidence, not a measure of overall balance.

| Suite | Checks | Scope |
|---|---:|---|
| `combat_baseline.gd` | 141 | Worked accuracy, shields, morale, fatigue, Wait and Recover cases; 3 frozen-0.15 continuations/settlements; 12 paired new company fights; all map/objective combinations; malformed saves |
| `damage_balance.gd` | 375 | Damage arithmetic and component wear, independent rolls, older health/equipment conversion, 3 frozen-0.14 continuations, paired campaign and map/objective continuations |
| `turns.gd` | 3,619 | 60 generated companies, eight stats, queue/Wait and historical mechanics, 24 actual first contracts with periodic ongoing-fight restores, pre-initiative saves |
| `turns_combat.gd` | 204 | Current baseline: all 23 variants pay primary costs; 120 friendly-rank firing lanes; reactions/stagger, objectives and deterministic ties |
| `archer_rules.gd` | 396 | Historical-rule geometry/resource checks and three complete model fights |
| `equipment_economy.gd` | 344 | Physical ownership, markets, repairs, actual recovered gear, paid sales and settlement/migration |
| `balance_roles.gd` | 1,284 | 640 side-paired AI duels under the current combat rules with equal personal stats and a 400-crown ceiling |
| `turns_ui.gd` | 37 | Native profile/equipment input, mixed queue, Space Wait, F finish, mid-wait save/load, complete battle and earned training |
| `weapon_compare_ui.gd` | 35 | Native current weapon values/deltas, purchase/equip, ammo, shields, carried references, save/load and complete battle |
| `armor_readability_ui.gd` | 24 | Native declared damaged-equipment fixture: current/max preview, confirmation, paid repair and persistence |
| `damage_ui.gd` | 49 | Native exact odds, player-clicked hit, aggregate feedback, post-hit save, actual full battle and immediate-final-hit save boundary |

## Formula and persistence evidence

Worked fixtures verify neutral skill-minus-defence, sword/spear bonuses, morale acting on the combined property, heater melee/ranged differences, active-only wall support capped at four, defence above 50 and half-point thresholds, melee-only surrounding, ranged holders/height exclusions, downhill versus uphill, separate bow/bolt distance equations, exact paid costs, and the normal 5–95 limits. Integer rolls use the same probability shown by the preview. The aimed-shot fixture confirms its regular-damage bonus does not also multiply the independent armour roll.

Actual strike fixtures verify +2 incoming fatigue on misses, +5 on armour-only hits, fatigue caps, the shield-impact interval, one-condition wear and immediate removal of broken-shield defence. Shieldwall is paid and survives an attack. Recover requires its perk and all nine AP, halving accumulated fatigue. Wait preserves its current activation and penalizes the next score, including negative initiative. Automatic recovery reserves fifteen capacity even with a damaged lung. Resolve fixtures verify adjacency, morale multiplication, its 95 ceiling/no 5 floor, one-state loss, and unengaged rally.

Three delivered-0.15 campaigns are loaded during real ongoing fights, saved/loaded again while adoption is pending, and continued beside the frozen engine. RNG, commands, casualties, injuries, rewards, equipment and settlement agree exactly. The frozen source files were also compared to the delivered 0.15 archive. Three older 0.14 damage migrations and three pre-initiative continuations remain protected. Camp adoption retains company/item identity and runs once. Missing/mismatched rule flags, invalid fleeing counters and out-of-range scores are rejected atomically.

The 24 fresh first-contract model journeys ended in **18 victories and 6 defeats, no draws**. The baseline suite’s first 12 seeds ended in 10 victories and 2 defeats; those seeds overlap the larger sample. Paired restored copies are determinism checks, not extra independent outcomes. Equipment/economy tests report 15 fresh fights plus one checkpoint replay, 12 wins and 160 actual recovered-item sales across 14 weapon variants; some fixtures deliberately exercise historical rules.

The campaign validator rejects a battle marked completed while its campaign is still unsettled. The native saver now processes aftermath before writing if F5 arrives at that final-hit boundary. A real battle is completed through ordinary AI actions, then saved before the next presentation frame: settlement occurs once, a repeated save gives no duplicate rewards, and reload reproduces the exact result. No victory or combat statistics are injected in that journey.

## Controlled build experiment

Four fixed kits use the same 400-crown ceiling and equal personal stats: 60 HP, 65 melee skill, 60 ranged skill, 10 melee defence, 5 ranged defence, 105 stamina/initiative, 45 Resolve, no traits or perks. Opponents are shielded axe users in light or heavy kit. Each matchup has 20 seeds × both starting sides = 40 duels. Real kit costs/reserves differ. No supporting allies, campaign purchases, growth or positional terrain advantage are simulated.

| Build | Cost / reserve | Body / head | Capacity / fresh initiative | Wins vs light: adjacent / gap | Wins vs heavy: adjacent / gap |
|---|---:|---:|---:|---:|---:|
| archer | 264 / 136 | 77 / 70 | 82 / 82 | 0/40 · 2/40 | 0/40 · 0/40 |
| heavy | 387 / 13 | 100 / 110 | 72 / 72 | 20/40 · 6/40 | 18/40 · 13/40 |
| light | 219 / 181 | 77 / 70 | 85 / 85 | 7/40 · 2/40 | 0/40 · 1/40 |
| shield | 319 / 81 | 140 / 110 | 64 / 64 | 29/40 · 34/40 | 15/40 · 12/40 |

These results do **not** establish equal build strength. Lone archers and unshielded light builds struggle against the tested shielded opponents; supported-squad play and further item/AI tuning are needed. Raw totals are in `balance-role-results.json`. Changing the accuracy foundation is not a claim that every authored weapon, recruit or enemy now has commercial BB balance.

## Native UI and archive

Native tests use a 1440×900 Xvfb window, Mesa software rendering and isolated saves. The three full native battle journeys finish in two victories and one defeat. The separate armour journey explicitly supplies damaged gear to reproduce the current/max comparison issue. Actual hit odds and weapon comparison screens were visually inspected. UI feedback distinguishes the clicked target’s hit from an enemy riposte, then checks emitted totals against actual HP/armour changes. Space waits and F finishes the active fighter. The only accepted native warning is the software renderer’s unsupported VSync setting.

Source import passes. The ZIP is CRC-checked, extracted to a clean directory, imported and run through a complete normal-scene smoke battle. No Godot caches, player saves, probe/debug scripts or downloaded third-party reference sources are packaged. This is a Godot source project; Windows/macOS standalone executables were not produced.

Campaign schema 15; battle schema 12. See `COMBAT-BASELINE-0.16.md` for equations, pinned references and explicit remaining differences. Historical tests are identified above. There is no commercial-executable comparison or claim of complete numerical parity.

![Exact live accuracy calculation](combat-baseline-odds.png)

![Current primary weapon accuracy and costs](weapons-comparison-main.png)
