# Validation — open builds 0.20

Godot 4.4.1, Linux. **59,712 checks; zero failures** across the final runs below. Counts include repeated assertions and overlapping fights; they are not independent balance evidence.

| Suite | Checks | Scope |
|---|---:|---|
| `background_generation.gd` | 29,903 | 7,200 people; deterministic mixed trees, background reachability, unchanged stats/stars, legal gear and starter safeguards; 32 actual-point routes; three exact 0.19 camp/battle continuations |
| `talent_growth.gd` | 7,569 | 3,600 generated people; 1–3 stars, saved choices, cap/banking, malformed saves, catch-up and three earlier continuations |
| `turns.gd` | 3,613 | 24 real first-contract simulations; 12 paired map/objective continuations and three old-save continuations |
| `perks.gd` | 134 | Existing melee arithmetic, tier gates, purchases, Gifted and persistence |
| `ranged_perks.gd` | 7,513 | 162 preserved pool shapes, legal careers, new generated pool validity, ranged combat, ammunition, merchant/refill rules and older encounters |
| `ranged_integration.gd` | 10,899 | Three veteran 0.18 continuations; all 162 actual 0.19 ranged pools restored into 0.20 and 486 level-eleven careers |
| `background_generation_ui.gd` | 26 | Actual recruit preview, full mixed pool, declared vacancy/funds, hiring exact stats/tree, unrestricted hammer equipment and native save/load |
| `perk_save_ui.gd` | 14 | Declared XP fixture; partial Gifted and ordinary growth, automatic saves, production/sandbox isolation |
| `turns_ui.gd` | 41 | Actual normal campaign battle, Space Wait/F finish, earned three-stat growth and perk purchase, automatic save and F9 |

## Generation and continuity

The new production algorithm samples four distinct weapon groups and two groups from each other category. All backgrounds use positive weights bounded at 1 and 2. The 7,200-person sample covers every individual group both present and absent in every background. A separate exhaustive enumeration of all 1,620 category combinations confirms distinct pools of 35–42 options. The native screenshot shows an actual poacher with Spear, Polearm, Crossbow and Throwing, without Bow. No role or pool is selected from the starting weapon.

Stats, identities, stars and all saved growth offers match corresponding 0.19 rolls. Thirty-two career fixtures grant XP through the production point provider and spend ten real points along the four available weapon masteries for one sample from each background. This establishes usable routes and persistence, not equal strength or natural level-eleven pacing.

Eight frozen 0.19 modules match the delivered release except pinned dependency paths. Earlier readers are unchanged. Battle, progression, perk progression and market source, plus weapon/armour/perk catalogues, are byte-identical to 0.19. Campaign schema is 19, battle schema remains 14, and personal pool schema 3 coexists with retained schemas 1/2. Three veteran 0.19 camps and ongoing encounters preserve soldiers, future offers, learned perks, gear, actions, RNG, casualties and settlement exactly. Only the campaign schema number differs. Three 0.18 continuations retain their prior migration boundary, and all 162 legacy ranged pools still support their three careers after loading into the current version.

## Native verification and limits

Native input runs at 1440×900 with Mesa software rendering and isolated saves. Prehire viewing, full tree layout, hire, equipment outside the mastery groups and F5/F9 pass. The hire test declares its vacancy/funding fixture; its candidate, tree, stars and growth are production-generated. Screenshot inspection found a long perk name spilling from a crowded row; labels now size to their actual rendered width, and the native journey was repeated and inspected.

A normal campaign journey completes a victorious battle with the new starting kits, spends genuinely earned stat growth and a perk point, then reloads exactly. Partial Gifted saves and production/sandbox isolation pass. Unsupported VSync is the only accepted graphics warning. The source import, ZIP CRC, clean extraction/import and full normal-start smoke battle pass. No player saves or Godot cache are packaged. This is a Godot source project; native Windows/macOS exports were not produced.

The 24 first-contract simulations finish 13 victories and 11 defeats, versus 12/12 with the previous starting kits. This small sample is not a balancing target or proof of equal build strength. No perk or combat numbers changed. Equipment prices, campaign progression pacing and AI limitations remain as documented. The AI does not plan Patient Hunter waiting or the active tactical perks. Prior full combat and balance reports are historical, not claimed as rerun.

[Generation design and distribution](BACKGROUNDS-0.20.md) · [Historical 0.19 report](VALIDATION-v0.19.md)

![Prehire mixed tree](background-recruit-tree.png)
