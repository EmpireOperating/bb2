# Early-campaign balance review — 0.33

## Decision

Keep the existing combat stats, starting resources, prices, contract payouts and recovery rates for now. This pass validates the integrated opening; it does **not** make the game easier. No equipment ratings, readiness warnings, recommended minimum gear, level gates or party-size gates were added. Players judge their own equipment and matchups.

All runtime source/data files remain byte-identical to the delivered 0.33 integration. The package gains test drivers, raw results, this review and native screenshots. Existing saves and gameplay are unchanged.

## Ordinary companies, first ten days

Sixteen deterministic seeds (`1 + n × 197`, n = 0…15), each played with three policies: 48 runs. All begin with the normal three random founders, equipment, 300 crowns and supplies. Formation/reserves, living trade, roaming bands, farms, physical patrols and dungeons are enabled. Recruitment, travel, fights, voluntary retreat, upkeep, healing, repairs, training, purchases and sales use production APIs. No victory flags, injected equipment, money, health or XP.

| Policy | Survived through day 10 | Mercenary deaths | Hires | Median jobs won | Median crowns remaining |
|---|---:|---:|---:|---:|---:|
| Expand toward six; provision and recover | 15/16 | 17 | 47 | 3 | 126 |
| Keep four; buy mail with earnings | 15/16 | 9 | 21 | 3 | 156 |
| Keep three; no deliberate recovery or gear purchases | 11/16 | 22 | 0 | 2 | 680.5 |

Deaths include hired replacements, so raw casualty totals are not per-capita death probabilities. These policies bundle multiple choices; this is not an isolated causal experiment on armour or roster size. Every company that ended early did so through actual gameplay. Remaining money does not imply a surviving or successful company.

The four-person policy bought its first short mail with earned contract money in every run; median first purchase was day 2. The upgrade is one layer for one mercenary, not a full suit or a free starting loadout. One seed (1183) that wiped both other policies survived with the four-person policy. Hiring more bodies versus protecting fewer bodies is already a consequential spending choice. There is no evidence here for a blanket thug nerf or payout increase.

## World opportunities

Sixteen additional normal companies remained in their starting town for ten days, paying upkeep and buying food through normal methods. All sixteen had thug work available on days 1 and 3. Fourteen retained it on day 6 and nine on day 10; the world is allowed to resolve jobs while the company waits. We did not freeze patrols, make camps immune to NPCs, or manufacture replacement jobs for the player. Food and treasury ledgers remained balanced and standard starting funds covered this ten-day control.

## Native game check

A fresh native seed-1 company hired its fourth companion through town controls, accepted a real contract, travelled, fought and settled the encounter, returned to town, bought and fitted short mail using earned crowns, and saved/reloaded. Four survived; the trip finished on day 2. Purchase/fitting used production APIs; no resources or outcomes were injected. The screenshots show the actual resulting game.

## Limits

The drivers know map coordinates and use tactical AI, not human judgement. They sell unused loot and spend earned progression using fixed policies. Neither survival percentages nor passing checks certify human difficulty. Sixteen shared seeds are a focused regression cohort, not a population estimate. Dungeon clearing with early-game companies was deliberately not treated as a requirement; the prepared-expedition tests in the integration report remain the dungeon evidence. Midgame, late-game and full twelve-person difficulty are outside this pass.

Raw results: `early-baseline.json`, `early-holdout.json`, `early-gear.json`, `early-gear-holdout.json`, `early-world.json`. Test/log manifest: `early-validation.json` and `early-validation/`.

Reproduce with Godot 4.4.1:

```
godot --headless --path . --script res://tests/early_campaigns.gd -- baseline 0
godot --headless --path . --script res://tests/early_campaigns.gd -- holdout 8
godot --headless --path . --script res://tests/early_campaigns.gd -- gear 0 --gear
godot --headless --path . --script res://tests/early_campaigns.gd -- gear-holdout 8 --gear
godot --headless --path . --script res://tests/early_world.gd
godot --path . --script res://tests/early_journey_ui.gd
```

Native test requires an imported project, graphical display and fresh user-data directory.
