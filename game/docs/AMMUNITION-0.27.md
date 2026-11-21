# Company ammunition — 0.27

Integrated onto delivered Godot 0.26, preserving its free-roaming overworld, scouts, encounter/route state and all ten weapon perk groups. The original ammo pack was developed against 0.25; its changed files were reconciled onto the newer source, not used as a replacement project. This is the Godot source project, not a browser rebuild.

## Player behavior

- Company reserve starts at 60. Region map and armory display it; towns sell 30 supplies for a base 30 crowns with existing reputation adjustment.
- Arrows and bolts cost 1 supply each; javelins, throwing axes and bolas cost 3 each. Existing physical capacities remain 12 arrows, 8 bolts and 5 thrown weapons per bundle.
- Paid attacks consume one round on hit or miss. Reload consumes no additional bolt. Empty attacks refuse without AP, fatigue or RNG changes. Combat panels show remaining/capacity.
- After any battle, surviving soldiers refill equipped ammunition and main/carried throwing bundles. Each pass adds one round per item in roster order; slots are ammo, weapon, carry1, carry2. Unaffordable items are skipped so cheaper rounds can still use the remainder. Supplies never go negative; 1–2 supplies cannot produce a thrown weapon.
- Purchasing supplies triggers the same refill. The individual armory button also allows partial refills outside combat, including wilderness camps. Tools cannot repair ammunition. Loose stores and fallen soldiers are excluded.
- Victory converts killed enemies' remaining rounds to supplies, at the same 1/3 rates, before replenishment. Recovered packs/bundles are emptied; this prevents selling or equipping a duplicate of those rounds. Routed enemies keep equipment. Defeats and retreats yield no salvage.
- Aftermath shows looted, spent, reserve and missing supply. Company planning flags refill needs. Settlement remains idempotent, including after Save/Load.

## Bolas

Bolas did not exist in 0.24. This pass adds a five-use, one-handed throwing bundle with the existing Quick/Heavy Throw actions, throwing perks, carried-item behavior and a simple rope/weights drawing. Its initial damage is 15–25, 10% penetration and 50% armour damage. No entanglement, immobilization or recovery-from-target mechanic is implemented. Those would require a separate weapon design/balance pass.

New companies have a bundle in stores. Newly generated markets sell one for a base 55 crowns. The new market flag preserves the exact stock/ledger of existing weekly markets. Founder/recruit generation does not change.

## Save compatibility

Campaign schema 22 adds `ammunition` and `ammo_pending`; battle schema remains 19. Existing current combat counters already belong to physical item conditions, so no redundant per-soldier ammo field is introduced.

A pre-0.27 company gets its 60-supply reserve once during migration. Existing camp item counts remain exact; the player can refill using supplies. A saved battle or aftermath defers the new loot/refill settlement until return to camp. Current Save/Load preserves zero reserves, partial bundles, loaded crossbows, RNG and migration state exactly. Bad supply fields are rejected atomically.

Three 0.24 and three 0.25 fixture campaigns were captured by running their original delivered archives. Three existing 0.23 fixtures are retained. Three additional 0.26 careers were captured from the delivered build with actual paid Swift Stabs or Deep Impact active. Their saved trees, live perk states, commands, RNG, casualties and settlement survive migration exactly until the documented camp refill. Tests compare historical commands/RNG/casualties and exact settlement before the new camp refill. A captured 0.25 mid-route save verifies that migration preserves every spatial/campaign field and continues with identical movement and economy. Current JSON roundtrips use full precision, as required by the overworld.

## Validation

See [current validation](VALIDATION.md). No claim of final ammunition-economy or bolas balance: reserve size, purchase price, bundle price and basic bolas damage are initial prototype tuning. No executable export is included.

![Company ammunition and town purchase](ammunition-world.png)

![Whole-round partial refill](ammunition-partial.png)

![Combat remaining/capacity](ammunition-bolas.png)

![Aftermath supply report](ammunition-aftermath.png)
