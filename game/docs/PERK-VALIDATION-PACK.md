> Historical integration-pack notes, based on 0.16. For the merged 0.18 release use [current perk notes](PERKS-0.18.md) and [current validation](VALIDATION.md).

# Perk validation

Final rules are tested in Godot 4.4.1. Native UI checks use the compatibility renderer at 1440×900.

| Check | Result |
| --- | --- |
| Catalogue, pool combinations, point gates, formulas, actions, persistence and migration | 134 checks, passed |
| Reaction, Wait, expiry, pressure, pull immunity and swap timing | 16 checks, passed |
| All nine sandbox presets save/load | 11 checks, passed |
| Native tree, prehire/hire, Gifted and active-perk UI | 18 checks, passed |
| Existing combat-baseline regression | 141 checks, passed |
| Existing pooled-damage and migration regression | 378 checks, passed |
| Nine builds × five situations × twelve seeds × both sides | 1,080 battles; 2,259 checks, passed |

Legacy battle comparisons ignore the new serialized `perk_rules: false` field, just as they ignore prior schema flags. Actions, RNG, casualties, equipment and settlement still compare exactly. The production progression source SHA-256 remains `223f3a71263ea035a4ee1ff94d638ef708c6c303ef3c9c49a0747e7d1ee1cad5`.

## Matched scenario results

Each build has 120 trials: open ground, a choke, ranged pressure, a flank and a fight begun at high fatigue. Each has ten authored picks and stats from the approved roster examples. Each team contains the test recruit and two unchanged controls. Both board sides are tested. Equipment uses actual legal components and a common 900-crown ceiling; unspent crowns are not converted into combat bonuses.

| Build | Gear cost | Raw armour load | Team wins / 120 | Recruit alive / 120 | Draws |
| --- | ---: | ---: | ---: | ---: | ---: |
| Runa: Spear sentinel | 425 | 30 | 116 | 118 | 1 |
| Runa: Sword duelist | 250 | 15 | 84 | 66 | 1 |
| Runa: Polearm bodyguard | 530 | 30 | 88 | 71 | 0 |
| Hagen: Heavy shield anchor | 686 | 55 | 101 | 106 | 5 |
| Hagen: Armoured greatsword | 791 | 55 | 110 | 96 | 0 |
| Hagen: Resolute polearm support | 420 | 30 | 99 | 69 | 2 |
| Mara: Spear skirmisher | 245 | 15 | 102 | 88 | 0 |
| Mara: Medium greatsword | 530 | 30 | 104 | 89 | 0 |
| Mara: Sword and polearm opportunist | 350 | 15 | 47 | 20 | 1 |

These are smoke/regression trials, not a balance ranking. The AI does not plan Rotation, Footwork or Indomitable, though the commands and player UI are tested. One control team has no career perks. Team wins can occur after the tested recruit dies; escaped recruits count as alive. Exact per-scenario outcomes, damage and recovery counts are in `perk-trial-results.json`.

Mara’s sword/polearm hybrid underperforms in these automated fights. Manual play must test whether its switching, positioning and support justify its weaker direct fighting. The current evidence supports retaining multiple test routes; it does not justify declaring all nine equally strong. No perk numbers were retuned to fit these results.

## Reproduce

From the project directory:

```bash
godot --headless --path . --script tests/perks.gd
godot --headless --path . --script tests/perk_timing.gd
godot --headless --path . --script tests/perk_lab.gd
godot --headless --path . --script tests/combat_baseline.gd
godot --headless --path . --script tests/damage_balance.gd
godot --headless --path . --script tests/perk_trials.gd
# Requires a native display:
godot --path . --script tests/perks_ui.gd
```

Earlier tests that specifically expect the four placeholder perks in every recruit’s UI describe the old interface. They are retained as historical tests, not claimed as passing under the new personal-tree interface. Keep the separate progression project’s current checks when merging.
