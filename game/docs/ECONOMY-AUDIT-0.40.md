# Early economy audit — 0.40

This release adds reproducible balance tests and their evidence. Production economy and combat rules remain those of 0.39. The only production-source edit is the displayed release number. No prices, wages, pay, enemies, starting resources, saves, fog rules or production rates were changed.

## Result

Eight identical seeds were tested under three distinct policies, followed by a recruitment-growth control. Each begins with the real three-person, 300-crown start and runs to a decision after day 45 or a real ending. A long journey can finish on day 46–47. Survival requires no ending and no wage arrears.

| Policy | Survived | Wage disbandings | Wipes |
|---|---:|---:|---:|
| Mercenary, four-person target | 0/8 | 5 | 3 |
| Trader, three-person target | 8/8 | 0 | 0 |
| Mixed, four-person target | 6/8 | 1 | 1 |
| Mercenary, up to six after first paid win | 0/8 | 7 | 1 |

These are outcomes for specified automated policies, not human win rates. Eight seeds do not establish final balance. The poor combat-only results warrant further work, but do not prove that all combat-only play is impossible.

## What the audit found

- The previous 0.39 hybrid driver spent operating/trading cash on upgrades, cleared unsold-cargo tracking, could wait for 85% armour while out of repair tools, and admitted veteran fights with four mercenaries. Its one survivor out of four was not a reliable measure of the economy alone.
- The audited trader and mixed policies retain five days of wages and provision/repair replenishment, plus a separate reserve before optional gear purchases. They compare marginal prices across a whole load, the buyer’s actual funds and travel upkeep; they discount estimated sale receipts by 10% for competition. They relocate to another producer when a viable empty-leg-plus-loaded-trip opportunity exists.
- Every crown reconciles, including contract payments, stolen cash, equipment sales, commodity purchases/sales, wages, supply purchases, equipment and recruitment. Unsold cargo remains an asset; its cost stays in the cash margin, not an invented profit. Repairs and healing happen through normal elapsed time, consuming real tools/medicine.
- Trading can finance progression under current rules. Mixed companies can also survive and upgrade while fighting. There is no evidence here for a blanket reward increase or lower wages.
- Five compact mercenary runs exhausted their cash after both easier camps had been cleared and the veteran ridge camp remained. Three were wiped out. In the growth control, seven disbanded and one was wiped out. Larger hiring permissions did not resolve the problem under this policy: the companies generally afforded five, not six, and their ongoing wages rose.
- The region contains only three towns and three principal camps. Clearing threats removes those jobs, and secure roads correctly stop advertising unneeded escorts. An expanded region and additional work attached to actual world events should be evaluated before inventing repeating bounty income. No external region/dungeon integration pack was merged.

## Financial results

Cash margins below are realised sale receipts minus all cargo purchases; they are before upkeep. Stored cargo and worn equipment are excluded from cash. Equipment spending is gross purchases, not net asset appreciation.

| Seed | Policy | End day | Alive | Crowns | Cargo cash margin | Jobs | Gear bought | Wages | Supplies | Ending |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | mercenary | 14 | 4 | 0 | 0 | 369 | 248 | 141 | 59 | wage disband |
| 71 | mercenary | 18 | 4 | 0 | 0 | 375 | 175 | 171 | 203 | wage disband |
| 198 | mercenary | 5 | 0 | 87 | 0 | 190 | 164 | 30 | 114 | wiped |
| 395 | mercenary | 3 | 0 | 58 | 0 | 190 | 138 | 26 | 70 | wiped |
| 592 | mercenary | 17 | 4 | 0 | 0 | 369 | 245 | 167 | 187 | wage disband |
| 789 | mercenary | 12 | 0 | 59 | 0 | 375 | 345 | 78 | 93 | wiped |
| 986 | mercenary | 21 | 4 | 0 | 0 | 387 | 314 | 208 | 148 | wage disband |
| 1183 | mercenary | 19 | 4 | 0 | 0 | 190 | 206 | 185 | 59 | wage disband |
| 1 | trader | 46 | 3 | 409 | 1426 | 0 | 752 | 450 | 151 | survived |
| 71 | trader | 47 | 3 | 624 | 1580 | 0 | 632 | 414 | 364 | survived |
| 198 | trader | 46 | 3 | 389 | 1574 | 0 | 917 | 405 | 249 | survived |
| 395 | trader | 46 | 3 | 357 | 1444 | 0 | 657 | 417 | 295 | survived |
| 592 | trader | 46 | 3 | 119 | 988 | 0 | 502 | 405 | 355 | survived |
| 789 | trader | 46 | 3 | 122 | 1121 | 0 | 0 | 421 | 436 | survived |
| 986 | trader | 47 | 3 | 272 | 1455 | 0 | 847 | 414 | 316 | survived |
| 1183 | trader | 46 | 3 | 254 | 1346 | 0 | 738 | 405 | 281 | survived |
| 1 | mixed | 46 | 4 | 0 | 1074 | 369 | 910 | 555 | 309 | wage disband |
| 71 | mixed | 46 | 4 | 530 | 1489 | 625 | 925 | 540 | 291 | survived |
| 198 | mixed | 46 | 4 | 349 | 1315 | 1164 | 973 | 598 | 560 | survived |
| 395 | mixed | 8 | 0 | 80 | 264 | 190 | 98 | 72 | 58 | wiped |
| 592 | mixed | 46 | 4 | 750 | 1597 | 619 | 956 | 540 | 357 | survived |
| 789 | mixed | 46 | 4 | 487 | 1220 | 967 | 951 | 537 | 491 | survived |
| 986 | mixed | 46 | 4 | 98 | 1451 | 387 | 1028 | 537 | 366 | survived |
| 1183 | mixed | 46 | 4 | 201 | 1417 | 555 | 839 | 534 | 550 | survived |
| 1 | mercenary / growth | 14 | 4 | 0 | 0 | 369 | 248 | 141 | 59 | wage disband |
| 71 | mercenary / growth | 18 | 5 | 0 | 0 | 435 | 77 | 219 | 233 | wage disband |
| 198 | mercenary / growth | 10 | 5 | 0 | 0 | 190 | 90 | 92 | 94 | wage disband |
| 395 | mercenary / growth | 3 | 0 | 58 | 0 | 190 | 138 | 26 | 70 | wiped |
| 592 | mercenary / growth | 11 | 5 | 0 | 0 | 190 | 92 | 105 | 76 | wage disband |
| 789 | mercenary / growth | 13 | 5 | 0 | 0 | 190 | 77 | 139 | 51 | wage disband |
| 986 | mercenary / growth | 13 | 5 | 0 | 0 | 190 | 92 | 139 | 27 | wage disband |
| 1183 | mercenary / growth | 11 | 5 | 0 | 0 | 190 | 92 | 116 | 63 | wage disband |

