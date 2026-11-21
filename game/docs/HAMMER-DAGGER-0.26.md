# Hammer and dagger perks — 0.26

## Playable additions

Six new perks bring the catalogue to 68. All ten existing weapon families now have a personal group. Each mercenary still receives four weapon groups; no background, starting stat, talent or equipped weapon locks a group. A learned effect requires its matching equipment.

| Group / tier | Perk | Exact prototype behavior |
|---|---|---|
| Hammer / 3 | Smackdown | ×1.30 armour damage from hammer attacks, Shatter Armour and reactions. Includes the maul. No direct HP multiplier. |
| Hammer / 4 | Hammer Mastery | 25% less weapon fatigue through the shared rounding/cost pipeline. AP and accuracy unchanged. |
| Hammer / 6 | Deep Impact | Shatter Armour that deals HP damage weakens a surviving, fighting target: −10 attack accuracy and 20% less regular/armour damage through its next fresh activation. |
| Dagger / 1 | Between the Ribs | Paid dagger hits gain 10% HP damage per extra adjacent melee ally around the target, capped at 30%. Includes Puncture; armour damage is unchanged. Underdog prevents it. |
| Dagger / 4 | Dagger Mastery | 25% less weapon fatigue; includes knives. AP and accuracy unchanged. Puncture keeps its −20 accuracy. |
| Dagger / 7 | Swift Stabs | A paid dagger hit on a surviving, fighting target primes further dagger attacks against that target: 2 fewer AP, minimum 2. Stab becomes 2 AP; Puncture becomes 2 AP. |

Both groups work with a shield or free offhand. Double Grip and Duelist retain their equipment requirements and Puncture exceptions. No weapon damage, accuracy, ordinary AP cost, equipment value, stat or growth table was retuned.

Deep Impact refreshes without stacking. Armour-only hits and reactions cannot apply it. Its penalties also affect the weakened target’s reactions. An already-started Wait resumption does not consume the next fresh activation: the penalty lasts until the end of that next activation. It is a temporary combat effect, not an injury.

A Swift Stabs miss or kill clears the chain. Attacking a different target costs full AP; a successful hit can then prime that target. Movement, formation advance, changing an order marker, weapon switching, guard, Recover, active perks, Wait and ending the turn clear it. Reactions neither prime nor consume it. Both player and AI legality/payment use the selected target’s actual cost, including attacks with only two AP remaining.

Equipment comparisons include hammer armour damage and mastery fatigue. Battle action cards show target-specific AP costs; notes show the surrounding HP bonus, active dagger chain and weakened targets. Combat feedback continues to show total armour damage and HP lost.

## Source audit and adaptations

The audit uses the same pinned revisions as the earlier project audit, not a claim to port the latest mod releases. Primary source files were read directly. No mod artwork or scripts were copied into the game; these are original Godot implementations of explicitly adapted effects.

