# Validation — hammer/dagger and overworld integration 0.26

43,837 assertion checks, zero failures in final recorded runs. Counts include repeated assertions, not unique encounters. Godot 4.4.1 on Linux.

The release starts from the actually delivered free-roam 0.25 project. Its campaign, overworld and playability code is preserved byte-for-byte. Hammer/dagger combat, personal groups and UI previews are added on top. Campaign schema remains 21, overworld schema 1, new battle schema 19 and new personal pool version 5.

| Suite | Checks | Evidence |
|---|---:|---|
| `hammer_dagger` | 91 | Both controllers/offhands, exact costs/damage, reactions, reset/expiry/Wait, AI two-AP actions, preview purity, 0.24 continuations and live saves |
| `hammer_dagger_trials` | 468 | 36 career checkpoints, 432 paired 3v3 fights; actual damage, effect use, survival and activity |
| `overworld` | 1,339 | All landmark routes, off-road navigation, terrain/crossings, physical town access, clock, pursuit/evasion, encounters, escorts, camps and corrupt saves |
| `overworld_perk_compat` | 30 | Three actually delivered 0.25 companies: all original fields in camp/route/contact/battle/aftermath, exact route and real combat continuations |
| `axe_mace` | 70 | Existing axe/mace arithmetic, timing, AI and 0.23 continuations |
| `perks` | 134 | Shared costs, progression and saves |
| `background_generation` | 29,967 | 7,200 people, all backgrounds/groups, independent stats/stars, 32 earned-point routes and historical saves |
| `ranged_perks` | 7,513 | Ranged math, careers, ammunition and historical saves |
| `double_grip` | 429 | Both controllers, weapon exceptions and exact 0.21 continuations |
| `perk_timing` | 16 | Existing expiry and reaction timing |
| `turns` | 3,607 | 24 ordinary campaign fights: 21 wins, 3 losses, no draws; 12 paired map/objective and three old-save continuations |
| `tactical_ai` | 43 | Paid decisions, planning purity, original 0.20 continuations and current battle saves |
| `engagement_ai` | 44 | Approach/re-engagement, bracing, escape, prior stall and saved fights |
| `hammer_dagger_ui` | 37 | Native purchases, real travel, paid Shatter/Puncture, target costs/status, hammer comparison and F5/F9 with a two-AP follow-up |
| `background_generation_ui` | 26 | Native prehire tree preview, hire, unrestricted equipment swap and exact saves |
| `overworld_ui` | 23 | Native free-route travel, mid-route save/load, scout discovery/contact, battle, homecoming, resupply and save |

## Evidence and limits

The 432-fight records and 36 career profiles exactly match the pre-merge hammer/dagger run. There are five distinct generated people across six family entries, one fight seed, both controllers and authored matching-level support/opponents. All saved model growth choices are trained. The ablation removes six perks without reallocating points; it is not an equal-point optimized-build comparison or proof of final balance.

Native perk tests use generated identities, stats and trees, with declared XP, equipment and adjacent-combat fixtures. They buy real perks and pay actual action costs. The overworld journey uses normal movement/contact/combat rules and legal AI commands, without forcing victory; seed 7391 returns to Ashwick on day 3 with two survivors. The test drives world time explicitly so rendering speed cannot change the checkpoint; ordinary processing runs during battle. The F5/F9 checkpoint is tested before reaching an autosaving travel event.

Three 0.24 and three 0.25 compatibility fixtures were captured with their respective delivered source before applying these changes. The 0.24 comparisons exclude only the established campaign-version/spatial additions. The 0.25 comparisons include every field and compare full-precision serialized values: JSON float64 decimals must not be mistaken for different float32 Vector2 coordinates. Battle commands, RNG, damage, casualties and settlement are checked against actual prior outcomes.

Native screenshots were inspected at 1440×900 with Mesa software rendering. The known unsupported-VSync warning is nonfatal. No game script errors occur in final passing runs. Failed test-harness timing/representation attempts are not counted as passes.

Only `battle.gd`, `perks.gd`, `main.gd` and the perk catalogue change production behavior relative to delivered 0.25. `hammer_dagger_trials.gd` is developer-only. Base equipment, stats, growth and overworld behavior are retained. Existing personal trees are not rerolled.

The older 1,296-fight build matrix was not rerun. Historical reports retain their original scope and are excluded from these fresh totals. The 0.25 report is preserved in [VALIDATION-v0.25.md](VALIDATION-v0.25.md); [0.24 validation](VALIDATION-v0.24.md) remains available. The obsolete archival company/world test limitations described in 0.25 remain; they are not silently counted as passing here.

Archive CRC, clean extraction/import and normal-start smoke checks pass. This is a Godot source project, not a native executable export. Runtime caches, player saves and temporary probes are excluded.
