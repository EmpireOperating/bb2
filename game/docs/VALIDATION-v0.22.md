# Validation — Double Grip 0.22

**13,242 checks; zero failures in the final recorded runs.** Godot 4.4.1 on Linux. Counts include repeated assertions; battles are reported separately.

| Suite | Checks | Scope |
|---|---:|---|
| `double_grip` | 429 | Actual regular/armour damage for all 25 weapons and both factions; intact/broken/carried shields, exceptions, paid switching, reactions, exact 0.21 continuation and current saves |
| `perks` | 134 | Existing perk arithmetic, costs, growth and saves with the added baseline damage multiplier |
| `perk_timing` | 16 | Sequences, expiry, reactions and active-perk timing |
| `ranged_perks` | 7,513 | Ranged eligibility, careers, perk pools, damage, ammo and legacy preservation |
| `tactical_ai` | 43 | Paid AI decisions and exact 0.20 encounter/settlement continuation |
| `turns` | 3,606 | 24 normal first contracts (13 wins, 11 defeats, no draws); turns, objectives and old saves |
| `double_grip_ui` | 17 | Generated veteran, visible boosted damage, native shield equip/remove, actual deployment, F5/F9 |
| `weapon_compare_ui` | 39 | 39 checks: candidate stats, purchase, equipment, carried references, saves and one full battle ending in defeat |
| `turns_ui` | 41 | Native controls, normal battle, battle-earned growth/perk purchase and save/load |
| `build_balance` | 1,404 | 54 unchanged careers, 1,296 paired fights; every disabled-bonus result matches delivered 0.21 data |

## Findings and boundaries

The [matched comparison](DOUBLE-GRIP-0.22.md) separates the damage-rule change from AI changes and retains draws. All 648 disabled-bonus results and 54 profiles exactly match the prior published data. The sample remains small in distinct people, uses flat 3v3 arenas, and tests sword duelists only. It does not prove equal build strength or late-game campaign pacing.

The native weapon comparison test initially assumed the first carried slot was empty; current random founders can start with a backup. The fixture now clears that slot through the normal UI before testing an empty-slot comparison. No assertion was removed. Its complete battle ends in defeat and still verifies settlement/save correctness. A separate seed-2 native journey wins, spends actual earned stat growth and a perk point, and reloads exactly. The Double Grip veteran uses declared test XP through production progression, not an assertion of naturally reaching level 11 in this slice.

Native screenshots were visually inspected at 1440×900. Mesa software rendering emits only the established unsupported-VSync warning. No Windows/macOS executable is included or tested.

## Preservation and packaging

Only production `battle.gd` and `main.gd` differ from 0.21. All catalogues, other production modules and historical readers are unchanged. A test-only frozen 0.21 battle file matches the delivered source byte for byte and is never loaded during normal play. Campaign schema 20 and battle schema 16 preserve old ongoing encounters under their previous rules. Three 0.21 and three 0.20 continuations preserve exact commands, RNG, casualties and settlement.

Source import, archive CRC, clean extraction/import and normal-start smoke checks pass. The archive excludes Godot cache, player saves and partial comparison reports. Earlier reports are historical and are not counted as rerun.
