# Material freight 0.39

## Shipping decisions

The eight dedicated trade goods can travel by NPC wagon: furs, cloth, silk, salt, lumber, iron, grain and hides. Finished supplies still use their local workshop/player-market rules; food retains its existing physical caravan system.

Each existing road has outward and reverse material variants. A specialised producer can ship only when its output for that good exceeds the destination's output. It keeps at least the greater of its normal target stock and its own affordable material needs. This prevents goods simply bouncing between markets.

Destination demand is target stock plus affordable recipe needs, minus actual stock and still-moving incoming cargo. Silk buyers must be prosperous. The planner selects the most valuable shortage, prioritising a missing input for current work. A shipment contains one good, at most four crates/bales. There is at most one new material dispatch per origin per daily tick, a three-day cooldown per directed route, and no second active material shipment on that directed route while one is waiting, moving or under escort.

The buyer must afford the goods, haulage and a 24c working reserve. Cargo costs 75% of the producer's current marginal retail quote; haulage costs 6c plus 2c per configured route day. Higher local value normally justifies the purchase; a real work blockage can justify an otherwise unprofitable import. The order is requoted before dispatch so stale plans cannot oversell or overdraw.

The seller is paid immediately. The buyer owns the cargo and bears the risk of loss. Haulage is a service expense, not a grant to another town or the player. Actual goods are removed from the exporter and a ready freight vehicle is consumed. The destination inventory does not change until physical arrival. Workshop orders may then consume the delivered materials normally.

## Capture, recovery and loot

Material wagons use the existing Traffic movement, sight, raid-intervention window, hauling, evidence trails and escort rules. Raider interest includes material cargo value. Materials never count as edible camp food, and food consumption cannot empty a material wagon.

- A roadside rescue frees the shipment to continue to its buyer.
- A captured shipment remains recoverable. Its buyer has already paid; an actual funded recovery job can be offered at either trading endpoint.
- After two full days held at camp, the goods become unpacked camp stores. Recovery work can still return them.
- A company camp victory takes unpacked trade stores into company cargo; intact wagons are released instead. A currently signed recovery reserves that shipment for its buyer.
- An outside camp clearance releases captured shipments. It does not give the player cargo.
- Looting marks that shipment exhausted and does not return its destroyed freight vehicle. A later camp generation cannot pay the same cargo again.

Existing council escrow pays escorts and recovery work. An escort requires the threatened-road encounter to be resolved and pays on arrival. Recovery pays for recovering the shipment and sends it onward under the existing guarded return rules. There are no cargo-specific flat bounties or generated replacement enemies.

## Accounting and compatibility

Economy schema 3 records material shipping histories, town exports/imports and company cargo looted. Material inventories balance against initial stock, production, use, company trades and actual imports/exports. Company cargo balances purchases plus loot minus sales. A single record connects the source, buyer, original goods, cost, haulage, world wagon and final disposition.

Fleet accounting includes both food and material vehicles, including the existing timed empty return after delivery. Material wagons contribute zero to the food ledger. Payment updates persistent merchant accounts and any current market books. A town opening its market later inherits its actual purse, not new weekly money.

Old 0.38 saves adopt an empty shipment history without resetting industry or moving goods/money. The preserved earned fixture is `freight-compat/v038-day46.json`. Old 0.37 migration remains available. New material manifests require the economy/fleet capability and must agree with the shipping history. Invalid manifests, routes, cargo totals, loot, phases, capability markers and accounts are rejected atomically.

## Player presentation

The road report lists the actual goods, outcome and purchase/haulage cost. A material shipment can be reported through a known trading endpoint even when the other endpoint is not explored; unknown places remain labelled **Unknown** and this report never reveals map cells or roads. Town Work totals still-moving paid imports. Caravan details, contract briefs, raid news and camp aftermath text use the cargo's actual name instead of calling everything food.

## Verification

Final test logs and the assertion manifest are in `validation-0.39/`.

- The material model suite covers funded dispatch, reverse routes, no early stock credit, delivery exactly once, escort gates/payment, captured material not being eaten, recovery, unpacking, camp loot, sale, insolvency, save migration and malformed-state rejection. Most branch cases are controlled fixtures; capture timestamps and tactical success are explicitly isolated where indicated.
- Native UI testing first loads the exact earned 0.38 day-46 company and checks migration. It then continues an exact earned older twelve-person company, travels normally, buys rations with its own money, observes NPC purchases/deliveries and a natural raid, reads the road report, destroys the actual camp through legal combat, loots the captured goods, travels back and sells one unit through the market. F5/F9 is checked at migration, captured cargo, active battle, aftermath and sale. No company, enemy, merchant, cargo or victory grant is installed in this journey.
- Native evidence: W018 carried three furs bought for 128c plus 10c freight. It was captured and unpacked at the forest camp on day 36. The company won that camp fight with twelve survivors, received those three furs plus the camp's actual 52 rations and six stolen crowns, and sold a fur at the destination. This verifies the feature, not opening-game difficulty with three founders.
- `freight-delivered.png`, `freight-captured.png`, `freight-camp-loot.png` and `freight-loot-sale.png` were visually inspected at 1440×900. Unknown destinations remain masked; the selected cargo and payment fit the report; the camp aftermath names the looted furs.
- An old traffic-camp regression test failed identically in untouched 0.38: it stopped waiting when a real unrelated scout encounter paused world time, then incorrectly required the wagon to have arrived. The test now resolves that ambush through normal combat before continuing the wait. No game rule was changed to make that test pass. The baseline diagnostic is in `freight-audit/baseline-traffic-camp.txt`.

Four unchanged hybrid career policies were also run from fresh companies for up to 45 days. They use ordinary recruitment, markets, contracts and legal combat with no money/resource grants or forced wins. The driver knows the whole map and remote current prices; it does not forecast competing NPC arrivals, so these are not human win rates.

| Seed | Final day | Living | Crowns | Material shipments | Delivered | Outcome |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 21 | 3 | 0 | 29 | 24 | Three unpaid days. The company disbands. |
| 71 | 46 | 4 | 37 | 53 | 50 | Survived 45 elapsed days |
| 592 | 18 | 4 | 0 | 24 | 20 | Three unpaid days. The company disbands. |
| 789 | 36 | 0 | 38 | 39 | 37 | The company is gone. |

The four careers produced 145 paid material shipments. Six material recovery jobs were completed through the automated campaign/combat loop and ultimately delivered:

- Seed 71: wagon_014, iron, final phase delivered.
- Seed 71: wagon_015, lumber, final phase delivered.
- Seed 71: wagon_011, cloth, final phase delivered.
- Seed 71: wagon_024, cloth, final phase delivered.
- Seed 789: wagon_025, cloth, final phase delivered.
- Seed 789: wagon_030, furs, final phase delivered.

Day 46 represents 45 elapsed days from day 1. NPC competition closes some easy trading gaps; two companies disbanded over wages, one was wiped and one survived with little cash. This is a disclosed balance result, not a claim that mercenary or trading careers are fully tuned. Larger-company balance has not been established.

## Scope

Production remains a town-level abstraction using the 0.38 material/workshop rules. The current region still has three town roles. Empty vehicle returns use the existing timer, not a separately drawn return party. Friendly caravan robbery, roadside trading and commodity insurance are not added. The company obtains goods through town purchases or captured camp stores; intact recovered freight belongs to its buyer.

Other chats' region/dungeon integration packs were not silently merged into this economy update. Region expansions must extend producer mappings and freight validation together.
