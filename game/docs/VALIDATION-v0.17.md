# Validation — talents and progression 0.17

Godot 4.4.1 on Linux. **12,748 checks, zero failures** across the following suites. Counts include repeated population assertions and overlapping seeded fights; they are correctness evidence, not a measure of overall balance.

| Suite | Checks | Scope |
|---|---:|---|
| `talent_growth.gd` | 7,569 | 3,600 generated people, weighted talents, starting ranges, saved offers, atomic choices, level 11, perk banking, malformed saves, earlier-pick catch-up and three real 0.16 battle continuations |
| `combat_baseline.gd` | 141 | Accuracy, shields, morale, fatigue and waiting; 12 paired current campaign fights and three frozen-0.15 continuations |
| `damage_balance.gd` | 371 | Damage arithmetic, physical component wear, earlier health/equipment conversion and deterministic battle/settlement continuation |
| `turns.gd` | 3,632 | 60 generated populations, queue/Wait, 24 actual first contracts with periodic saves and earned three-stat training, pre-initiative compatibility |
| `turns_combat.gd` | 204 | 23 weapon variants, 120 friendly-rank firing lanes, paid reactions/stagger and objective boundaries |
| `archer_rules.gd` | 396 | Historical-rule geometry/resources and three complete model battles |
| `equipment_economy.gd` | 304 | Ownership, markets, paid repairs/sales, recovered gear and settlement; 15 fresh fights plus a replay, with some historical fixtures |
| `talent_growth_ui.gd` | 26 | Declared XP and old-save fixtures; real selection/deselection/clear, Escape, F5/F9, atomic confirmation, auto-save and two-pick legacy catch-up |
| `turns_ui.gd` | 37 | Native profiles, equipment, mixed queue, Space Wait, F finish, saved waiting state, full battle and earned three-stat training |
| `weapon_compare_ui.gd` | 35 | Native comparison, paid purchase, equip, shield/ammo/carried previews, saves and complete battle |
| `damage_ui.gd` | 33 | Native exact odds, actual clicked hit, aggregate damage, full battle and immediate-final-hit save boundary |

## Growth and persistence

Across 3,600 new people, all have exactly three distinct talented attributes. The 10,800 ratings comprise 6,482 one-star, 3,297 two-star and 1,021 three-star talents. Inclusive starting ranges and deterministic generation are checked. Independent expected tables verify one-/two-/three-star gain bounds, including fixed two-star gains and the raised three-star maximum.

A declared XP fixture verifies all ten training levels, thirty increases, the level-11 cap, separate perk points, four learned perks, six banked points and deployment with all four. It is not a claim that an ordinary 30-day company reached level 11. Partial/duplicate/unknown picks, unearned training, altered future rolls and malformed identity/talent payloads are rejected without partially loading. Current and maximum health increase together while missing HP remains unchanged.

A previously trained 0.16 camp retains its actual stats, HP, XP, history, earlier talents and awards, then receives two catch-up choices per earlier one-stat level. Three ongoing delivered-0.16 fights continue with identical RNG, actions, casualties, items and settlement before adopting growth at camp. Pending conversion can be saved again. The four frozen 0.16 engines were compared with the delivered source; only dependency paths are changed to pin them to frozen copies. Earlier combat and health migrations continue to pass.

## Actual battles and pacing

The 24 new first-contract model journeys finish in **15 victories, 8 defeats and 1 draw**. Those survivors receive actual settlement XP; earned levels spend three distinct stats and save successfully. The first 12 seeds are also exercised by paired restoration suites, yielding 7 victories, 4 defeats and 1 draw; these are overlapping results, not additional independent balance trials.

A won clearing contract awards a surviving participant 40–55 XP under the existing survival/victory/kill/contract rewards. The first threshold is 40. Later thresholds are 100, 180, 280, 400, 550, 730, 940, 1180 and 1450. This preserves earlier ranks and gives meaningful early progression; endgame pacing remains unproven in this short scenario. The BB star/growth math does not imply identical campaign, enemy or economic balance.

## Native UI and release

Native tests use a 1440×900 Xvfb window, Mesa software rendering and isolated saves. The talent screen fixture verifies no mutation before confirmation, reversible selection, prevention of a fourth pick, exact saved gains, no reroll through closing/F5/F9, independent perk points, automatic save after confirmation and the older-save catch-up controls. Founder, recruit, selected-gain and catch-up screens were visually inspected.

A separate complete native battle produces an earned level and confirms three actual gains through the same UI. Weapon comparison and damage feedback journeys also complete real battles; final-hit saving settles once and reloads consistently. Space remains Wait and F finishes the activation. The accepted native graphics warning is unsupported VSync in the software renderer. One weapon-comparison launch exited before any test summary; it was discarded and rerun to a complete passing summary.

Source import passes. The final archive is CRC-checked, extracted fresh, imported and run through a full normal-scene smoke battle. No Godot cache, player save, temporary probe or downloaded third-party reference source is packaged. This is a Godot source project; standalone Windows/macOS exports were not produced.

Campaign schema 16; battle schema 12. See `TALENTS-0.17.md` for exact growth, authored starting ranges, XP pacing and compatibility. Earlier role-duel results remain in `VALIDATION-v0.16.md`; that experiment was not repeated because this update does not change its fixed-stat combat fixtures.

![Three choices before confirmation](talents-confirm-preview.png)

![Earlier picks retained during catch-up](talents-legacy-catchup.png)
