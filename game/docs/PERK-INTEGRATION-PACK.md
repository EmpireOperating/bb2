> Historical integration-pack notes, based on 0.16. For the merged 0.18 release use [current perk notes](PERKS-0.18.md) and [current validation](VALIDATION.md).

# Perks ↔ progression integration

This pack owns perk definitions, access pools, purchase validation, Gifted choices and combat effects. The parallel progression project owns XP, level thresholds, point awards, talents and ordinary attribute growth. Do not replace the progression project's files with this preview wholesale.

Base: `Battle-Brothers-2-Prototype-0.16.zip`, Library version 19. The pack is an independent work product. The patch is relative to that base; apply or reconcile it in a separate checkout before merging with the current progression build.

## Interface

| Data/API | Owner and meaning |
| --- | --- |
| `soldier.perk_points_earned: int` | Progression supplies cumulative lifetime earned points, 0–10. Never store remaining points here. |
| `PerkProgression.earned(s)` | The only point-provider adapter. Uses the above field; temporarily falls back to `Progression.level(s)-1` for the existing prototype. |
| `PerkProgression.available(s)` | Earned total minus the number of chosen perks. No XP or awards are changed. |
| `soldier.perks: Array[String]` | Purchased IDs in purchase order. One point each; duplicates disallowed. |
| `Perks.learn_reason(s, id, earned_points)` | Pure validation: pool membership, unspent award, tier, duplication, unfinished Gifted choices. Tier N needs N−1 previous purchases anywhere. |
| `Campaign.learn_perk(id, perk)` | Performs a validated camp purchase, records it and applies Colossus's current-HP adjustment. |
| `Campaign.choose_gift(id, attr)` | Adds exactly one fixed Gifted gain per distinct choice, max three. No XP, level or additional point award. |
| `Perks.initialize(person)` | Generates a pool once from the saved identity seed, using its own RNG; repeated calls preserve it. No population or battle RNG is consumed. |
| `perk_version`, `perk_groups`, `perk_pool` | Saved pool schema and actual access list. Copy from offer to hired soldier; do not reroll from current stats, equipment or a new seed. |
| `gifted_choices` | Purchased Gifted attributes. Their gains are already in permanent base stats. Never reapply on load. |
| `battle_unit.perk_state` | Saved combat triggers and allowances; not part of career progression. Reset on deployment, not on save/load. |

Recommended integration: implement `Progression.earned_perk_points(s)` in the progression project, then have `PerkProgression.earned` call it. Alternatively persist the cumulative `perk_points_earned` field when progression awards a point. At level eleven the agreed total is ten. Do not both increment an available-points counter and subtract `perks.size()` again.

The legacy validation adapter currently checks non-perk service records through `Progression.validate` on a temporary copy with empty perks, then validates the real purchases with the new catalogue and point budget. When integrating the new progression validator, separate its career validation from perk-ID validation or delegate perk validation directly. The current adapter must not bypass the new progression project's award ledger.

Gifted writes the existing eight permanent-stat fields via `People.FIELDS`. Preserve those gains in the new growth ledger if it reconstructs stats. Colossus and Fortified Mind are derived multipliers, not changes to base HP/Resolve. Brawny/Perfect Fit likewise modify derived equipment penalties and must not rewrite item weight. Avoid duplicate application in a new stat system.

## Files to reconcile

| File | Purpose |
| --- | --- |
| `src/perks.gd`, `data/perks.json` | Catalogue, groups, pool construction, shared arithmetic and state schema. |
| `src/perk_progression.gd` | Small progression adapter. |
| `src/battle.gd` | New-rules flag, action costs, damage/defence hooks, active commands, triggers and persistence. |
| `src/campaign.gd` | Offer/hire pool copying, purchase/Gifted commands, derived HP, deployment and migration. No XP thresholds or ordinary growth changes. |
| `src/people.gd` | Only the new Perks preload and derived armour-load calculation. Preserve the other chat's growth and talent work. |
| `src/main.gd` | Tree, pre-hire preview, Gifted choices, active-perk controls and derived-stat display. |
| `src/legacy_*_v16.gd` | Frozen 0.16 campaign/battle/people/progression readers for pending old encounters. Existing production progression is untouched. |
| `src/perk_trials.gd`, `data/perk_trials.json`, `src/perk_sandbox.tscn` | Test/demo fixtures only. Never use their supplied final stats or ten-point overrides as campaign progression. |
| `project.godot` | Preview-only startup/name changes. Keep the production project's identity/start scene when integrating. |

`integration/perks-0.16.patch` contains the source delta, tests, catalogue and demo setup. `integration/base-manifest.json` records the original and changed file hashes for conflict detection. The full runnable preview is alongside the patch for review.

## Persistence and old fights

The preview uses campaign schema 16 and battle schema 13. Coordinate these numbers with the other project before merge; they are not a claim on production schema numbers. Preserve every new state field in the merged save validator and serializer.

Old battles/aftermaths finish under their previous rules. On return to camp, eligible living melee soldiers get a saved pool and placeholder picks are refunded; XP and base stats are retained. Existing ranged soldiers retain their placeholder choices. Imported camp saves adopt immediately. Fallen records retain old perks. Battle migration never adds new triggers part-way through a fight.

The new-rules flag also enables the roster's proposed weapon roles: one-handed spears/swords 4 AP and range one, polearms range one–two with −15 adjacent accuracy before mastery, and no greatsword Riposte. Universal Recover costs 9 AP. These are scoped to new perk battles; reconcile with any later combat work.

## Remaining release gate

This starter validates the three authored recruits and all 54 access-pool combinations structurally. It does not yet certify generated-stat build viability. Before general recruitment rollout, validate two complete distinct routes plus a credible alternate against the new progression system's attainable stats and actual equipment. Add ranged groups before converting ranged recruits. Background-weighted group selection is a later extension; this initial generator samples groups uniformly.

Native UI tests: `tests/perks_ui.gd`. Rules: `tests/perks.gd`, `tests/perk_timing.gd`. Fixture persistence: `tests/perk_lab.gd`. Matched scenarios: `tests/perk_trials.gd`. Keep both the progression project's tests and these perk tests in the final merge.
