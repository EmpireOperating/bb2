# Validation — axe and mace perks 0.24

42,304 assertion checks; zero failures in final recorded runs. Counts include repeated assertions and are distinct from encounters. Godot 4.4.1 on Linux.

| Suite | Checks | Scope |
|---|---:|---|
| `axe_mace` | 70 | Both sides/offhands, exact damage and fatigue, nonstacking/immune stagger, Wait/expiry, AI decisions, three delivered 0.23 continuations and current saves |
| `perks` | 134 | Shared perk costs, progression and saves |
| `ranged_perks` | 7,513 | Ranged math, careers, ammo and historical saves |
| `background_generation` | 29,935 | 7,200 people, all backgrounds/groups, independent stats/stars, 32 legal earned-point routes and old saves |
| `double_grip` | 429 | Both controllers, all weapons, damage exceptions and exact 0.21 continuations |
| `perk_timing` | 16 | Existing expiry and reaction timing |
| `axe_mace_trials` | 468 | 36 career checkpoints, 432 paired 3v3 fights with activity and effect counters |
| `turns` | 3,616 | 24 normal campaign fights (17 wins / 7 losses / no draws), map/objective and old-save continuations |
| `axe_mace_ui` | 32 | Native generated trees, actual purchases, paid axe/mace attacks, target preview and F5/F9 |
| `background_generation_ui` | 26 | Native prehire preview, hire, unrestricted weapon swap and exact save |
| `weapon_compare_ui` | 39 | Native weapon comparisons, paid purchase/equip, hands/ammo, save and complete battle victory |
| `historical_pilot` | 26 | 24 historical duelists/AI fights reproduce every saved 0.23 outcome, activity and damage field |

Native screenshots were visually inspected at 1440×900 using Mesa software rendering. The known unsupported-VSync warning is nonfatal. Combat/XP/gear fixtures are explicitly labelled; they do not claim natural campaign progression. A separate native weapon-comparison journey completes an ordinary battle.

Only `battle.gd`, `perks.gd`, `main.gd` and the perk catalogue change production behavior. `axe_mace_trials.gd` is developer-only. Existing weapon damage/accuracy/AP, equipment, stats and growth tables are unchanged. Saved older trees are not rerolled. Historical comparison scripts now use their stored original careers and disable the new battle policy, keeping the old baseline reproducible.

The three archived 0.23 campaigns were generated with delivered source, not reconstructed using the new generator. JSON numeric values are normalized by the same production reader before exact comparisons. Native tests account for F9 closing transient UI panels.

The controlled sample is six people and one battle seed with both controllers; it establishes functioning effects and recorded activity, not final weapon balance. See [the source audit and results](AXE-MACE-0.24.md).

Archive CRC, clean extraction/import and normal-start smoke checks pass. Source-only Godot project; no native executable exports are included. Godot cache, player saves and temporary probes/reports are excluded. Older validation reports are historical and are not included in the fresh check totals.