The complete breakdown, including recruitment, loot, food/tools/medicine/ammunition spending, trade-by-trade decisions and exact earned saves, is under `docs/balance-0.40/`. `summary.json` provides the compact machine-readable table.

## Native verification

A fresh seed-71 company was created through the real Godot UI. No resources, victories, equipment, positions or fog were granted. The test knows the destination coordinates but explores toward them using a normal ground click; the town becomes selectable only after actual travel reveals it.

- Started with three mercenaries and 300 crowns.
- Bought three cloth and four grain for 172 crowns at actual marginal prices.
- Travelled to the next town, paying nine crowns in wages and consuming three rations.
- Sold all seven goods for 255 crowns: 83 gross trading margin and 74 cash gain after wages. The three consumed starting rations were not charged a fictional purchase cost.
- Hired a fourth mercenary for 107 crowns, leaving 267 crowns, 21 rations and 20 tools.
- F5/F9 preserved the fresh company, cargo, earned profit and new recruit exactly.
- Native run: 30 checks, zero failures. Screenshots `balance-opening-sale.png` and `balance-earned-fourth-recruit.png` were visually inspected. They display 0.39 because only the release label changed after that run.

This native check validates the fresh opening trade/recruit flow. It is not a native 45-day playthrough and does not establish that a human can discover these exact prices/routes without learning the region.

## Test boundaries

- All policies know the full map, current remote prices, merchant purses and enemy grades. They do not inspect future random rolls, predict NPC deliveries or change world state to help themselves. Remote price knowledge makes the trading results an optimistic planning benchmark.
- The tactical driver uses production AI with the existing casualty/health retreat rule. Its losses may reflect tactics. It does not evaluate all player builds, terrain tactics, deliberate camp farming, alternative routes or recruitment plans.
- The mercenary policy takes funded camp/escort/recovery work and sells recovered equipment/cargo, but never buys trade cargo. It does not perform a systematic search for profitable unsigned raids; this is a limitation on conclusions about all combat-only play.
- Mixed prefers acceptable paid work, then trade. Trader takes no voluntary jobs, but still fights forced road encounters and sells salvage. Each policy buys real modest equipment from surplus; backgrounds do not lock builds.
- Combat-selection thresholds belong only to the test policy, never to game access checks or player warnings. Veteran jobs require six active mercenaries and 110 average current body protection in this test. Outlaw jobs require four and 55 average protection; this conservatism can miss winnable opportunities.
- Reserve size, shopping and recruitment remain heuristics. Lower cash reserves can be rational, and waiting can still exhaust funds. None of the tested policies is an optimal solver.
- Earlier exploratory policies were not a controlled matched comparison and are excluded from the headline counts. Only the frozen final policy and its documented growth variation are counted.

## Reproduce

Run in Godot 4.4.1, from the extracted project directory:

```sh
godot --headless --path . --script res://tests/economy_balance.gd -- mixed 71 45 final
godot --headless --path . --script res://tests/economy_balance.gd -- trader 71 45 final
godot --headless --path . --script res://tests/economy_balance.gd -- mercenary 71 45 final
godot --headless --path . --script res://tests/economy_balance_growth.gd -- mercenary 71 45 growth
godot --path . --script res://tests/economy_balance_ui.gd
```

Use seeds `1, 71, 198, 395, 592, 789, 986, 1183` for the full cohort. The native test needs a display and a fresh Godot user-data directory. No downloaded external packages are required.

## Decision

Keep current pay, prices, wages, production and combat difficulty. Prioritise reachable work arising from real world events as the company outgrows the first camps; rerun these policies after the larger-region integration. Also test a player-style trading policy with remembered, stale prices before claiming ordinary trade is too easy.
