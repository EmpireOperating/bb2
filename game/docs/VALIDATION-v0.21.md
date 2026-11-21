# Validation — build comparison and AI 0.21

**12,767 checks; zero failures** in the recorded passing runs. Godot 4.4.1 on Linux. Counts include repeated assertions; battle outcomes are reported separately.

| Suite | Checks | Scope |
|---|---:|---|
| `tactical_ai` | 43 | Both sides: legal paid active perks, no planning RNG, aimed Wait, sword decisions, one/two-hex reach, backup roles; three exact 0.20 continuations |
| `turns` | 3,601 | Generated company validation, 24 actual first contracts, mixed initiative, objectives and older continuations |
| `perks` | 134 | Perk arithmetic, costs, tier gates, Gifted, purchases and saves |
| `perk_timing` | 16 | Wait, expiry, reactions, switching and active-perk timing |
| `ranged_perks` | 7,513 | 57-perk integration, 162 retained pool shapes, ranged effects/ammo, careers and legacy continuation |
| `turns_ui` | 41 | Native gear/queue/Space/F, a complete normal battle, genuinely earned growth and perk purchase, automatic save/F9 |
| `build_balance_ui` | 15 | Generated level-six training and budgeted gear; declared enemy active-perk scenarios through native timer; exact mid-activation saves |
| `balance_shield` | 234 | Nine generated careers; 216 paired-policy battles; saved growth, legal purchases and budget validation |
| `balance_duelist` | 234 | Nine generated careers; 216 paired-policy battles; saved growth, legal purchases and budget validation |
| `balance_polearm` | 234 | Nine generated careers; 216 paired-policy battles; saved growth, legal purchases and budget validation |
| `balance_bow` | 234 | Nine generated careers; 216 paired-policy battles; saved growth, legal purchases and budget validation |
| `balance_crossbow` | 234 | Nine generated careers; 216 paired-policy battles; saved growth, legal purchases and budget validation |
| `balance_hybrid` | 234 | Nine generated careers; 216 paired-policy battles; saved growth, legal purchases and budget validation |

## Findings and boundaries

The controlled sample contains 54 careers from eight distinct generated people, six roles and three level checkpoints. All 1,296 encounters finish under the normal 30-round limit; draws are retained, not discarded. The full [comparison](BUILD-BALANCE-0.21.md) reports actual spending, unused budget, damage, survival, fatigue, recoveries and ammunition. Two authored support allies and authored opponents are controls, not claimed as naturally trained characters. XP/gear fixtures are explicit.

Reach and sword-decision defects were fixed before the final comparison. The early hybrid kit was adjusted to fit the 400-crown ceiling. Developing duelists retain a shield until Duelist and medium armour until Nimble; this affects the test build policy, not normal automatic equipment. No damage coefficients, perk values, generation, progression or prices were changed. The remaining duelist weakness is reported rather than concealed with a numerical boost. Ordinary raiders were not assigned a new perk roster.

The 24 normal first-contract simulations finish **11 victories, 13 defeats, no draws**. The prior native seed-1 journey now loses after the reach correction and therefore cannot verify an earned promotion. Its failure is retained in the development history; the successful progression journey uses seed 2, selected by a model replay of the same equipment/Wait/F actions. No assertion was removed: the native journey still must win, train earned attributes, purchase a perk and reload exactly. This is path coverage, not a claim that the opening is easy or that all seeds win.

Native tests use 1440×900 Mesa software rendering and isolated saves. Actual input inspects the generated build and saves it. Enemy fixture actions use the normal game timer and pay normal costs. Rotation, Footwork and Indomitable and their saved state pass. Screenshots were inspected. Unsupported VSync is the accepted graphics warning.

## Preservation and release

Eight frozen 0.20 modules match delivered source except dependency pins; all earlier readers remain unchanged. People, progression, personal perks, perk progression, arsenal, market, armour and damage modules are byte-identical to 0.20. Perk/weapon/equipment/background catalogues are unchanged. Three previous veteran encounters retain exact old commands, RNG, casualties, inventory, learned perks and settlement. Old ongoing fights keep battle schema 14 and old AI; the next deployment uses schema 15. Current campaign schema is 20.

The source import, ZIP CRC, clean extraction/import and normal-start smoke battle pass. The package contains no Godot cache, player saves, temporary probe or partial trial reports. This is a source project, not a Windows/macOS executable. Prior reports are historical and are not counted as freshly rerun.

[Controlled results](BUILD-BALANCE-0.21.md) · [Historical 0.20 validation](VALIDATION-v0.20.md)
