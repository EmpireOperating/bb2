# First-month playability audit — 0.44

Thirty-six campaigns completed: three policies × six seeds × two versions. Each starts with the ordinary three mercenaries and 300 crowns. No resources, visibility, teleports, victories or contracts are manufactured. Runs end after day 30 or an actual company loss.

## Results

| Policy | 0.43 survivors | 0.44 survivors | Median crowns among 0.44 survivors |
|---|---:|---:|---:|
| Mercenary | 2/6 | 2/6 | 502 |
| Trader | 4/6 | 4/6 | 51.5 |
| Mixed | 5/6 | 4/6 | 453 |

These are deterministic policy outcomes on six maps per mode, not human win rates or a statistically established balance effect. Different travel times change encounters and economic conditions, so money and survival can improve or worsen on an individual seed.

There were **0 navigation aborts** in the final paired runs. The surviving companies' visits, earnings, casualties and costs are recorded per seed. The direct endings after the fix were: **combat: scout: 7; combat: clear: 1**. A combat ending does not prove the economy is generous: casualties, recruitment and low reserves can contribute to later defeats.

## Confirmed defect and fix

Directions previously kept their first origin forever. If you first heard about a destination in Stonewick, subsequently asking locals in another town still gave the Stonewick instructions. The policy could therefore walk back across the region before following an otherwise valid clue.

`RegionalNews.hear` now updates the origin and hearing time for destinations actually mentioned by the current locals. Simply arriving, opening the journal or reading directions does not change anything. Other destinations retain their previous notes. Old foreign reports keep their observation date, source and stale status. Bookmarks remain attached to their destination and survive save/load.

A concrete matched example is trader seed 71: its first journey to East Mossfall took **141.25 hours before** and **22.65 hours after**. Previously the instructions sent it back through Redfall; the new local directions began in East Ravenmere. The old trader died on day 14; the new one survived the month. This is one reproducible example, not a general survival guarantee.

The reproducer has two expected failures against the original code and passes all nine checks after the fix. Its original failure log is retained and explicitly named as expected. No wages, food prices, payout amounts, starting kit, combat values or enemy strength were changed.

## Information boundary

The navigator receives a data-only view of explored terrain, displayed road segments, sighted place markers, visible named landmarks and the journal's literal text. It has no Campaign object and cannot call the complete road graph or the former search-area helper. It parses the actual compass and landmark names, explores the visible road frontier, and orders travel to observed terrain. The production engine still resolves all movement, discovery, interception and costs.

Only already-sighted places and signed-contract markers permit exact targets. Contract destinations are the same markers the existing game exposes. Unknown town coordinates and current remote prices are unavailable to the policy. Market observations are sampled only after physically arriving in town; earlier quotes remain frozen and can be wrong by the time a trader returns. Isolation tests poison hidden foreign prices and enemy strength and verify that local observations and navigation choices remain unchanged.

The policies know game rules and use the existing tactical AI. They do not know future events or RNG. Reading current local job descriptions, company equipment, health and market quotes is permitted. Full snapshots and accounting are used for verification and reporting, not to choose destinations or trades.

## Policy and limitations

- Mercenaries seek manageable posted work and aim to maintain four people. Traders accept no contracts and aim for three people. Mixed companies prefer manageable local work, then trade and explore.
- Supplies, repairs, gear and recruitment use ordinary paid commands. The shared spending policy keeps an operating reserve. Healing and repairs occur on the production clock.
- Traders use remembered destination quotes for up to seven days. For an unvisited market they can make a small speculative purchase of locally abundant goods. They receive no guaranteed margins or sale prices.
- All three use the same existing tactical AI and retreat rule. They fight when intercepted; they do not model a skilled human's map-level scout avoidance. Voluntary fight selection also remains a fixed heuristic. Combat-heavy losses therefore identify a risk area, not a proof that the enemies require a nerf.
- `no_job_visits` counts policy visits without a selected suitable job, including rejection for readiness; it is not a count of empty world contract boards. Low-food/debt observations are samples, not a complete day-by-day starvation diagnosis.
- Pilot results were excluded after correcting two driver errors: an arbitrary two-day travel cutoff and frontier detection that omitted diagonal road continuations. The final before/after matrix uses identical corrected policy files; hashes are in `protocol.json`.

