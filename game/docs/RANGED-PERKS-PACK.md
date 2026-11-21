# Ranged perk trees: implemented starter

The twelve additions below bring the catalogue to 57. These are authored adaptations for this prototype, not exact ports of mod scripts. Their displayed rules and executable tests define the implementation.

Every newly generated ranged recruit receives Bow, Crossbow and Throwing, one of Spear/Sword/Polearm, two of Light/Medium/Heavy, Marksman and one of Shield/Swift/Power, plus two character groups. Six shared fundamentals are always present. Duplicate perks appear once. There are **162 distinct ranged pools of 36–42 perks**. A tier only requires previous points spent anywhere; there are no weapon-branch prerequisites, stat locks or equipment locks.

Marksman contains Anticipation, Overwhelm, Footwork, Head Hunter, Bullseye and Killing Frenzy. Existing melee pools are preserved. For now, the initial ranged loadout selects the ranged pool profile; the group's choices are sampled uniformly from the saved person seed. Later equipment changes do not change a tree. Background weighting is not yet implemented.

## New rules

### Bow

| Perk | Tier | Implemented effect |
| --- | --- | --- |
| Target Practice | 2 | Bow shots gain +10 accuracy against ranged weapon users, or targets with neither a working shield nor an adjacent standing ally. Applies only to deliberate shots; does not bypass line of sight. |
| Bow Mastery | 4 | Bow actions cost 25% less fatigue and gain one hex of maximum range. Applies to Quick Shot and Aimed Shot; does not bypass engagement, ammunition or line-of-sight requirements. |
| Patient Hunter | 5 | After using Wait this round, Aimed Shot gains +20% regular and armour damage. Quick Shot receives no bonus. Waiting preserves AP and gives no additional fatigue recovery; the benefit ends with the round. |
| Hip Shooter | 6 | Quick Shot costs 3 AP instead of 4. Each earlier paid bow shot this round adds 7 to its non-perk fatigue cost, hit or miss. Aimed Shot keeps its normal AP and fatigue. Wait and switching never reset this escalating cost; only your first activation next round does. |

### Crossbow

| Perk | Tier | Implemented effect |
| --- | --- | --- |
| Power Shot | 2 | A paid crossbow hit that removes at least 10 HP has a 35% chance to stagger a standing target: -2 current AP and -2 AP on its next first activation. Repeated staggers do not stack. Armour-only hits and reactions cannot trigger it. Indomitable prevents the stagger. |
| Crossbow Mastery | 4 | Crossbow shots and reloads cost 25% less fatigue. Reload costs 3 AP instead of 4, including heavy crossbows. Loaded state stays with the physical weapon; mastery grants no ammunition or free reload. |
| Iron Sights | 6 | Paid crossbow shots gain +20 percentage points of head-hit chance. Accuracy and damage multipliers do not change. Combines with Head Hunter; no effect on bows, throws or melee. |

### Throwing

| Perk | Tier | Implemented effect |
| --- | --- | --- |
| Hybridization | 2 | Add floor(10% of ranged skill after wounds/scars) to melee attack skill and floor(10% of melee skill after wounds/scars) to ranged attack skill, before morale and Overwhelm. Use unmodified input skills; never feed the bonuses into each other. Once per round a swap to or from a throwing weapon costs 0 AP, excluding shield changes. Shares its allowance with Quick Hands; fatigue remains 4. |
| Throwing Mastery | 4 | Throwing actions cost 25% less fatigue. Throws gain +20% regular and armour damage at one or two hexes, or +10% at three hexes. No damage bonus at four hexes. Includes javelins and throwing axes; does not replenish bundles. |
| Opportunist | 6 | Your first two paid throwing attacks of the battle cost one less AP, minimum 3. Hit or miss consumes an allowance and one weapon from the held bundle. Switching, Wait and new rounds never restore these allowances. No corpse ammunition or AP recovery in this adaptation. |

### Shared Marksman additions

| Perk | Tier | Implemented effect |
| --- | --- | --- |
| Head Hunter | 5 | A paid head hit prepares one guaranteed head hit on your next eligible paid weapon attack. The prepared attack consumes the charge even on a miss, and cannot rearm it. Body-only attacks and reactions neither use nor build the charge. Persists through turns, Wait and swaps; clears after battle. |
| Bullseye | 6 | Paid ranged attacks gain +15 percentage points of armour penetration, capped at 100%. Includes bows, crossbows and thrown weapons. This adaptation changes penetration only: blocked shots remain blocked and full armour bypass is a separate property. |