| Primary source | Audited behavior | Prototype decision |
|---|---|---|
| [Reforged Hammer group](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/mods/mod_reforged/perk_groups/pg_rf_hammer.nut) and [Dagger group](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/mods/mod_reforged/perk_groups/pg_rf_dagger.nut) | Hammer: Rattle/mastery/Deep Impact. Dagger: Between the Ribs/mastery/Swift Stabs. | Keep a small selection. Do not port projected-stat weighting or background restrictions. |
| [Legends weapon groups](https://github.com/Battle-Brothers-Legends/Legends-public/blob/9651d89bca426df9f2679cb79b6872f71c5ecdcb/mod_legends/config/z_perks_tree_weapons.nut) and [Smackdown](https://github.com/Battle-Brothers-Legends/Legends-public/blob/9651d89bca426df9f2679cb79b6872f71c5ecdcb/scripts/skills/perks/perk_legend_smackdown.nut) | Smackdown includes ×1.30 armour damage plus Wind Up/knockback effects. | Use only the armour multiplier, restricted to hammers; tooltip states the omission. |
| [Hammer mastery extension](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/mod_reforged/hooks/skills/perks/perk_mastery_hammer.nut) and [Dagger mastery extension](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/mod_reforged/hooks/skills/perks/perk_mastery_dagger.nut) | Hammer dents selected armour and adds Pummel. Dagger interacts with Reforged reach. | Retain the prototype’s shared 25% fatigue mastery convention; no new active skill, armour dent or reach system. |
| [Deep Impact perk](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/skills/perks/perk_rf_deep_impact.nut) and [action](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/skills/actives/rf_deep_impact_skill.nut) | Separate weapon-derived attack with HP-proportional skill/damage penalties, 25 fatigue and extra two-handed AP. | Apply fixed −10 accuracy/−20% damage to existing Shatter Armour after HP damage. Costs remain Shatter’s actual costs. Explicitly labelled adapted. |
| [Between the Ribs](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/skills/perks/perk_rf_between_the_ribs.nut) | Surrounding-based regular/direct damage modifiers with an immunity gate. | Paid dagger HP damage only, +10% per extra melee ally, capped at 30%; Underdog blocks. No reaction bonus. |
| [Swift Stabs](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/skills/perks/perk_rf_swift_stabs.nut) | Conditional hit-chain discount of 2 AP, floor 2, with expiry conditions. | Explicit per-target state and the action reset rules above; real player and AI costs share it. |
| [Rattle](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/skills/perks/perk_rf_rattle.nut) and [Rattled](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/skills/effects/rf_rattled_effect.nut) | −3 Reforged reach until turn end. | Deferred because that reach/effect system is absent. |
| [Hammer the Gap](https://github.com/Battle-Brothers-Legends/Legends-public/blob/9651d89bca426df9f2679cb79b6872f71c5ecdcb/scripts/skills/perks/perk_legend_hammer_the_gap.nut) and [Flux](https://github.com/Battle-Brothers-Legends/Legends-public/blob/9651d89bca426df9f2679cb79b6872f71c5ecdcb/scripts/skills/perks/perk_legend_flux.nut) | Source-specific repeated-tile/AOE accuracy and a Double Strike effect. | Not selected; avoid inventing substitute mechanics or duplicating existing Double Strike. |

In-battle injuries, Bone Breaker and injury-dependent perk expansions remain a later slice.

## Recruitment and saves

New personal pool version 5 draws four distinct weapon groups from Spear, Sword, Polearm, Bow, Crossbow, Throwing, Axe, Mace, Hammer and Dagger. A draw is repeated if it lacks either a melee or ranged route. Only group RNG is involved. Armour, style and character groups remain two each; the six shared fundamentals remain. Existing background weights stay 1 or 2. Hammer and Dagger have positive neutral weight for every background.

The 7,200-person generation sample has 34–42 unique options per person, with every group both present and absent within every background. Starting stats, stars and saved growth rolls remain independent. Equipment never rerolls a tree; any weapon remains usable without its group.

Start a new company to roll the expanded trees. Existing soldiers and all 30 already-generated weekly recruit offers retain their exact groups, pools and purchases. Old pool versions 1–4 remain supported. Campaign schema stays 21 with the 0.25 overworld and encounter state. Battle schema 19 adds the dagger target and Deep Impact expiry state; older ongoing encounters retain their original rules and state shape until completion. The next deployment uses current rules.

Three campaign fixtures were captured using the delivered 0.24 source before implementation. All original camp, partial encounter, completed encounter and aftermath fields match after loading/continuing in 0.26; the existing schema-21 spatial migration adds overworld state. Three delivered 0.25 spatial campaigns also retain exact serialized camp, route, contact, encounter and aftermath state, including continued travel and combat. Current live chain/debuff saves also roundtrip exactly; malformed state is rejected without changing the live company.

## Controlled combat evidence

First three eligible founders from distinct campaign seeds per weapon, requiring weapon + Shield + Swift groups only. No stat/star selection. Levels 3/6/11 use declared XP, saved gains, legal earned points and equal gear budget ceilings (actual spending differs). Paired shield/free-offhand careers. Authored 3v3 support/opponents, one fight seed (71), both controllers. Ablation removes only six new perks without reallocating points; it measures implementation impact, not equal-budget build balance.

The cohort contains five distinct people across six family entries, not 36 independent people. The same identity can qualify for both families. All saved growth choices are trained in the model careers, with health/skill/defence priorities; perk picks and equipment follow the actually rolled groups. Light armour uses Nimble and medium uses Poise. Gear spending ceilings are 400/600/800 at levels 3/6/11; actual spending is recorded.

| Weapon / offhand | New perks | Fights | Wins / losses / draws | Attacks | HP damage | Armour damage | Swift uses | Impact hits | Flank HP hits |
|---|---|---:|---|---:|---:|---:|---:|---:|---:|
| Hammer / free | Removed | 54 | 31 / 22 / 1 | 182 | 1723 | 8519 | 0 | 0 | 0 |
| Hammer / free | Enabled | 54 | 31 / 21 / 2 | 205 | 1995 | 9695 | 0 | 21 | 0 |
| Hammer / shield | Removed | 54 | 19 / 31 / 4 | 187 | 819 | 5752 | 0 | 0 | 0 |
| Hammer / shield | Enabled | 54 | 26 / 28 / 0 | 229 | 1250 | 7721 | 0 | 7 | 0 |
| Dagger / free | Removed | 54 | 18 / 33 / 3 | 818 | 938 | 4970 | 0 | 0 | 0 |
| Dagger / free | Enabled | 54 | 18 / 33 / 3 | 772 | 1041 | 5079 | 153 | 0 | 84 |
| Dagger / shield | Removed | 54 | 26 / 25 / 3 | 1012 | 1502 | 5290 | 0 | 0 | 0 |
| Dagger / shield | Enabled | 54 | 23 / 29 / 2 | 1194 | 1521 | 5999 | 176 | 0 | 112 |

Both controllers used the effects: 329 discounted dagger attacks, 28 Deep Impact applications and 196 flanking HP hits across the enabled runs. Every draw had an attack within the final two rounds. Losses and draws are retained; survival reporting includes living escapees.

This is an ablation: removed perks leave points unspent. It is not an equal-point comparison of optimized builds, a weapon ranking or proof of final balance. One fight seed, a small cohort and authored supporting fighters limit what the outcomes establish. No damage/accuracy buff was added to chase the observed win rates.

[Full profiles and outcomes](hammer-dagger-results.json) · [Generation sample](background-generation-results.json) · [Validation](VALIDATION.md)

![Hammer personal tree](hammer-dagger-hammer-tree.png)

![Dagger personal tree](hammer-dagger-dagger-tree.png)

![Hammer comparison includes mastery and Smackdown](hammer-dagger-hammer-comparison.png)

![Deep Impact target status](hammer-dagger-hammer-combat.png)

![Dagger follow-up costs](hammer-dagger-dagger-combat.png)
