# Living camps and named camp loot

Isolated branch `world/camp-lifecycle`, based on the completed hinterlands commit `3b614c572435dfb5e946d24f9c857a4214f39124`. This is a separate integration slice, not a replacement for the other chats' balance, progression, perk or dungeon work. Start a new company in this preview to enable it. Existing saves retain their saved rules.

## Camp lifecycle

An occupied camp gathers up to six food per day, stopping local gathering at sixty stored food. A nearby paid, effective council patrol can deny this gathering. Foraging is an abstract camp-resident activity; there are no new visible forager parties in this slice. Every gathered unit enters the existing world production ledger. Stolen supplies, ordinary camp upkeep, garrison growth and funded reoccupation continue through the existing systems.

Camps pay eight food for each recruit, then train the batch for two days. Paid trainees become reserves. They can fill a missing slot only when its surviving field party is physically home and not engaged. A fully defeated party is replaced with a new party ID, assembled at the camp, using the required number of trained reserves. Only one field party per camp is active at a time. The older party remains defeated in the save. New recruits receive new member identities; their predecessors remain in the fallen list.

Wounded survivors require one food per wounded member per day for care at home. Care cannot revive a dead member. Returning and training behavior uses the existing paths, retreat priorities and patrol system. Replacement parties can roam, hunt, flee, raid caravans and raid their own farm through the existing behavior. Farm security now consults the latest party rather than the original party forever.

Destroying a camp stops its foraging, recruitment and dispatch. Paid training on an archived destroyed occupation does not complete. Reoccupation keeps the existing minimum quiet interval and requires a funded mature neighboring camp. It creates a new occupation and a new initial party. Replacing a defeated field party never increments the occupation generation.

## Named equipment

Each camp occupation receives a hidden, deterministic reward roll when founded. Initial chances are **15%, 25%, and 35%** for founding strengths 1, 2, and 3. These are our prototype starting values, not a claim about Battle Brothers' exact formula. The higher-strength pool contains stronger equipment definitions. A later strength increase, contract acceptance, waiting or reload cannot reroll the reward. A genuinely reoccupied site receives a new occupation-specific roll.

The saved promise includes the definition, name, source, bonuses and item condition. The existing named-equipment system supplies nonmagical craftsmanship bonuses. Ordinary shared equipment definitions stay untouched. Direct camp victory and successful camp-clear contracts award the item once, place it in inventory, and put it first in the loot list with gold lettering and a bonus summary. Scout victories, retreats and non-company clearance do not award it. The generic treasure claim API cannot bypass camp victory. Discarding or selling a claimed item does not reset the entitlement.

The camp panel exposes visible stores and training, and mentions the possibility of named equipment. It does not reveal the rolled outcome. Distant camp panels do not reveal current recruitment activity.

## Integration points

- `campaign.gd`: final optional tenth `setup` argument `renewing_camps=false`; component creation, daily hook after guards receive wages, victory reward settlement, snapshot/restore. The wrapper remains version 31.
- `camp_life.gd`: lifecycle, deterministic reward rolls, ledgers and strict transactional save validation; component version 1.
- `overworld.gd`: component version 2 when enabled; replacement IDs `site_generation_rN`, with earlier snapshots retaining version 1.
- `bandits.gd`: component version 3 adds member identities, fallen history and paid care. Versions 1/2 retain their previous behavior.
- `farmstead.gd`: latest live party lookup for local raid/security checks.
- `main.gd` and `bandit_view.gd`: enable fresh preview companies, visible camp activity and named loot presentation. Choose the release title/save path at integration; the preview uses `ashen-company-camp-life-preview.json`.

No tactical combat formulas, stat growth, perks, item catalog, named-item generation or dungeon content were changed. Later main archive version 37 and the other chats' work were not merged into this branch. Preserve them when resolving shared-file conflicts. Old saves are compatible; they do not silently gain the new camp lifecycle or retroactive camp loot rolls.

## Validation

**4,217 checks across 15 suites, zero failures**, including repeated assertions. See `CAMP-LIFE-VALIDATION.json` and packaged logs for exact totals. Clean Godot import also passes.

Coverage includes 64 seeded fresh campaigns and exact JSON roundtrips; paid partial/full recruitment; delayed assembly; persistent dead identities; farm access for replacement parties; care accounting; destruction during training; reoccupation; corruption rejection without partial mutation; camp, contract, scout, loss and repeat-claim reward paths; dungeon/world clocks; and the previous farm, guard, caravan, named-item and legacy campaign suites.

Six thirty-day observer runs use seeds 1, 7, 198, 7391, 42 and 999999999, injecting only company cash/rations to keep the observer alive. They naturally dispatched **47 replacement parties** and recorded replacement-party caravan attacks while all food and council balances held. They recorded no replacement-party farm raids in those guarded runs; the isolated farm-position scenario verifies that route. These runs demonstrate lifecycle behavior, not final combat difficulty.

The native UI test uses a declared company-position fixture at the camp on seed 27, with the ordinary three founders, starting gear and legal tactical AI. Victory recovers **Torsten's Boar spear**, +14% damage and -1 action fatigue. F5/F9 preserves the hidden promise, battle aftermath, inventory and destroyed camp. A second ordinary start on seed 1 naturally reaches camp training on day six; a position fixture then inspects it and verifies F5/F9. The screenshots show assault, victory, named loot, clearance and training. Contract/no-drop/scout model settlement tests declare outcome fixtures separately from the legal direct camp battle.
