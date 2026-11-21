# Combat balance 0.15

This is the first damage/equipment rebalance, not a claim of complete Battle Brothers parity. It retains the original weapon families, paid special actions and layered outfits. All gameplay changes apply to both armies.

## Ordinary hit calculation

Let R be the regular-damage roll, Q an independent weapon-damage roll multiplied by armour effectiveness, A current protection, and p penetration. Body A includes every protective body layer; head A includes all helmet parts. Armour wear is rounded once to a whole point because component condition is stored as integers.

1. Armour loss D = min(A, round(Q)); remaining armour A′ = A − D.
2. Direct HP damage = max(0, R × p − 0.1 × A′).
3. If armour breaks, add max(0, R × (1 − p) − D).
4. Multiply the result by 1.5 for a head hit, then round once to whole HP. Displayed HP loss is capped at actual remaining health.

Full bypass (Puncture) deals its modified regular damage directly, with zero armour wear and no remaining-armour mitigation. Puncture and Shatter force body hits. Shatter doubles armour wear and halves resulting HP damage; unlike the old implementation, it has no forced one-HP minimum through fully blocking armour. Stagger applies on a hit even when armour prevents all HP loss. Existing aimed-shot, hook, riposte and brace identities remain. No universal minimum HP leak is applied.

Examples with R = Q = 40 and 20% penetration: 100 armour loses 40 armour and 2 HP; 200 armour loses 40 armour and 0 HP; 30 armour loses 30 armour and 10 HP; no armour loses 40 HP. A head hit against 100 helmet armour loses the same 40 armour and 3 HP. Splitting body protection between mail and padding does not change the answer.

The ordinary formula is based on the previously audited [public 1.5.2.2 script mirror](https://github.com/ninkjin/Battle-Brothers-Scripts/blob/162f498ac7c49b4c317bbf54718a595ecef6a65a/README.md) and its [actor damage handler](https://github.com/ninkjin/Battle-Brothers-Scripts/blob/162f498ac7c49b4c317bbf54718a595ecef6a65a/scripts/entity/tactical/actor.nut). That is a community mirror, not an official source release. Whole-point durability rounding and the authored specials remain this prototype’s explicit conventions. Tests evaluate known formula outcomes; the commercial game executable was not run.

## Health and weapon scale

Generated starting HP is round(previous seeded HP × 0.75); the seeded draw and every non-health attribute are unchanged. Across the previously audited 100 seeds, the possible observed 62–95 range becomes 47–71. Existing companies receive the same scaling without rerolls; earned health growth is added back at full value. Wounded HP fractions and permanent identity are preserved. Other stat generation and growth rules await the next slice.

Only min/max damage, armour effectiveness, penetration and head chance change here. AP, fatigue, reach, accuracy, hands, load, prices and carried/ammunition rules are retained. All weapons have 25% head chance, except greatsword at 30%.

| Weapon | Old damage | New damage | Armour effectiveness | Penetration |
|---|---:|---:|---:|---:|
| Arming sword | 24–35 | 40–45 | 0.80× | 20% |
| Boar spear | 23–32 | 35–40 | 1.00× | 25% |
| Bearded axe | 32–45 | 40–60 | 1.30× | 30% |
| Ash longbow | 23–34 | 40–60 | 0.60× | 35% |
| Flanged mace | 25–35 | 35–50 | 1.10× | 40% |
| War hammer | 27–36 | 30–40 | 2.00× | 50% |
| Rondel dagger | 15–23 | 15–30 | 0.60× | 20% |
| Billhook | 30–42 | 55–75 | 1.30× | 30% |
| Light crossbow | 38–52 | 40–60 | 0.70× | 50% |
| Short sword | 18–27 | 22–32 | 0.70× | 20% |
| Falchion | 29–41 | 40–55 | 0.90× | 15% |
| Greatsword | 42–58 | 85–100 | 1.00× | 25% |
| Light militia spear | 17–25 | 25–30 | 0.90× | 25% |
| Heavy spear | 29–40 | 40–55 | 1.10× | 30% |
| Belt hatchet | 21–31 | 25–40 | 1.10× | 25% |
| Two-handed axe | 48–64 | 80–95 | 1.50× | 30% |
| Ironbound club | 18–27 | 25–35 | 0.80× | 30% |
| Two-handed maul | 38–51 | 55–75 | 2.50× | 40% |
| Belt knife | 10–17 | 10–20 | 0.40× | 20% |
| Long glaive | 39–53 | 70–90 | 1.10× | 30% |
| Hunting shortbow | 17–26 | 25–40 | 0.50× | 25% |
| Heavy warbow | 31–44 | 50–70 | 0.70× | 35% |
| Heavy crossbow | 49–67 | 50–70 | 0.75× | 60% |

## Armour capacities

| Component | Old maximum | New maximum |
|---|---:|---:|
| Riveted mail | 85 | 95 |
| Reinforced mail | 120 | 140 |
| Iron cap | 40 | 70 |
| Nasal helm | 60 | 110 |
| Short mail shirt | 62 | 70 |
| Long sleeved hauberk | 105 | 120 |
| Plain breastplate | 80 | 100 |
| Red brigandine | 68 | 80 |
| Bronze scale vest | 72 | 80 |
| Kettle helmet | 55 | 100 |
| Bascinet shell | 68 | 135 |

Other capacities, prices and load values are unchanged. Basic light body armour remains 77–100 depending on garment; mail with a gambeson is now 140. A maximal protective body assembly reaches 315; a fully assembled protective helmet reaches 199. Helmets remain a separate hit location. Broken gear retains its load.

## Role experiments and limits

The reproducible role experiment uses equal personal stats, a 400-crown gear ceiling, 20 seeds, both starting sides, two opponent armour kits and both adjacent/five-hex starts: 640 actual AI duels. Costs are not artificially made equal: light kit reserves 181 crowns, shield kit 81, maul kit 13 and archer kit 136. That money is reported but is not spent inside a duel. These fixtures have no supporting frontline, terrain, perks or progression. They do not establish optimal builds or human win rates. The full results are in [balance-role-results.json](balance-role-results.json).

Light equipment gives more stamina and earlier turns; heavier coverage and shields trade those away. Heavy weapons deal more damage per hit with larger action commitments. Archers need space and support; a lone archer facing a shielded opponent is a deliberately adverse matchup. The AI experiment exposed wasteful Shatter use against armour a normal maul hit already destroyed. It now chooses Shatter only when the expected additional wear is at least 25 points and half a normal blow’s armour wear, with no RNG consumed by planning.

Automated first-contract outcomes and native journeys are recorded in VALIDATION.md. Remaining balance work includes attribute growth, waiting penalties, fatigue from hits/misses, morale and dynamic perk trees. Perks and formation bonuses have not been calibrated to a finished economy.
