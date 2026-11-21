# Validation — weapon comparisons 0.13.3

Godot 4.4.1 on Linux x86-64. Native input runs in a 1440×900 window with Mesa software rendering and an isolated save directory. This validates the source project, not standalone exports or human balance.

## Checks rerun

| Suite | Checks | Failures |
| --- | ---: | ---: |
| `tests/weapons.gd` | 865 | 0 |
| `tests/equipment_economy.gd` | 220 | 0 |
| `tests/weapon_compare_ui.gd` | 35 | 0 |
| **Total** | **1,120** | **0** |

Only these two model suites and this native journey were rerun for the weapon-preview UI. Earlier broader checks remain historical evidence in the versioned validation reports. No combat rules, prices, gear ownership, buying/equipping mutations, saves or RNG logic changed.

## Comparison behavior

The selected item is compared with the actual selected-slot weapon. If a carried slot is empty or holds a shield, the equipped main hand is explicitly labelled as the reference. The same profiles serve company stores and the local weaponsmith. Profiles are read-only and use the mercenary's actual armour load, temperament and perks for primary and special fatigue costs.

Both portraits, names and primary actions are visible. The table compares damage, minimum/maximum reach, attack AP, attack fatigue, weapon accuracy bonus, armour-damage multiplier, penetration, hands and ammunition. Signed deltas use beneficial/adverse/neutral colours; a larger minimum range and larger maximum range is a mixed tradeoff. Paired damage/reach deltas are labelled as min/max. Penetration changes use percentage points, explained in the footer. Accuracy is explicitly a weapon bonus rather than a computed target hit chance.

Both special-action descriptions and personal costs are visible. Crossbow previews therefore expose reload cost alongside their cheap shot. Notes warn about returning an offhand shield to stores, the free carried slot needed to stow a shield during a later battle switch, missing/mismatched/empty ammunition, and buying separately from equipping. Storing a carried weapon does not change the main hand; equipping a one-handed weapon does not automatically recover a shield from stores.

## Native player journey

A fresh seed-2 company uses only ordinary starting stores and a paid shop purchase. No equipment, resources, victories or state are injected for the comparison journey.

The test equips the existing arming sword, then previews the existing axe. It checks 24–35 versus 32–45 damage, +8/+10 damage bounds, +1 AP, -8 weapon accuracy, +0.50 armour multiplier and +5 percentage points of penetration. Browsing is compared against a full campaign snapshot to establish that it changes neither resources nor gear/RNG.

It then previews and confirms a billhook, verifying its exact two-hex minimum/maximum, the mixed reach indicator, whole-number hand counts, advance shield warning and actual return of the same shield to stores. A bow preview warns about missing arrows; fitting an ordinary quiver through the ammo slot resolves the equipment requirement. Previewing a crossbow next identifies the arrow pack as incompatible, shows bolts instead, and exposes both the three-AP shot and four-AP reload.

An empty carried slot uses the main hand as a labelled reference. After storing a hammer, the next candidate compares against that hammer rather than the still-equipped bow. The company then previews and buys a short sword at the displayed town price; the first confirmation leaves it in stores and the second equips it. The offhand remains empty until the existing shield is explicitly equipped again.

F5/F9 preserves the selected and confirmed physical equipment. A real contract is accepted, travelled to and deployed. The purchased short sword's actual primary action cost matches the prior personal preview. One full native battle completes and its settlement reloads correctly.

![Main-hand comparison](weapons-comparison-main.png)

![Two-handed reach and shield tradeoffs](weapons-comparison-two-hands.png)

![Crossbow ammunition and reload comparison](weapons-comparison-crossbow.png)

![Occupied carried-slot comparison](weapons-comparison-carried.png)

![Shop preview before purchase](weapons-comparison-shop.png)

The final main-hand, two-handed, crossbow, carried-slot and shop screens were visually inspected. The existing weapon model suite retains actual actions, switching, ammunition, loot and historical continuation checks. The economy suite exercises all 23 weapon primary/family costs, finite stock/purses, purchases, sales, repair and generated battles.

## Save and package

Campaign/battle schemas remain 12/9. Existing saves retain their state, and the earlier archer and armour-display fixes remain included. The planned v0.14 encounter/AI work, direct camp attacks and additional combat-feedback changes are still pending.

The package is imported, ZIP CRC-checked, extracted into a clean directory, reimported and smoke-tested through a complete battle. Generated Godot caches and player saves are excluded. Failing assertions and script errors are not accepted; software-display VSync warnings are benign.
