# Validation — ranged integration 0.19

Godot 4.4.1, Linux. **32,074 checks, zero failures** in the final runs below. Repeated assertions and overlapping fights are not independent balance evidence.

| Suite | Checks | Scope |
|---|---:|---|
| `ranged_perks.gd` | 7,513 | 162 pools, four legal weapon routes per pool, generated recruits, nine earned-point career builds, bow/crossbow/throwing mechanics, counters, ammunition, merchant/refill rules and old encounters |
| `ranged_integration.gd` | 10,899 | Three veteran 0.18 camps and ongoing fights; exact old results, pick preservation/refunds, saved markets; 162 actual generated founder pools and 486 completed stat/perk careers |
| `ranged_trials.gd` | 531 | 216 authored 3v3 smoke battles; nine ranged/hybrid builds, three conditions, four seeds, both sides; unequal equipment costs |
| `perks.gd` | 134 | Existing melee arithmetic, pools, tier gates, actions and persistence; 57-entry catalogue |
| `perk_timing.gd` | 16 | Reactions, Wait, expiry, stagger immunity and switching |
| `perk_progression.gd` | 226 | Actual point provider, forged overrides, Gifted/Colossus and ten-point cap; three 0.17 continuations |
| `perk_lab.gd` | 11 | Nine melee demo presets save through production progression validation |
| `talent_growth.gd` | 7,569 | 3,600 generated people, 1–3 stars, saved three-stat choices, level 11, banking, malformed saves and legacy catch-up |
| `turns.gd` | 3,631 | 24 real first-contract journeys, saves, earned growth and earlier mixed-queue continuations |
| `turns_combat.gd` | 258 | 25 weapons, ranged firing lanes including throws, costs, reactions, stagger and objectives |
| `combat_baseline.gd` | 141 | Accuracy, defence, morale, fatigue, shields and 12 paired actual first contracts |
| `damage_balance.gd` | 372 | Pooled armour/component wear, older equipment migration, deterministic fights/settlement |
| `archer_rules.gd` | 396 | Historical bow/crossbow geometry and friendly-line regressions; three complete battles |
| `equipment_economy.gd` | 268 | Ownership, old weapon fixtures, markets, repair/sales, 15 fresh fights and a replay; throwing economy separately tested above |
| `ranged_ui.gd` | 54 | Native tree, all nine presets, prehire/hire, F5/F9, paid refill, Hybridization display, real bow shot and engaged throw; authored combat fixtures |
| `perk_save_ui.gd` | 14 | Partial Gifted, ordinary saved growth, automatic purchase saves and byte-exact isolation of sandbox/production files |
| `turns_ui.gd` | 41 | Normal campaign controls, gear, Space Wait/F finish, actual victorious battle, earned three-stat training and perk purchase, automatic save/F9 |

## Integration and compatibility

The supplied 57-perk catalogue is unchanged. The earlier 45 retain their names, tiers and values; King of All Weapons adds the supplied clarification that a prepared Head Hunter attack takes priority. Production progression and its point adapter are byte-identical to 0.18. The real point provider remains level minus one, capped at ten; demo fixtures grant explicit XP through that provider rather than override it. Gifted, stars and ordinary training remain separate.

Eight frozen 0.18 modules match delivered source except their pinned dependency/data paths. Earlier readers have only Arsenal/Market/catalogue references pinned to their previous data. Three veteran 0.18 campaigns keep exact melee pools/purchases, XP, stats, stars and future growth. Old ranged placeholders refund once. Existing market stock/cash is unchanged. Three ongoing veteran battles retain identical actions, RNG, casualties, physical equipment, records and settlement before adopting at camp. Three neutral ranged state fields are excluded from structural comparison; no combat result is excluded.

Current campaign schema 18 and battle schema 14. Saving while adoption is pending works. Missing perk-rules flags and attempts to disable perks in a current campaign are rejected. Normal startup and production/sandbox save isolation are retained.

## Generated careers and balance limits

Actual founder generation covers all 162 ranged access pools. Each is trained through its own saved rolls along bow, crossbow and throwing routes: 486 complete careers, ten three-stat choices and ten legal perk purchases each. Growth selects Health, Ranged skill and Stamina. No final stats are authored for this check. Level-eleven XP is a declared fixture, not evidence of reaching the cap naturally within 30 days. The four-route structural test also checks each pool's one melee mastery.

The separate 216-battle trial uses nine authored final-stat fixtures, differing gear costs and fixed unperked controls. It checks execution, not equal investment or equal strength. AI does not plan Wait/Patient Hunter or Footwork, Rotation and Indomitable. See the actual [trial report](ranged-trial-results.json); manual balance work remains. The 24 real first-contract journeys finish 12 victories and 12 defeats, unchanged from 0.18. The 12 paired accuracy/damage journeys overlap those seeds and finish six/six.

## Native verification and release

Native tests run at 1440×900 with Mesa software rendering and isolated saves. Tree, action-cost, ammo, recruit-preview and throwing-refill screenshots were inspected. Actual input fires a bow and throws while engaged, consuming AP/fatigue and physical ammunition. Another native journey completes a normal campaign battle, trains three earned stats and buys an earned perk. The Gifted test resumes a partially selected bonus and verifies that saving the demo leaves production bytes unchanged.

Test fixtures were adapted to the integrated point provider and production modal behaviour. Historical weapon fixtures intentionally exclude throwing; current 25-weapon and ranged suites test throws under their actual rules. The initial native launch required restoring the missing Xvfb keyboard compiler; subsequent runs pass. Accepted graphics warning: unsupported VSync under software rendering.

The source import, final ZIP CRC, clean extraction/import and full normal-start smoke battle pass. No Godot cache, player save, temporary probe or external reference source is packaged. This remains a Godot source project; Windows/macOS executables were not produced. Prior reports are retained as historical evidence, not claimed as newly rerun.

![Ranged tree](ranged-bow-tree.png)

![Bow action costs and ammunition](ranged-volley-actions.png)
