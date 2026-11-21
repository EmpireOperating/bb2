# Validation — personal perks 0.18

Godot 4.4.1 on Linux. **21,010 checks, zero failures** across the final runs below. Counts include repeated population assertions and overlapping battles. They demonstrate tested correctness, not overall balance or equal build strength.

| Suite | Checks | Scope |
|---|---:|---|
| `perks.gd` | 134 | 45-perk catalogue, all 54 pools, purchase/tier gates, arithmetic, actions, persistence and earlier migration |
| `perk_timing.gd` | 16 | Reaction, Wait, expiry, pressure, pull immunity and switch timing |
| `perk_lab.gd` | 11 | All nine authored demo presets persist through the real progression validator |
| `perk_progression.gd` | 226 | Actual level-derived point provider, forged counters, Gifted/Colossus, ten-pick cap and three complete delivered-0.17 battle continuations |
| `generated_perk_builds.gd` | 5,671 | 54 generated founders, three complete routes each using saved growth and earned point APIs; 972 matched three-versus-three fixture battles |
| `perk_trials.gd` | 2,259 | Nine authored ten-point builds, five situations, twelve seeds and both sides: 1,080 matched fixture battles |
| `talent_growth.gd` | 7,569 | 3,600 generated people, stars, saved growth, atomic choices, level 11, malformed saves, earlier-pick catch-up and three complete 0.16 battle continuations |
| `combat_baseline.gd` | 141 | Skill/defence, shields, morale, fatigue, waiting, 12 paired actual campaign fights and older continuations |
| `damage_balance.gd` | 372 | Pooled damage, component wear, earlier health/equipment migration and deterministic battle/settlement continuation |
| `turns.gd` | 3,631 | Generated populations, queues/Wait, 24 actual first contracts, periodic saves and earned three-stat training |
| `turns_combat.gd` | 204 | 23 weapon variants, 120 friendly firing lanes, paid reactions/stagger and objective boundaries |
| `archer_rules.gd` | 396 | Historical-rule geometry/resources and three complete model battles |
| `equipment_economy.gd` | 268 | Ownership, markets, paid repair/sales, recovered gear and settlement; 15 fresh fights plus a replay, some historical fixtures |
| `perks_ui.gd` | 18 | Declared demo fixtures: tree, group highlighting, prehire/hire, Gifted, Indomitable and board-targeted Rotation |
| `turns_ui.gd` | 41 | Normal campaign input, profile/gear, mixed queue, Space Wait, F finish, full victorious fight, earned three-stat training and an actual earned Colossus purchase with auto-save/F9 |
| `perk_save_ui.gd` | 14 | Declared 100-XP fixture with generated stats: partial Gifted auto-save, resume, ordinary growth, production/demo save isolation |
| `weapon_compare_ui.gd` | 39 | Actual previews, purchase/equip, carried items, saves and a full victorious battle; declared perk display fixtures for penetration, shield suppression and Riposte availability |

## Integration and persistence

The supplied perk catalogue is unchanged. Production uses 0.17 levels, thresholds, star generation and saved three-stat offers. Earned perk points derive from actual level, with ten at level eleven. Forged cumulative point fields are ignored as a source and rejected by save validation. Gifted and normal stat choices do not award or consume each other's points. Health growth with Colossus applies the multiplier once and retains missing HP.

Three ongoing delivered-0.17 encounters continue with the same actions, RNG, casualties, equipment and settlement before conversion at camp. Melee placeholder picks are refunded once into the existing earned budget; XP, talent ratings, base stats, past training and future growth rolls remain. All four frozen 0.17 readers match delivered source except pinned dependency paths; every earlier frozen reader is byte-identical to 0.17. Earlier health/combat/growth migration tests also pass.

Current campaign schema 17; battle schema 13. Trigger state and pending conversion survive intermediate saves. New-schema battles require an explicit perk-rules flag. Sandbox F5 uses its isolated save path; a native test verifies that it cannot overwrite production bytes. F9 within a personal tree reloads partial Gifted and automatic purchase saves.

## Generated builds and balance limits

All 54 access pools were found through actual seeded founder generation. One founder per pool was advanced along three distinct legal ten-point routes. The test uses the exact saved growth offers, picks three stats per level through Campaign.develop, obtains points through the real XP provider and validates each completed career save. These are 162 complete generated-stat builds. Level-eleven XP and a 900-crown gear allowance are declared fixtures; the test does not claim those resources are naturally attainable in the short campaign.

Each build fights open-ground, ranged-pressure and high-fatigue 3v3 scenarios on both sides, for 972 battles. The controls have fixed stats and no career perks. AI does not plan Rotation, Footwork or Indomitable. Aggregate results and the nine authored demo routes are in [perk validation](PERK-VALIDATION.md); detailed machine reports are included. Those comparisons support continued playtesting, not a verdict of equal usefulness. No perk numbers were tuned to fit automated outcomes.

Under the new weapon/AP rules, the 24 actual first-contract journeys finish in **12 victories and 12 defeats**. Their earned XP, growth and saves validate. The first 12 overlapping seeds finish six/six in paired restore checks. These differ from 0.17's outcomes and should not be read as additional independent trials or proof of BB-identical tuning. Enemy AI planning, long-campaign XP/economy, ranged trees and manual assessment of the weaker hybrid route remain future work.

## Native UI and release

Native checks use a 1440×900 Xvfb window, Mesa software rendering and isolated save directories. Personal trees, ordinary earned Colossus, Gifted, active actions, recruit preview and weapon comparison were visually inspected. Space remains Wait and F ends only the active fighter. The accepted graphics warning is unsupported VSync in the software renderer.

Two added native test expectations were corrected: normal growth contains ten preallocated rows rather than an empty array, and the axe still costs five AP versus the sword's four. These were assertion mistakes, not changed game rules. Final reruns pass. The optional sandbox's manual-save destination was corrected after inspection; explicit production-byte isolation is now covered. Weapon comparison now shares penetration math with combat and labels unavailable greatsword Riposte.

Source import passes. The release ZIP is CRC-checked, extracted fresh, imported and run through a full normal-start smoke battle. No Godot cache, player save, probe or downloaded reference source is packaged. This is a source project for Godot 4.4.1, not a native Windows/macOS export.

The original integration-pack notes are retained as explicitly historical `*-PACK.md` files. Previous release evidence is in `VALIDATION-v0.17.md` and earlier reports. Those are not claims that every historical UI script still describes the new interface.

![A perk earned in the actual campaign](perks-earned-campaign.png)

![Completed Gifted in the ordinary campaign UI](perks-campaign-gifted.png)
