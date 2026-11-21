# Axe and mace perks — 0.24

## Playable additions

Five new perks bring the catalogue to 62. Each new weapon group offers three perks; Killing Frenzy already existed and is shared rather than duplicated. No weapon family, background, talent or stat is required to learn a perk offered by the personal tree. Equipment requirements determine whether a learned effect is active.

| Group / tier | Perk | Exact prototype behavior |
|---|---|---|
| Axe / 2 | Smashing Shields | Split Shield: 36 condition, or 18 versus Shield Expert; no HP damage. |
| Axe / 4 | Axe Mastery | 25% less axe attack/special fatigue, rounded by the shared cost pipeline. AP and accuracy unchanged. |
| Axe / 7 | Killing Frenzy (existing) | A paid attack kill grants +20% regular/armour damage through the next own activation. Existing timing/stacking rules unchanged. |
| Mace / 2 | Concussive Strikes | A paid, damaging mace head hit staggers a surviving enemy. No reaction trigger. |
| Mace / 4 | Mace Mastery | 25% less mace attack/special fatigue. Staggering Blow retains its −10 accuracy and current AP cost. |
| Mace / 5 | Push the Advantage | Against an already-staggered target, paid mace attacks gain 10 percentage points of head-hit chance and 10% head HP damage. Body damage unchanged. |

Both shield and free-offhand builds use these perks. Double Grip and Duelist retain their independent equipment requirements. Melee axes, including the greataxe, use Axe; throwing axes use Throwing. Current mace weapons are the club and flanged mace; the maul is a hammer. No hammer/dagger tree was added.

Stagger removes two current AP and two AP at the next activation, then clears. Resuming Wait does not consume or duplicate the pending penalty. Repeated stagger does not stack; Indomitable blocks it. The hit that first staggers cannot benefit from Push the Advantage. The two mace triggers use shared production damage/action rules on both controllers. AI recognizes actual shield-break thresholds, including Shield Expert, and avoids trying to stagger an Indomitable target.

Weapon comparison costs include mastery. Axe action descriptions show actual shield damage; the target panel reports whether the mace advantage is active. Combat feedback continues to show total armour/HP loss.

## Source audit and explicit adaptations

Audited source snapshots are pinned to the revisions already used by this project; this is not a claim to port the latest mod release. No mod artwork or scripts were copied into the game. The Godot effects are original implementations adapted to the prototype.

