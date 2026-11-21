# Perk validation — integrated 0.18

The current catalogue has 45 perks and 54 personal access combinations. See [release validation](VALIDATION.md) for all final checks and source/migration verification. The original independent pack results remain in `PERK-VALIDATION-PACK.md`.

## Actual generated-stat routes

54 actual generated founders, one per pool combination. Three distinct legal ten-point routes each; exact saved three-stat rolls to level eleven. XP and a 900-crown equipment allowance are declared test fixtures, not a claim about 30-day attainability. Three-versus-three AI, both sides, open/ranged-pressure/fatigue scenarios. AI does not plan active perks. Control units use fixed stats and no perks. No final personal stats are authored.

| Route | Builds | Team wins / 324 | Recruit alive / 324 | Draws | Maximum gear cost |
|---|---:|---:|---:|---:|---:|
| Polearm support | 54 | 238 | 199 | 6 | 746 |
| Spear line | 54 | 279 | 301 | 7 | 686 |
| Sword fighter | 54 | 202 | 166 | 7 | 430 |

These builds start from the same actual founder within each pool; ordinary growth choices and equipment differ by route. All train Health and Melee skill; sword/spear train Melee defence, polearms train Stamina. This is three constructive examples per pool, not an exhaustive optimization of every recruit. Strong spear results and lower sword survival warrant manual balance testing. A team victory can occur after the test recruit dies; routed survivors count as alive.

## Authored demo fixtures

Nine authored stat/perk fixtures; ten points each, same 900-crown gear ceiling, actual costs vary. Three-versus-three matched-seed AI smoke trials, both sides. AI does not plan Rotation/Footwork/Indomitable; these are covered by command tests and available to the player. This is regression/optionality evidence, not a balance verdict or generated-stat viability proof.

| Build | Gear cost | Raw armour load | Team wins / 120 | Recruit alive / 120 | Draws |
|---|---:|---:|---:|---:|---:|
| Runa: Spear sentinel | 425 | 30 | 116 | 118 | 1 |
| Runa: Sword duelist | 250 | 15 | 84 | 66 | 1 |
| Runa: Polearm bodyguard | 530 | 30 | 88 | 71 | 0 |
| Hagen: Heavy shield anchor | 686 | 55 | 101 | 106 | 5 |
| Hagen: Armoured greatsword | 791 | 55 | 110 | 96 | 0 |
| Hagen: Resolute polearm support | 420 | 30 | 99 | 69 | 2 |
| Mara: Spear skirmisher | 245 | 15 | 102 | 88 | 0 |
| Mara: Medium greatsword | 530 | 30 | 104 | 89 | 0 |
| Mara: Sword and polearm opportunist | 350 | 15 | 47 | 20 | 1 |

These 1,080 fixture battles were rerun on the integrated build. Outcomes match the supplied pack's authored trials. Mara's sword/polearm hybrid remains weaker in automated combat; manual switching and positioning need further evaluation. The active commands and player UI are tested separately because AI does not plan them. Equal equipment ceilings do not mean equal equipment spending or equal combat strength.

## Reproduce

Run from the extracted project using Godot 4.4.1. The last three commands require a native display.

```bash
godot --headless --path . --script tests/perks.gd
godot --headless --path . --script tests/perk_timing.gd
godot --headless --path . --script tests/perk_progression.gd
godot --headless --path . --script tests/generated_perk_builds.gd
godot --headless --path . --script tests/perk_trials.gd
godot --path . --script tests/perks_ui.gd
godot --path . --script tests/perk_save_ui.gd
godot --path . --script tests/turns_ui.gd
```
