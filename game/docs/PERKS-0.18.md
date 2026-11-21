# Personal perks — integrated 0.18

This release reconciles the supplied 0.16-based perk integration pack with the delivered 0.17 talents/progression build. The production project keeps its identity and normal main scene. The perk catalogue and numerical effects are retained; the XP, growth and talent systems remain the 0.17 systems.

## Saved personal options

| Category | Selection per eligible person |
|---|---|
| Weapons | Spear, Sword and Polearm |
| Armour | Two of Light, Medium, Heavy |
| Fighting style | Two of Shield, Swift, Power |
| Character | Two of Tough, Fast, Trained, Vigorous |
| Shared fundamentals | Colossus, Pathfinder, Fast Adaptation, Fortified Mind, Steel Brow, Quick Hands |

Duplicate perks appear once. All 54 category combinations yield 34–36 options from the 45-perk catalogue. A separate identity-seeded RNG chooses groups uniformly; it consumes no company, growth or combat RNG. The exact groups and pool are saved, displayed before hiring and copied into the hired record. Gear choices never reroll or restrict the pool. This first roster is applied to melee founders/recruits only. Ranged recruits keep the earlier four perks; switching a melee recruit to a bow does not change their personal pool.

## Progression contract

`Progression.earned_perk_points(s)` is the sole point source: level minus one, capped at ten. `Progression.points` subtracts purchased IDs once. `PerkProgression` delegates to it; no demo override can grant production points. If an imported optional cumulative `perk_points_earned` value is present, it must match actual earned points. There is no second XP table or remaining-point counter.

Each level 2–11 still grants three different ordinary stat choices and one separate perk point. Seven perk tiers need zero through six previous purchases anywhere. Pool membership, duplicates, purchase order and point budget are validated. Completing Gifted is required before another perk purchase. Level 11 and ten perks remain the cap; the short 30-day scenario does not establish that the cap is naturally reachable in one campaign.

Gifted permanently adds three distinct gains: Health/Stamina/Resolve/Ranged skill/Ranged defence +4; Initiative +5; Melee skill/Melee defence +3. These gains do not use stars, replace normal growth or grant XP/levels/extra perk points. Partial choices are saved and resume without reapplication. Colossus derives maximum HP after wounds; learning it and later health growth increase current HP by the change in maximum HP, preserving absolute missing health. Fortified Mind is likewise derived, not written into base Resolve. Brawny and Perfect Fit change equipment penalties without changing raw armour weight or its perk effectiveness band.

## Combat and UI

Open **Company & Equipment → Person & Service → Personal perks**, or the **Personal perks** button in a profile. A recruit's profile previews their tree before purchase. Group buttons highlight related options without hiding alternatives. Selecting a perk displays its full effect and the purchase gate. Learn and each Gifted choice auto-save; F5 and F9 also work in the tree.

**Weapons & active perks** (6) exposes Rotation, Footwork and Indomitable when learned. Rotation and Footwork enter hex targeting; Indomitable activates directly. Space waits and F ends the current activation. Trigger state, once-per-round allowances, pending effects and Wait behaviour persist through saves. The ordinary AI does not yet plan these active actions.

New perk battles also adopt the pack's weapon roles: one-handed swords/spears cost 4 AP at range one; polearms reach one–two hexes, with −15 adjacent accuracy until mastery and a 5 AP primary attack with mastery; greatswords cannot Riposte. Recover is universal at 9 AP and removes half accumulated fatigue (rounded down remaining). Deep Breath or retained Second wind instead removes 65%. Weapon comparison uses the combat functions for costs and permanent penetration bonuses; damage/accuracy are labelled base values because other bonuses depend on the target and current battle state. Unavailable greatsword Riposte is explicitly labelled.

## Compatibility

Campaign schema 17; battle schema 13. Delivered 0.17 campaign/battle/people/progression readers are frozen with pinned dependencies. Existing earlier readers remain intact. Old ongoing encounters and aftermath keep their original combat, RNG, equipment damage, casualties and XP settlement through the return to camp. New perk rules never appear halfway through an old fight.

At that camp boundary (immediately for a camp save), eligible living melee soldiers receive a saved pool. Their earlier placeholder perk picks are cleared, returning those points to the existing level-derived budget. Base stats, XP, history, talents, completed growth and all future rolls remain. Ranged and fallen records retain earlier perks. The conversion records its completion, so loading again cannot repeat the refund. Earlier health/combat/growth conversions run at their established boundary before perk adoption.

## Demo and validation fixtures

Normal startup opens the real campaign. For the optional authored demo, run `src/perk_sandbox.tscn` or `godot --path . -- --perk-lab`. Runa, Hagen and Mara have preset final stats and test XP supplied through the actual point provider. Presets are fixtures, not evidence of natural campaign progress. Demo controls are unavailable in normal play.

The demo always starts fresh. Explicit F5 saves and F9 loads `ashen-company-perks-lab-save.json`; the ordinary game uses `ashen-company-save.json`. Demo autosaves are disabled. Native regression checks verify that saving the demo leaves the normal save byte-for-byte unchanged.

See [current validation](VALIDATION.md), [perk trial details](PERK-VALIDATION.md), [0.17 growth rules](TALENTS-0.17.md) and the exact catalogue in `data/perks.json`. The original pack's integration and validation notes are preserved with `-PACK` filenames and marked historical.
