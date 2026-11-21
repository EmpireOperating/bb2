# Expanded region and work availability — 0.41

New companies use a 116 × 60-cell region, four times the former map area, with six towns, six farms/councils, ten physical caravan routes and 10–12 camps. Two districts connect through guarded trade corridors, with wilderness camps beyond their roads. Every town has its own recruits, market, material stocks, workshop demand, cash and fleet accounts. Supply/demand prices and world-funded contracts retain 0.40 rules.

## What changed

The Expanded Region port was reconciled with authoritative 0.40. The newer industry/material freight systems now use town economic roles and dynamic account counts. The map camera clips the larger region, supports pan/zoom/follow, and converts mouse positions back into world coordinates. Town/camp report pages handle the expanded roster. Fixed and old generated maps retain their old geometry on load.

Controls: WASD/arrows or middle drag to pan; wheel or −/+ to zoom; Home or Company to follow. Fog remains attached to campaign discovery; camera movement reveals nothing. Starting a new company resets the camera. Start a new company to get the larger region. F5/F9 remain save/load. Combat retains Space to wait and F to end activation.

## Same company policies, larger world

Eight seeds: 1, 71, 198, 395, 592, 789, 986, 1183. Each career runs through day 45 or a real loss; completing an ongoing journey can carry the final snapshot into day 46 or 47. The expanded driver differs from 0.40 only in the map flag and output folder. No changes to payouts, wages, starting resources, combat math, enemies, gear prices or AI were made to improve these results. Survival requires a living, undisbanded company past day 45.

| Policy | Small map, 0.40 | Expanded map, 0.41 | Paid wins on expanded map |
|---|---:|---:|---:|
| Trader | 8/8 | 7/8 | 0, 0, 0, 0, 0, 0, 0, 0 |
| Mixed | 6/8 | 8/8 | 11, 9, 13, 7, 11, 10, 10, 13 |
| Mercenary | 0/8 | 1/8 | 13, 2, 4, 1, 3, 3, 7, 2 |

These are reproducible policy outcomes, not human win rates. Traders may fight intercepted road parties; paid wins count completed jobs, not every battle. The driver knows geography and remote prices, uses conservative fight filters, and usually holds combat companies at four. It does not grant money, teleport, reveal fog, force wins or inspect future randomness. The previous optional six-person policy was not rerun in this slice.

## Work-search control

Inspection of the unchanged policy found repeated journeys between the nearest two towns. That can leave an entire added district untested. A second policy visits all town boards before repeating familiar ones, then weighs elapsed time against travel time. It has no knowledge of remote job offers. Exactly this search policy ran on both map sizes for four seeds; purchases, fight selection, resources and tactics are unchanged.

| Seed | Small map | Expanded map | Expanded paid wins | Towns visited, small / expanded |
|---|---|---|---:|---:|
| 1 | Day 14: wage disband | Survived, 729c | 14 | 3 / 6 |
| 71 | Day 18: wage disband | Survived, 901c | 11 | 3 / 6 |
| 592 | Day 14: wage disband | Survived, 610c | 12 | 3 / 6 |
| 789 | Day 22: company lost | Survived, 167c | 12 | 3 / 6 |

The comparison tests regional opportunity and the cost of reaching it. It does not establish that every mercenary start is viable or that job generation is fully balanced. New threats also increase travel danger. Geography, travel encounters and the order of world events can change with the expansion, so outcomes cannot be attributed solely to the number of contract boards.

## Native game verification

A fresh seed-71 company bought seven trade units for 172 crowns, physically travelled and sold them for 255, hired a fourth mercenary for 107, then travelled into the eastern district. It arrived on day 3 with 255 crowns, four living mercenaries and 17 rations. Fog was revealed by travel only. F5/F9 preserved each checkpoint.

A second native run loaded that exact earned arrival, accepted the eastern council's 190-crown camp contract, travelled to East Crossing Outlaws, deployed on its ford battlefield, and resolved the actual fight. A scout interception on the approach killed two mercenaries. The two survivors then won the camp battle with no further deaths, ending with 445 crowns. Both encounters used actual combat commands. No resources, levels or equipment were granted and the test did not require victory. This verifies the new camp ID, battlefield mapping, funded payout and save/load through combat; it is not evidence that the fight is safe for every starting party.

A separate native fixture verifies camera controls, six town service panels, report pagination and loading an original map. Its full-map screenshots explicitly use visibility/location fixtures and are not earned exploration. The measured full-map render was about 32.8 ms/frame on the test machine with software OpenGL; it is not a hardware performance guarantee.

## Validation and compatibility

49 completed test runs, 7013 checks, zero failures. Clean Godot 4.4.1 editor import. The suites include six-town economic conservation over 35 days, independent market transactions, physical material freight, exact persisted roundtrips of four earned 0.40 saves, malformed-account rejection without partial mutation, 32 expanded-map geography checks and 64 legacy hinterland layouts, loot, camp life, farms, battle time and integrated legacy compatibility. Observer-only 35-day tests give survival resources to the observer company; they are separate from all career outcomes above.

Old companies keep their map, money, equipment and progress. Save wrapper 33 and economy schema 3 remain; expanded geography/world use version 3. No loading grants or automatic map enlargement. The persisted comparison normalizes both sides through JSON to avoid treating equal integer/float representations as gameplay changes.

Reproduction: run `godot --headless --path . --script res://tests/expanded_balance.gd -- mercenary 71 45 unchanged`. For the paired control, use `regional_search_balance.gd -- mercenary 71 45 search-small` and `search-large`. Native tests require a graphical display: `expanded_region_ui.gd`, `expanded_economy_ui.gd`, and `expanded_contract_ui.gd`. Full reports, cash accounts, decisions, journeys and earned checkpoints are in `docs/region-0.41/`; final test logs are under its `logs/` directory.

## Integration provenance

Base: Battle-Brothers-2-Prototype-0.40.zip, SHA-256 `a8a284b519801bea0734e353f6f27d10eadb3e5ab5193ba2ed44acbfa82f22e5`.

Source: Expanded Region, using the reconciled `01-expanded-region-on-0.36.patch` supplied in the Regional Recovery pack. The recovery-only patch was not applied. Its repairs/relief changes, vault-key changes and other unrelated feature packs are outside this slice. The merge preserves the 0.40 conserved economy, role-aware markets, material caravans, finite merchant cash and absence of unfunded scout bounties. Conflicts in campaign setup, market validation and the main UI were resolved explicitly; regression tests above cover both old and new maps.