## Throwing equipment

| Weapon | Regular damage | Armour factor | Penetration | Range | Bundle | Load |
| --- | --- | --- | --- | --- | --- | --- |
| Javelins | 30–45 | 0.90 | 45% | 1–4 | 5 throws | 6 |
| Throwing axes | 35–45 | 1.25 | 25% | 1–4 | 5 throws | 8 |

Both use ranged skill, add +10 weapon accuracy, and lose two accuracy per hex beyond the first. Both are one-handed, shield-compatible and usable while engaged. Quick throw costs **4 AP / 15 fatigue**. Heavy throw costs **5 AP / 20 fatigue**, adds −5 accuracy and +20% armour damage. Perks modify those costs/effects as described above.

A bundle's physical `condition` stores remaining throws, 0–5. Each paid attack consumes one on hit or miss. The bundle never uses the arrow/bolt slot. Carried bundles keep independent counts; switching cannot refill them. Empty bundles cannot attack. The AI switches to a suitable carried melee weapon when empty. Town refills cost four crowns per missing throw before reputation pricing and update the existing merchant ledger. Tool repair cannot replenish bundles. New companies have spare bundles, and newly created weekly markets sell both types.

## Timing and combination rules

- Hip Shooter's count resets at the first activation of the next round. Wait and swaps preserve it. Bow Mastery plus Hip Shooter yields quick-shot fatigue costs **12, 17, 22** with neutral traits, and three shots consume all nine AP.
- Crossbow Mastery allows shoot/reload/shoot at **3 + 3 + 3 AP**. Reload costs 15 fatigue before other applicable reductions. Reloading does not create ammunition; a case holds eight bolts.
- Opportunist's two uses last for the whole battle; spent uses are never restored by another round. Heavy throws receive the same one-AP reduction, down to four.
- Hybridization and Quick Hands share one free-swap allowance. Any shield equip/stow costs AP. Both input skills are read before either hybrid bonus is added, after scars/wounds and before Overwhelm/morale.
- Head Hunter persists through Wait, swaps and rounds. Its forced attack cannot prime another charge. Body-only attacks, shield-split and reactions neither use nor generate it. A prepared head hit overrides King of All Weapons' location roll.
- Damage bonuses add together, then multiply the action's regular and independent armour roll. Fatigue reductions retain the existing 50% floor and single upward rounding. Bullseye penetration is not full armour bypass. Indomitable prevents Power Shot stagger.

The UI displays exact costs, ammo/loaded state, volley count, unused opening throws and prepared Head Hunter state. Hit previews use the same skill and accuracy calculation as resolution. Strict firing lanes, shields and engagement remain relevant.

## Example choices

| Recruit | Shared personal tree supports these presets |
| --- | --- |
| Lysa | Volley archer; Patient archer; Sword skirmisher with throwing backup |
| Oren | Crossbow harrier; Iron hunter; Polearm hybrid with javelins |
| Tova | Shield thrower; Axe skirmisher; Spear hybrid |

Each trio uses one unchanged personal tree and one set of authored permanent stats. Armour and weapon choices differ. The fixtures demonstrate choices and allow manual playtesting; they do not promise that every arbitrary generated recruit can reach every authored stat total.

## Concept references

[Reforged's weapon design diary](https://github.com/Battle-Modders/mod-reforged/wiki/DevDiary-4-Weapons-Design) informed Target Practice, Hip Shooter, Power Shot, reload-focused Crossbow Mastery, Iron Sights, Hybridization, Opportunist and penetration-focused Bullseye. [Reforged's dynamic tree diary](https://github.com/Battle-Modders/mod-reforged/wiki/DevDiary-3-Dynamic-Perk-Trees) informs the grouped-pool approach. [Legends' perk-group reference](https://github.com/Battle-Brothers-Legends/Legends-public/wiki/Perk-Trees) lists Patient Hunter in its bow group; the Wait/Aimed rule here is our own explicit adaptation. Bow/Throwing Mastery and Head Hunter also retain recognisable base-game concepts with the prototype rules specified above. No mod code or artwork was copied for this extension.

Further expansion can add perks/groups without rerolling existing trees. Balance numbers, background weights and richer AI should follow manual and generated-career playtests.
