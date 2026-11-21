# Town industry 0.38

## What drives demand

The 0.37 fixed daily disappearance of tools, medicine, ammunition and all cargo has been removed. Producers create raw materials into finite stores; factories consume recipe inputs. Company demand, household wear, food shortages, real damage, freight capacity and empty equipment shelves determine orders.

Towns manage themselves. The company can deliver inputs or buy finished goods; there is no player workshop-management layer or equipment-readiness warning.

- Ashwick's role is cloth and grain, with some hides and timber.
- Stonecross produces iron, salt and silk, with a little grain.
- Dunmere produces timber, hides and furs, with modest grain and cloth.

These are stable town IDs; the procedural region can give them different display names.

## Concrete recipes and consequences

| Work | Inputs | Result / payer |
| --- | --- | --- |
| Farm repairs | 4 lumber, 1 iron, 2 tools | Council pays 18c; materials authorize the existing safe-work timer for that raid incident |
| Town repairs | 3 lumber, 1 iron, 2 tools | Council pays 16c; removes one recorded damage level |
| Freight wagon | 4 lumber, 1 iron, 1 hides | Merchant pays 10c; adds one dispatchable vehicle |
| Mill and bakery | 1 grain | Merchant pays 3c; adds 24 actual rations to the town's conserved food ledger |
| Food preservation | 1 salt | Merchant pays 2c; protects surplus town food for the next three days |
| Toolsmith | 1 iron, 1 lumber | Merchant pays 4c; creates 12 usable tools |
| Fletcher | 1 iron, 1 lumber | Merchant pays 4c; creates 30 usable ammunition |
| Medical dressings | 1 cloth | Merchant pays 3c; creates 6 medicine, with local herbs/labour abstracted |
| Raid treatment | 2 medicine | Council pays 8c; reduces raid pressure by one |
| Clothing / bedding | 1 cloth or 1 furs | Households pay 16c / 30c; clothing need covered for four / seven days |
| Fine silk clothing | 1 silk | Prosperous households pay 70c; luxury need covered for ten days |

Armour and weapons use recipes selected by their actual kind: cloth padding, hides for leather, iron for metal armour and blades, wood/hides for bows, and wood/iron/hides for shields. A made item enters persistent shelf stock. Weekly selection and one purchase per definition per week are retained; a week boundary no longer refills an empty shelf without materials.

Workshop capacity is two non-household jobs per day, reduced to one while hungry or damaged. Missing materials do not use that capacity: another feasible order can proceed. Essential recovery/food orders are considered first. Household purchases have separate finite household budgets. Raw extraction costs the merchant 2c per unit and stops at four target stocks, so producers do not accumulate unlimited goods.

Affordability is checked at execution. Orders are intentions rather than escrowed contracts; the displayed funds can be spent on another higher-priority order first. Contract escrow remains the separate 0.37 system.

## Food and freight

Unpreserved town stocks above four days of local demand lose 2.5% of the surplus per daily tick, rounded up. Salt stops that loss for the preservation period. This is town storage only; company rations retain their current rules. Grain baking adds explicit food output, while spoiled food has its own ledger and is never misreported as food eaten or bought.

Each town starts with two available freight vehicles when adopting industry. New food shipments consume capacity. Delivered vehicles become available at their origin after the route's return travel time. Seized vehicles remain tied up until recovered and delivered; plundered vehicles never return. A short destination and no ready origin wagon can prompt construction. Pre-industry shipments are grandfathered and do not return into the new initial fleet. Farm harvest carts remain part of the farm infrastructure; farm-repair materials cover their infrastructure rather than requiring a brand-new wagon every harvest.

## Prices, money and saves

Quotes combine current stock with bounded demand from individually affordable orders. Marginal pricing and the buy/sell spread remain. Merchant purchases, sales, retail receipts and labour payments update both the persistent purse and the current equipment market book. Council-paid work debits the actual council. Household earnings are an abstraction of the surrounding civilian economy, not a fully closed simulation of every citizen's wage.

The outer campaign wrapper remains 33; economy schema is now 2, with an industry substate and optional world fleet/spoilage ledgers. The immutable 0.37 validator checks old economy schema 1 before adoption. Existing company resources and cargo remain intact. New material stock is an initial town reserve, not a company reward. Old damaged farms adopt the material requirement for their unfinished repairs.

Conservation checks cover materials in/out, recipe input totals, workshop output, shelf items, household budgets, vehicle dispatch/return counts, spoilage and the existing world food/council money ledgers. Invalid candidates are rejected atomically. The archived earned 0.37 day-46 company is preserved at `industry-compat/v037-day46.json`.

## Verification

The final validation manifest and logs are in `validation-0.38/`.

- Material tests cover 0.37 migration, grain and medical conversion, salt/spoilage, a supplied farm repair, actual wagon dispatch/refusal/return, a week without free equipment replacement followed by material-funded replacement, bankruptcy, real raid demand and malformed-save rejection. These are explicitly controlled fixtures, not claimed player journeys.
- Four fresh careers use normal actions with no resource grants or forced combat results. The automated driver knows remote prices and map routes. It is a test policy, not a new player feature. Legal combat and normal wages, supplies and recruiting still apply.
- The native UI test begins with a new three-person company and buys new lumber cargo. It then loads an exact earned older company, fights a live camp, transports iron from its producing town and sells it at another town, transports cloth back, and checks F5/F9 at several stages. The old destination purse was nearly empty; ordinary tool purchases for the company funded the later iron sale. No merchant purse was granted. Iron bought at 36c sold at 67c; this is gross resale margin, before company travel costs.
- Native material and work pages were captured and visually inspected at 1440×900. `industry-materials.png`, `industry-town-work.png`, `industry-iron-origin.png` and `industry-destination-market.png` show the delivered UI. Older compatibility suites remain available and pass.

| Seed | Final day | Living | Crowns | Outcome |
| --- | --- | --- | --- | --- |
| 1 | 21 | 2 | 0 | Three unpaid days. The company disbands. |
| 71 | 23 | 0 | 16 | The company is gone. |
| 592 | 46 | 4 | 310 | Survived the 45-day run |
| 789 | 46 | 4 | 180 | Survived the 45-day run |

Day 46 means 45 elapsed campaign days from day 1. The sample does not establish 12-/20-person company balance.

## Deliberate scope

NPC freight still physically carries food. Cargo goods are produced and used locally and can be transported by the company; general NPC material shipments are not implemented in this slice. There are no seasons, population model, individual resident inventories, or separate charcoal/herb intermediate commodities. Cloth-to-medicine abstracts local medicinal ingredients; grain is additional dry crop output alongside the existing perishable farm-food chain. Returning freight capacity is timed but its empty return journey is not drawn as a separate world entity.

Goods have functional demand and finite stock, but a long isolated shortage can still stop a town's work until the company delivers inputs. The current region has three town roles; future region integrations must extend the material stocks, producers and compatibility rules rather than silently using these three-town mappings.