| Primary source | Audited behavior | Decision |
|---|---|---|
| [Legends weapon groups](https://github.com/Battle-Brothers-Legends/Legends-public/blob/9651d89bca426df9f2679cb79b6872f71c5ecdcb/mod_legends/config/z_perks_tree_weapons.nut) | Axe includes Smashing Shields, mastery and Killing Frenzy; Mace includes mastery and Push the Advantage. | Use a small cross-mod selection; retain our existing Killing Frenzy values. |
| [Smashing Shields](https://github.com/Battle-Brothers-Legends/Legends-public/blob/9651d89bca426df9f2679cb79b6872f71c5ecdcb/scripts/skills/perks/perk_legend_smashing_shields.nut) | Modifier 1.50. | Apply ×1.50 to our fixed 24-condition axe shield hit; Shield Expert halves afterward. |
| [Reforged Axe group](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/mods/mod_reforged/perk_groups/pg_rf_axe.nut) and [mastery extension](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/mod_reforged/hooks/skills/perks/perk_mastery_axe.nut) | Dismantle/mastery/Dismemberment; mastery adds Bearded Blade and Hook Shield. | Keep the familiar 25% fatigue mastery only. Hook actions and Reforged reach are absent. |
| [Reforged Mace group](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/mods/mod_reforged/perk_groups/pg_rf_mace.nut) and [mastery extension](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/mod_reforged/hooks/skills/perks/perk_mastery_mace.nut) | Concussive Strikes/mastery/Bone Breaker; mastery adds Bear Down. | Keep fatigue mastery without Bear Down or a stun guarantee. |
| [Concussive Strikes](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/skills/perks/perk_rf_concussive_strikes.nut) | Mace head hits use daze/stun, with different one-/two-handed behavior. | Use the existing two-AP stagger, require actual damage, exclude reactions and prevent stacking. The tooltip explicitly says this is not stun/daze. |
| [Push the Advantage](https://github.com/Battle-Brothers-Legends/Legends-public/blob/9651d89bca426df9f2679cb79b6872f71c5ecdcb/scripts/skills/perks/perk_legend_push_the_advantage.nut) | Head chance and head damage bonuses depend on multiple injury/status groups, including Staggered. | Implement the +10 branch against our stagger state only, restricted to paid mace attacks. No synthetic injuries/statuses. |
| [Dismantle](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/skills/perks/perk_rf_dismantle.nut), [Dismemberment](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/skills/perks/perk_rf_dismemberment.nut), [Bone Breaker](https://github.com/Battle-Modders/mod-reforged/blob/ae90bbfbd05aa0e767e37d658f17e3b57ea2273e/scripts/skills/perks/perk_rf_bone_breaker.nut) | Accumulating debuffs and injury-dependent effects. | Deferred: the prototype does not have the corresponding in-combat injury/effect system. |
| [Legends Onslaught](https://github.com/Battle-Brothers-Legends/Legends-public/blob/9651d89bca426df9f2679cb79b6872f71c5ecdcb/scripts/skills/perks/perk_legend_onslaught.nut) | Armour-based melee damage and Baffled application. | Deferred rather than inventing a replacement for Baffled. |

## Recruitment and save compatibility

New personal trees use pool version 4: four weighted distinct weapon groups from Spear, Sword, Polearm, Bow, Crossbow, Throwing, Axe and Mace. A weapon-group draw is repeated if it lacks either melee or ranged options; only group RNG is involved. Armour/style/character draws remain two groups each. Background preferences remain bounded at weights 1 or 2; Axe and Mace have positive neutral weight for every background. Stats, stars and equipment do not choose or reroll the tree.

The 7,200-person generation test found 34–42 distinct options per person and many trees in each background, with every group present and absent in each background. Exact identity, stat, star and saved growth rolls remain unchanged from the earlier generation baseline. Old personal pool versions 1–3 retain their exact lists. All existing recruit offers are already saved, including future weeks, so a new company is needed to see expanded trees.

Campaign schema stays 20; personal pool version 4 is validated alongside old versions. Battle schema 18 enables the new behavior. Previously saved ongoing encounters retain schemas 14–17 and their original rules until completion. Three baseline campaigns were captured by the actually delivered 0.23 code: camp state, partial encounter, final encounter and aftermath all match exactly after importing and continuing. Current mid-battle state also roundtrips exactly.

## Controlled combat evidence

First three eligible founders from distinct campaign seeds per weapon, requiring weapon + Shield + Swift groups only. No stat/star selection. Levels 3/6/11 use declared XP, saved gains, legal earned points and equal gear budget ceilings (actual spending differs). Paired shield/free-offhand careers. Authored 3v3 support/opponents, one fight seed (71), both controllers. Ablation removes only five new perks without reallocating points; it measures implementation impact, not equal-budget build balance.

Defensive picks follow the armour actually selected: light uses Nimble and medium uses Poise; the fixture does not spend a second point on a redundant major armour reduction. This is six generated people, not 36 independent people. Offhand alternatives have the same natural starting identities but different legal perk/gear choices.

| Weapon / offhand | New perks | Fights | Wins / losses / draws | Attack attempts | Shield condition lost | Concussive staggers | Advantage head hits |
|---|---|---:|---|---:|---:|---:|---:|
| Axe / free | Removed | 54 | 29 / 23 / 2 | 237 | 47 | 0 | 0 |
| Axe / free | Enabled | 54 | 30 / 21 / 3 | 249 | 54 | 0 | 0 |
| Axe / shield | Removed | 54 | 25 / 24 / 5 | 285 | 72 | 0 | 0 |
| Axe / shield | Enabled | 54 | 24 / 25 / 5 | 322 | 196 | 0 | 0 |
| Mace / free | Removed | 54 | 24 / 27 / 3 | 360 | 84 | 0 | 0 |
| Mace / free | Enabled | 54 | 27 / 25 / 2 | 404 | 99 | 10 | 3 |
| Mace / shield | Removed | 54 | 22 / 29 / 3 | 403 | 99 | 0 | 0 |
| Mace / shield | Enabled | 54 | 23 / 27 / 4 | 433 | 116 | 10 | 2 |

The table is an ablation, not a claim that any weapon/offhand is stronger. Removing perks leaves their points unspent. Shield-condition measurement includes ordinary shield-block wear as well as Split Shield. Both hand setups actually triggered the added effects. All draws had an attack within the final two rounds; there were no prolonged idle endings in this sample. Remaining draws and losses are retained. No automatic damage/accuracy rebalance was made in response to these small win-rate differences.

[Full profiles and outcomes](axe-mace-results.json) · [Generation sample](background-generation-v0.24.json) · [Validation](VALIDATION-v0.24.md)

![Axe personal tree](axe-mace-axe-tree.png)

![Mace personal tree](axe-mace-mace-tree.png)

![Mace target advantage](axe-mace-mace-combat.png)
