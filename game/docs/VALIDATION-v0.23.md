# Validation — engagement AI 0.23

**13,261 checks; zero failures** in final recorded runs. Godot 4.4.1 on Linux. Assertion counts include repeated checks and are distinct from encounter counts.

| Suite | Checks | Scope |
|---|---:|---|
| `engagement_ai` | 44 | Both controllers, legal approach costs, defensive brace, outnumbered escape, original stalemate, exact 0.22 and current save continuations |
| `tactical_ai` | 43 | Paid active perks and exact 0.20 continuation |
| `double_grip` | 429 | Damage, equipment eligibility, exceptions and exact 0.21 continuation |
| `perks` | 134 | Perk arithmetic, costs, growth and saves |
| `perk_timing` | 16 | Expiry, sequences and reactions |
| `ranged_perks` | 7,513 | Ranged careers, effects, ammunition and legacy preservation |
| `turns` | 3,609 | 24 actual campaign fights: 19 victories, 5 defeats, no draws; turns, objectives and old saves |
| `engagement_ai_ui` | 13 | Native enemy timer: spear approach/attack, wounded re-engagement and saves |
| `build_balance_ui` | 15 | Native trained career, paid enemy Rotation/Footwork/Indomitable and saves |
| `turns_ui` | 41 | Native input, full campaign victory, earned growth/perk purchase and save/load |
| `build_balance` | 1,404 | 54 unchanged career checkpoints, 1,296 paired fights; all 648 baseline results reproduce 0.22 |

## Findings and limits

See [matched results](ENGAGEMENT-AI-0.23.md). The fixed benchmark contains eight distinct generated people and authored 3v3 opposition/support. It demonstrates removal of the reported bracing/re-engagement deadlock; it does not prove optimal AI or equal builds. Remaining draws and attack-free tails are retained and reported. Survival now includes escaped living fighters, separately from remaining on the field.

Native tests use isolated saves and 1440×900 Mesa software rendering. The established unsupported-VSync warning is the only accepted graphics warning. Declared enemy fixtures check the production timer; ordinary campaign enemy perk rosters are unchanged. A separate real campaign journey wins and spends actual earned progression.

Only production battle rules and version labels changed from 0.22. All other production modules, catalogues and existing historical readers are byte-identical. The frozen test-only 0.22 battle matches delivered code and is never loaded by normal play. Existing encounters keep their saved policy; next deployment adopts schema 17.

Archive CRC, clean extraction/import and normal-start smoke checks pass. Source-only Godot project; no Windows/macOS export is included or tested. Godot cache, player saves and partial trial reports are excluded. Historical reports are retained and are not counted as freshly rerun.