The next useful combat investigation is to compare a policy that avoids visible scouts and declines badly prepared fights against these fixed policies, before changing enemy strength or income. This release establishes a reproducible first-month test and fixes the demonstrated direction defect; it does not declare the early game balanced.

## Individual outcomes

| Policy | Seed | Before | After | Living after | Crowns after | Towns visited after |
|---|---:|---|---|---:|---:|---:|
| mercenary | 1 | Survived | Survived | 4 | 551 | 6 |
| mercenary | 71 | Lost day 6 | Lost day 6 | 0 | 51 | 2 |
| mercenary | 198 | Lost day 6 | Lost day 6 | 0 | 87 | 3 |
| mercenary | 395 | Lost day 3 | Lost day 3 | 0 | 58 | 2 |
| mercenary | 592 | Survived | Survived | 4 | 453 | 6 |
| mercenary | 789 | Lost day 6 | Lost day 6 | 0 | 70 | 3 |
| trader | 1 | Survived | Survived | 3 | 51 | 6 |
| trader | 71 | Lost day 14 | Survived | 3 | 78 | 6 |
| trader | 198 | Lost day 5 | Lost day 5 | 0 | 130 | 3 |
| trader | 395 | Survived | Survived | 3 | 51 | 6 |
| trader | 592 | Survived | Survived | 3 | 52 | 6 |
| trader | 789 | Survived | Lost day 23 | 0 | 31 | 6 |
| mixed | 1 | Survived | Survived | 4 | 253 | 6 |
| mixed | 71 | Survived | Survived | 4 | 698 | 6 |
| mixed | 198 | Survived | Lost day 8 | 0 | 73 | 3 |
| mixed | 395 | Survived | Survived | 4 | 258 | 6 |
| mixed | 592 | Survived | Survived | 4 | 648 | 6 |
| mixed | 789 | Lost day 9 | Lost day 9 | 0 | 236 | 4 |

## Validation and replay

Every campaign reconciles its final crowns with contracts, salvage, trade, wages, gear, supplies and recruitment, checks world/council accounting, and restores earned saves. All final campaign assertions passed. **1331 regression and native-UI checks passed**, including legacy save restoration, unchanged report ages, no changes to fog/economy from asking, and F5/F9 persistence.

The native UI test loads the unmodified earned Briarmere arrival from 0.43, opens the old Redfall directions, asks the current locals, confirms the new origin, bookmarks it and saves/loads. It uses real mouse/keyboard input and rendered Godot screens.

```sh
godot --headless --path . --script res://tests/first_month.gd -- mercenary 71 replay
godot --headless --path . --script res://tests/first_month.gd -- trader 71 replay
godot --headless --path . --script res://tests/first_month.gd -- mixed 71 replay
godot --headless --path . --script res://tests/player_knowledge.gd
godot --headless --path . --script res://tests/local_directions.gd
```

Repeat with seeds 1, 71, 198, 395, 592 and 789 for the matrix. For a before-version comparison, use a separate extracted project copy and replace only `src/regional_news.gd` with `docs/first-month-0.44/regional_news_v043.gd`. The full policy, seeds and production-file hashes are recorded in `protocol.json`. Native UI reproduction uses `tests/first_month_ui.gd` with a graphical display and an isolated save directory.

Raw reports, decisions, trades, journeys, end saves and checkpoints are in `first-month-0.44/before/` and `after/`. `paired-summary.json` and `verification.json` hold machine-readable totals. Historical pilot runs are excluded from this deliverable's results.

## Native screenshots

![Old directions from the previous town](first-month-0.44/before-local-directions.png)

![Directions after asking the current locals](first-month-0.44/after-local-directions.png)

## Scope

Based on the saved 0.43 main prototype. Other chats' separate raider, dungeon and other integration packs were not silently merged. Save wrapper and news schema are unchanged; existing companies adopt the new behavior on their next actual local inquiry.
