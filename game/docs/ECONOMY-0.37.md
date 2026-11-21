# Living economy — 0.37

## Scope and rules

The baseline is the exact 0.36 master, Library version 41 (SHA256 `9da5ebe8062aa224b4a16f11b17881e700ff88adaa0098bf9cf701132e9d505a`). No Expanded Region, Boss Tactics or other parallel integration pack is merged here.

Trade cargo is separate from consumable supplies. Farming towns produce cloth, woodland towns produce furs, and the workshop town produces silk and salt. These roles follow town identities on the generated map, not their displayed names. Three-town geography is retained. Local consumers use goods daily; workshops have finite storage and reduced output during food shortages or raid pressure.

The four supplies are food, tools, medicine and ammunition. Food uses the existing farm/cart/caravan ledger, including company exports and imports. Other supplies use local production/consumption ledgers. Town supply quantities and cargo cannot be created by repeated purchases or selling. Ammo sales draw only from the company reserve, not loaded weapons. Buying ammo retains automatic carried-pack refill.

Buy and sell quotes sum marginal prices across the whole bundle. Sales use a 25% spread and reduce scarcity; purchases increase it. Immediate buy/sell cycles lose money. There is no global fixed resale price and no promise that a planned delivery will remain profitable after travel.

Food merchants dispatch cargo when destination stocks plus incoming freight are below eight days of demand. Existing food wagons remain physical, interceptable entities. **Dedicated trade goods currently move between towns through the player's cargo; there are no new autonomous silk/fur caravans or cargo weight system in this release.** Food traffic, local shortages and raid pressure still affect the surrounding economy. This is an initial trade economy, not a complete simulation of every material input and profession.

Private merchant money persists across weekly equipment inventory refreshes. Purchases and simulated local consumption/retail activity replenish it. Equipment, supplies and cargo share that finite purse. The local retail income is a model of residents' spending, not a closed global currency simulation.

Council contracts are selected from existing camp occupations and physical shipments. Weekly `road_hunt`, `road_arms` and `road_blockade` offers cease in economy campaigns. Camp and convoy identities prevent repeated claims on the same target. A genuinely new funded camp occupation or loaded exposed shipment can create new work. Peaceful roads do not advertise guaranteed escort income. Board prices are capped by the council's available money; fewer than 50 crowns means no posting. Signing moves the amount into escrow. Completion pays it; failure/expiry/cancellation or another actor resolving the target returns it. Reserved money is unavailable to patrols. New worlds begin with an additional 240 crowns of civic reserves per council, accounted as an initial contribution; existing worlds receive no such grant on migration.

Uncontracted scouting/camp wins no longer spawn fixed money. A player camp clearance transfers its current unpacked rations and tracked stolen treasury coins, then frees surviving identifiable cargo. Patrol clearances dispose of unclaimed stores without paying the company. Existing equipment salvage and named-roll rules are unchanged. Supplies previously awarded on every successful contract are removed for new economy jobs.

The Company plan also now forecasts travel/rest beyond day 30 for continuing companies; its previous UI-only date limit was left over from the monthly campaign.

## Save behavior

Wrapper 33 contains `economy_base_version: 32`, preserving the existing nested save capabilities. Validation checks inventory flows, cash balances, market linkage, escrow, actual target identities and tracked stolen coins, and rejects malformed input before replacing a live campaign.

Native loading adopts the economy only for a living open campaign in camp with no pending encounter. An older active battle finishes under its original saved encounter; adoption happens after return. An already-signed old job is grandfathered exactly once, including its original payment/supply bonus. No soldiers, company money, equipment, health or supplies are granted. Older monthly model snapshots remain exact until explicitly continued/adopted. Weekly historical road-job fixtures remain useful compatibility tests, not new-game behavior.

The persistent town identities and `setup` twelfth argument (`world_economy`) must be reconciled when integrating a larger-region pack. The eleventh argument remains `open_campaign`. Do not overwrite current source with a parallel pack's older snapshot.

## Evidence

`tests/economy.gd` covers finite stock, separate cargo, spread, cross-town margins, food price response to an actual raid, merchant rollover, escrow reserve/refund, patrol withdrawal, real camp-store transfers, no duplicate claims, peaceful boards, migration and atomic corruption rejection. Its funded 40-day observer and location/raid fixtures isolate rules; they are not earned playthroughs.

Native acceptance uses rendered controls: a fresh company buys supplies and dedicated cloth cargo, then F5/F9 restores them. A second segment loads the exact earned 0.36 day-30 seed-71 company, migrates without grants, fights its actual forest camp and recovers 39 rations with no bounty, travels to trade tools, and carries cloth from the farming town to the workshop town for resale. This is an earned older-company continuation, not a fresh 0.37 thirty-day native playthrough. Screenshots show the real boards, cargo/supply tabs, aftermath and destination sale.

The final hybrid driver starts fresh companies with ordinary founders/resources and uses legal trades, recruitment, travel, recovery and tactical AI. It keeps four mercenaries, retains two days' wages plus eight crowns while buying cargo, ranks cargo by resale ratio, and applies a preparation preference before optional contracts. Those are test-policy choices, not player access gates. It knows remote quotes and map topology, does not attempt dungeons, and does not represent human win rates.

| Seed | Final day | Living | Deaths | Crowns | Outcome |
|---|---:|---:|---:|---:|---|
| 1 | 46 | 4 | 2 | 1,495 | Still operating; audit ended |
| 71 | 10 | 0 | 5 | 133 | The company is gone. |
| 592 | 46 | 4 | 3 | 3,165 | Still operating; audit ended |
| 789 | 5 | 0 | 4 | 22 | The company is gone. |

The two survivors support four mercenaries through day 45 with trade and a finite set of real contracts. This does not establish balance for twelve deployed or twenty paid members. No combat stats or enemy forces were weakened. Another policy on the same game held too much idle cash while refusing small trades; two companies went bankrupt and two wiped. That exposed a driver failure rather than evidence that the game should grant recurring jobs. Both outcomes are retained in `economy-policy-comparison.json`.

Exact successful validation logs and assertion counts are in `validation-0.37/`. Counts include repeated serialization/accounting checks, not distinct scenarios. Native screenshots were visually checked. Historical 0.36 and earlier reports remain evidence only for their versions.

## Reproduce

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/economy.gd
godot --headless --path . --script res://tests/economy_careers.gd -- 1 45
godot --headless --path . --script res://tests/economy_careers.gd -- 71 45
godot --headless --path . --script res://tests/economy_careers.gd -- 592 45
godot --headless --path . --script res://tests/economy_careers.gd -- 789 45
```

`economy_ui.gd` requires a graphical display and isolated user-data directory. It drives real controls and legal battle commands. `economy_careers.gd` exports reports and exact end saves under `docs/economy-careers/`.
