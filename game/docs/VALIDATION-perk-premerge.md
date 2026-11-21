# Pre-merge hammer/dagger verification checkpoint

This was a local checkpoint, not a published 0.25 release. Current integrated results are in [VALIDATION.md](VALIDATION.md).

42,364 assertion checks; zero failures in final recorded runs. Repeated assertions are included; this count is distinct from encounters. Godot 4.4.1 on Linux.

| Suite | Checks | Scope |
|---|---:|---|
| `hammer_dagger` | 91 | Both controllers/offhands, exact damage/costs, reactions, reset/expiry/Wait, AI two-AP actions, preview purity, three delivered 0.24 continuations and current saves |
| `hammer_dagger_trials` | 468 | 36 career checkpoints, 432 paired 3v3 fights; actual attacks/damage, effect counters, survival and activity |
| `axe_mace` | 70 | Existing axe/mace arithmetic, timing, AI and delivered 0.23 continuations |
| `perks` | 134 | Shared costs, progression and saves |
| `background_generation` | 29,967 | 7,200 people, all backgrounds/groups, independent stats/stars, 32 earned-point routes and historical saves |
| `ranged_perks` | 7,513 | Ranged math, careers, ammo and historical saves |
| `double_grip` | 429 | Both controllers, weapon exceptions and exact 0.21 continuations |
| `perk_timing` | 16 | Existing expiry and reaction timing |
| `turns` | 3,613 | 24 ordinary campaign fights: 21 wins / 3 losses / no draws; 12 paired map/objective and three old-save continuations |
| `background_generation_ui` | 26 | Native prehire preview, hire, unrestricted weapon swap and exact saves |
| `hammer_dagger_ui` | 37 | Native tree purchases, paid Shatter/Puncture, target costs/status, hammer comparison, exact F5/F9 and paid two-AP follow-up after reload |

Native screenshots were inspected at 1440×900 under Mesa software rendering. The unsupported-VSync warning is nonfatal. Generated identities, stats and trees are retained. Native XP, gear and adjacent combat positions are declared fixtures; the UI journey buys real perks and executes paid actions but does not represent a fully trained level-11 career. Model trials train all required saved stat choices.

Production changes are limited to `battle.gd`, `perks.gd`, `main.gd` and the perk catalogue. `hammer_dagger_trials.gd` is developer-only. Base equipment, stats and growth tables are unchanged. All saved personal trees remain exact.

The three 0.24 compatibility fixtures were captured using delivered source before these changes, not reconstructed with the new generator. Current chain/debuff state survives native F5/F9. Preview checks verify that reading costs and notes does not mutate state or RNG.

The 432-fight sample has five distinct people, one fight seed, both controllers, matching-level opponents and declared support. It verifies implementation and activity; it does not establish final weapon balance. See [source audit and trial results](HAMMER-DAGGER-0.26.md).

The older 1,296-fight build matrix was not rerun for this release. Historical reports retain their original scope and are excluded from these fresh totals. The historical benchmark disables this new policy as well as the 0.24 policy.

Archive CRC, clean extraction/import and normal-start smoke checks pass. This is a Godot source project; no native executable export is included. Runtime caches, player saves and temporary probes are excluded.
