# Validation — damage and equipment 0.15

Godot 4.4.1 on Linux. **6,266 checks, zero failures** across the suites below. Counts overlap in covered mechanics; they are regression evidence, not a measure of final balance.

| Suite | Checks | Scope |
|---|---:|---|
| `damage_balance.gd` | 372 | Known arithmetic outcomes; actual strike integration; component wear; specials; migration; malformed saves; 12 paired campaign continuations and 12 paired map/objective fights |
| `turns.gd` | 3,608 | Population, eight stats, queue, Wait, invalid commands, 24 actual first contracts, map/objective continuations and older saves |
| `turns_combat.gd` | 204 | 23 weapon variants and paid actions/reactions under new damage; 120 friendly firing lanes; objectives and ties |
| `archer_rules.gd` | 396 | Historical-rules geometry/resource regression and three complete model fights |
| `equipment_economy.gd` | 288 | Ownership, markets, recovered gear, repairs, legacy transitions and actual fight settlement |
| `balance_roles.gd` | 1,284 | 640 actual AI duels with side-paired seeds and a shared 400-crown equipment ceiling |
| `turns_ui.gd` | 37 | Native input: profiles, gear preview/equip, mixed queue, Space Wait, F finish, save, complete victory and earned development |
| `weapon_compare_ui.gd` | 35 | Native input: exact new weapon values and deltas, paid purchase/equip, ammo/shields/carried slots, save and full battle |
| `armor_readability_ui.gd` | 24 | Native declared broken-gear fixture: current/max, now/max deltas, swaps, paid repair and save |
| `damage_ui.gd` | 18 | Native player-clicked attack, exact aggregate feedback, post-hit save and full battle |

## Damage and save evidence

The independently worked damage fixtures cover zero penetration, different penetration rates, intact armour, exact break, overflow, no armour, full bypass, separate damage rolls, head boundaries and integer rounding. A 40/40 hit at 20% penetration against 100 protection produces 40 armour loss and 2 HP loss; a head hit produces the same armour loss and 3 HP loss. Five different padding/mail splits produce identical results. Physical condition loss sums to the resolved armour loss. Stagger can apply to a landed hit with zero HP damage; puncture preserves armour. AI Shatter planning consumes no RNG and avoids armour a normal maul hit already destroys.

Three complete 0.14 ongoing fights are continued beside the frozen engine, including a second save/load while conversion is pending. Every final battle state, RNG, casualty, injury, loot item and settlement agrees. Return-to-camp conversion is deterministic and runs once. Camp-load fixtures preserve names, money, gear IDs, wounded health fractions and broken/half-conditioned equipment. Actual earned 0.14 health training is preserved. A separately declared pre-0.14 XP/talent fixture verifies its stronger ten-point health award is retained in full; that fixture is not described as an earned battle. Corrupt catalogue, pool and version flags are rejected atomically. The turns suite also protects three pre-initiative battle continuations.

The 24 fresh first-contract model journeys ended in **21 victories, 3 defeats, no draws**. The 12 paired campaign continuations in the damage suite use overlapping seeds and ended in 10 victories, 2 defeats; they are additional determinism checks, not 12 additional independent population samples. Equipment-economy fixtures report 15 fresh fights plus one checkpoint replay, 13 wins and 104 actual recovered-item sales across 14 variants. Some of that suite intentionally uses historical rules.

## Controlled role experiment

Equal personal stats: 60 HP, 65 melee skill, 60 ranged skill, 10 melee defence, 5 ranged defence, 105 stamina/initiative, 45 resolve; no traits or perks. The same 400-crown equipment ceiling is available to each build. Actual costs and unused reserves differ and are reported rather than silently equalized. Each cell below contains 40 duels: 20 seeds × both starting sides. Opponents are shielded axe users wearing either leather/linen/cap or heavy mail/gambeson/nasal helm. There are no supporting allies, terrain advantages, training or campaign spending decisions.

| Build | Gear cost | Body / head | Capacity / initiative | Wins vs light, adjacent / gap | Wins vs heavy, adjacent / gap |
|---|---:|---:|---:|---:|---:|
| archer | 264 | 77 / 70 | 82 / 82 | 1/40 · 3/40 | 0/40 · 0/40 |
| heavy | 387 | 100 / 110 | 72 / 72 | 6/40 · 2/40 | 10/40 · 2/40 |
| light | 219 | 77 / 70 | 85 / 85 | 12/40 · 6/40 | 2/40 · 0/40 |
| shield | 319 | 140 / 110 | 64 / 64 | 12/40 · 24/40 | 6/40 · 2/40 |

These outcomes do **not** show equal matchup strength. Lone archers struggled against shielded opponents; heavy weapons and light kits also need supported-squad playtesting. Measured tradeoffs are earlier turns/more stamina and reserves for light kit, more protection for shield kit, larger expensive hits for heavy weapons, and a benefit from firing space for archers. The experiment caught and prompted a correction to wasteful hammer-special selection. It is diagnostic evidence, not proof that all builds or the campaign economy are balanced. Full raw totals are in `balance-role-results.json`.

## Native UI and release

Native runs use a 1440×900 Xvfb window, Mesa software rendering and isolated save directories. Three native journeys complete actual contract battles in victory. The dedicated damage journey uses a real clicked primary attack after ordinary battle movement; its emitted totals equal the actual HP and combined armour changes, then survive F5/F9. AI finishes the rest of those battles. No resources, enemy positions, damage rolls or victories are injected in these three journeys. The separate armour-readability journey explicitly supplies damaged equipment to reproduce the reported comparison problem.

The battle feedback, battle record, armour current/max comparison, weapon comparison and version-labelled screens were visually inspected. Space waits and F ends the active turn. The harmless software-renderer VSync warning is the only native warning accepted. Source import is clean. The deliverable ZIP is CRC-checked, extracted into a new directory, imported and smoke-run through a complete battle with the normal scene. Godot caches, player saves and external research source files are excluded. This remains a source project; Windows/macOS standalone exports were not produced.

Campaign schema 14, battle schema 11. Whole-point armour rounding and authored specials are documented in COMBAT-BALANCE-0.15.md. Growth, fatigue events, next-round Wait penalties, morale and perk-tree balance remain subsequent work. No commercial Battle Brothers executable comparison or claim of full numerical parity is made.

![Actual clicked hit: total armour and HP loss](damage-total-feedback.png)

![Current/max armour and separate usable/capacity changes](armor-upgrade-current-max.png)

![Rebalanced weapon comparison](weapons-comparison-main.png)
