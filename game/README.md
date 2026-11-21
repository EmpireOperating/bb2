# The Ashen Company — Hollow Campaign Experiment

A separate experimental full-campaign integration. Original games, original saves and the other chat's development workspace are not development targets here.

## Launch this build

`/home/quatro/games/battle-brothers-2-hollow-campaign-experiment/launch-hollow-campaign-experiment.sh`

Use only this launcher. It selects the combined campaign scene and requires Godot `4.4.1.stable.official.49a5bc7b6`. Inherited launchers describe historical inputs, not supported alternative entrypoints for this namespace. Never run two writers against the same save directory.

## Playing with the new equipment

Start with the real three founders and normal supplies. Town recruitment, company formation, contracts, travel, markets and progression remain the existing campaign systems.

Open Company → Inventory. The nine main equipment rows and the separate carried reserves use actual owned items. In town, choose Town stock · Buy equipment to see finite offers and prices. Buying places the purchased physical item in the stash; select its slot and explicitly Equip it. There are no free showcase kits or automatic fitting.

Belts control carried capacity: two, three or four reserves. Occupied reserves prevent removing needed capacity. Switching a carried weapon in battle costs 4 AP and 0 fatigue. Tier 1 means the first/basic equipment tier; item and companion rarity are independent, identity-bound rolls, not a promotion to a higher equipment tier.

## Retained campaign and boundaries

This combines the accepted Burial Ruins campaign and Hollow equipment/rarity integration with the accepted Dungeon Maps delivery. It retains world travel/towns, ordinary paid recruitment, finite markets and loot rules, contracts, generated outdoor hex battles/fog, company formations/reserves and existing dungeon progression.

All nine existing dungeon sites now route through the accepted seeded tactical-map generator and deployment adapter. Seven tactical field IDs are supported; current stock sites assign six specialized field types. Generic `crypt` remains available in the original map preview and is tested as a prepared tactical field, not an invented seventh campaign destination. This merge does not redesign dungeon room/floor progression or add new sites. The accepted enemy-facing and matching alpha-picking fixes are included.

Stock equipment remains mechanically authentic. Some stock designs use disclosed visual proxies or have unpainted layers; undead appearance is not a new anatomical art set. Protective glove/boot/cloak/belt alternatives are retained, but campaign balance and complete catalog/art coverage are not certified.

## Independent saves

Origin: `ashen-company-hollow-campaign-experiment`.
Checkpoint: `user://hollow-campaign-camp.json`.

Current out-of-combat CAMP saves include admitted underground rooms. Battles and aftermath are not serialized: quitting during combat returns to the last saved CAMP state. No old-save migration is promised. Checkpoint failures block follow-up actions and show an error; retry saving before proceeding.

## Verification and evidence

The authoritative acceptance record, including frozen source identity, actual final test counts, review and native limits, is:
`/home/quatro/games/battle-brothers-2-hollow-campaign-evidence/delivery-acceptance.json`

Until that record exists and identifies this candidate, treat it as under final qualification. Earlier inherited verification files apply to their original builds, not this combined campaign. A headless passing record is not native visual/input acceptance; see its explicit native status.

Base manifest: `dd839d7359f849489dcba504edbc9fc2d0bc7ca7292287e80239232699147f80`.
Inventory donor: separately pinned tree `a5d392c26ef34b19d1db0265e581e89cbe1df3d3`.
Scope and all retained failures: `/home/quatro/games/battle-brothers-2-hollow-campaign-evidence/`.

Merge-specific source pins, regressions, review and preserved failures: `/home/quatro/games/battle-brothers-2-hollow-campaign-evidence/merge-dungeon-01/`. During qualification, its report is failure-default; the previous delivery record qualifies only its previous frozen candidate.

This is the unified experimental campaign candidate, not yet a native-playtested stable base. No source commit, public release, target-GPU performance claim or twenty-paid-hire/native full-company certification is implied.
