# Validation — armour readability 0.13.2

Godot 4.4.1 on Linux x86-64. Native journeys use a 1440×900 window, Mesa software rendering and isolated save directories. This validates the source project, not exported executables or human balance.

## Checks rerun

| Suite | Checks | Failures |
| --- | ---: | ---: |
| `tests/armor.gd` | 2,447 | 0 |
| `tests/playability.gd` | 42 | 0 |
| `tests/armor_readability_ui.gd` | 24 | 0 |
| `tests/armor_ui.gd` | 77 | 0 |
| **Total** | **2,590** | **0** |

Only these four suites were rerun for this presentation change. Prior wider checks remain historical evidence in `VALIDATION-v0.13.1.md` and `VALIDATION-v0.13.md`. No combat damage, pathfinding, AI, gear ownership, repair pricing, RNG or save-schema logic changed in this patch.

## Actual comparison semantics

Body armour displays the sum of body protection and padding, including both maxima. The original two damage pools remain separate internally. Head armour uses its existing assembled current and maximum. The main equipment comparison, stored kit summaries, exchange descriptions, battle sidebar and weapon-action enemy inspection use consistent current/max values.

The preview's **now** change is proposed remaining durability minus equipped remaining durability. Its **max** change compares fully repaired capacities independently. Each gets its own colour. Maximum capacity is not a universal gear score: load costs and individual layer mechanics still matter.

Components show BROKEN at zero condition with positive capacity, DAMAGED below maximum and FULL at maximum. Zero-durability cosmetic pieces remain Cosmetic. A zero-capacity assembly displays NO ARMOUR. Viewing comparisons never repairs or swaps the physical items.

## Native reproduction of the reported confusion

The new readability journey creates an explicitly declared equipment fixture matching the screenshot: ruined 0/22 quilting, ruined 0/85 mail, cosmetic tabard and a 40/40 helmet. Gear condition is injected only to isolate the UI case; no battle victory or earned loot is fabricated. All subsequent previews, confirmations, paid repair and save/load use real mouse/keyboard input.

It verifies:

- **0/107 → 30/115**, **+30 now / +8 max** when previewing fresh linen.
- **+22 now / +0 max** for an identical fresh quilting replacement.
- **−17 now / +23 max** for a more protective but damaged gambeson.
- **+25 now / −15 max** for fresh weaker linen compared with that damaged gambeson.
- The discarded broken component remains broken in stores after a confirmed swap.
- Paid repair raises the worn set from **5/130 to 130/130** without increasing maximum capacity.
- Cosmetics are not marked broken; helmet, whole-kit and exchange comparisons retain correct current/max values.
- Previews do not mutate the campaign; F5/F9 retains confirmed condition and repair costs without committing an unconfirmed choice.

![Reported example with separate current and maximum changes](armor-upgrade-current-max.png)

![Fresh gear can still have lower maximum protection](armor-fresh-downgrade.png)

![Paid repair restores current condition, not capacity](armor-repaired-current-max.png)

The comparison, equal-capacity replacement, repaired kit and whole-kit exchange screens were visually reviewed. Both delta colours remain visible, and current/max values and status labels fit their columns.

## Existing gameplay regression

The existing native armour journey performs real fitting, shop purchase, incompatible helmet refusal, whole-kit storage and exchange, an actual generated-company battle, persistence of combat damage, and paid survivor repairs. It also tests native save/load. Its battle is separate from the declared readability fixture.

The model armour suite retains 50-company outfit/ownership coverage, all components, previews, exact equip results, shop accounting, repairs, actual battle damage, save corruption refusal and older-save migration. The playability suite verifies read-only planning, feedback and a complete escort encounter.

Campaign schema remains 12 and battle schema remains 9. Existing saves retain their exact stored state. This patch does not implement the pending v0.14 encounter/AI work, direct attacks on camps or further combat-feedback changes.

## Package

The source is imported, the ZIP is CRC-checked, then a clean extraction is imported and runs a complete smoke battle. Godot caches and player saves are excluded. Script errors and assertion failures are not accepted; the software renderer's VSync warning is benign.
