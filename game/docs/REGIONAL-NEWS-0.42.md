# Regional news and remembered leads — 0.42

Local Rumours now opens Reports & destinations. Towns describe their own road trouble, damaged or threatened farms, overdue incoming shipments and funded workshop shortages. Information heard by the company stays in a dated lead journal. Ordinary caravans carry copies of the origin's news, including reports already relayed there, and hand them over only on actual arrival. An escort takes a packet when it is signed; releasing that escort keeps the original packet. Seizure delays news and plunder destroys the packet.

## Player use

At a town, select **Local Rumours** or open **Lead Journal → Ask Locals**. Each report shows its observation day and age, where and when you heard it, and its last carrier when applicable. Reports at least 72 hours old display **MAY BE OUTDATED**. A late wagon or older town board cannot overwrite a newer account. Asking again can replace an outdated account; opening the journal alone never refreshes it.

The **Destinations** tab records trading connections described by locals and places named in received reports. **Show Search Area** pins a broad area and pans the map there. Travel remains a deliberate map action. Terrain, roads, precise settlement markers and enemy positions remain concealed until normal exploration reveals them. Directions do not guarantee safe travel, an available contract or profitable prices.

The lead journal is available from the overworld and pauses world time while open. F5/F9 preserve reports, directions and the pin. **Other Rumours** keeps access to existing cache/discovery rumours; burial rumours retain their own button.

## Information rules

Reports are snapshots, not live remote queries. Local sampling occurs when a carrier collects a packet or the player asks, at six-hour observation granularity. Each town retains up to 36 current report entries; the company retains up to 48. Local sampling prunes relayed board entries older than fourteen days. The journal retains remembered reports until superseded or its capacity is reached. Search areas use a coarse 128-pixel grid with a 96-pixel radius, not the settlement's exact point.

Road reports describe active, unprotected nearby threats. Farmers report damage or an ongoing raid. Merchants know which incoming shipments are overdue, without revealing where raiders took them. Workshop reports require funded production orders and actual material shortfalls; the two largest shortages are reported. None of this creates contracts, money, goods, troops or map visibility.

## Companies using available information

Four fresh mercenary careers ran through day 45 or a real loss. They start with the normal three companions, 300 crowns and modest equipment. The policy tries to maintain four mercenaries and uses the existing spending, training, fight-selection and tactical AI rules. It can use sighted destinations, destinations named in a signed contract and rough town directions actually heard. It cannot query remote prices or unseen town coordinates to choose travel. It visits local contract boards and asks for news only after physically arriving in a town. Exact routing is allowed once a town is sighted, matching the player's normal map action.

| Seed | Result | Day | Living | Crowns | Paid jobs won | Towns visited | Rough searches |
|---|---|---:|---:|---:|---:|---:|---:|
| 1 | Survived | 46 | 4 | 695 | 14 | 6 | 2 |
| 71 | Survived | 48 | 4 | 432 | 12 | 6 | 5 |
| 592 | Survived | 46 | 4 | 111 | 12 | 6 | 3 |
| 789 | Company lost | 6 | 0 | 70 | 1 | 3 | 3 |

Three companies survived and reached all six towns. Seed 789 lost two mercenaries in a day-4 fight, then lost its remaining two to a day-6 interception. The three survivors also suffered casualties and paid to replace them. Outcomes remain challenging; these are reproducible automated policies, not human win rates or a completed balance claim. Finishing an ongoing journey can put the final snapshot past day 45.

The earlier 0.41 all-town search policy survived 4/4 of these seeds while knowing all town positions. This run tests access to opportunity using player-available information; it does not isolate news as a statistical cause of survival. No payouts, wage rules, starting supplies, equipment, enemy strength or combat math changed. Every career reconciles its final crowns against real contracts, loot, wages, hires, gear and supply purchases. Reports include journeys, observations, decisions and earned save checkpoints. These careers accepted no escort jobs; escort packet behavior is covered separately in the model checks.

## Native verification

A fresh seed-71 company asked for directions in Stonewick, pinned Briarmere's search area, explored through ordinary ground clicks until the town became visible, and physically arrived there. Normal wages were paid. It then waited for actual arriving caravans and heard two foreign reports. It ended that journey on day 4 with all three mercenaries and 273 crowns. F5/F9 preserved the heard information, exploration and pin. There were no resource grants, teleports, visibility fixtures or forced victories in this journey.

A separate native UI case loads the unmodified earned seed-71 career endpoint. It checks every journal page, independently clickable pins for multiple reports about the same town, naturally stale reports, and persistence. Browsing does not update reports or reveal terrain. Screenshots are included below.

## Validation and compatibility

11 completed test runs, 2447 checks, zero failures. Godot 4.4.1 editor import completed successfully. Coverage includes physical carrier delivery, frozen packets, out-of-order arrivals, older information rejection, escort reservation/release, old-save adoption, exact new-save roundtrips, malformed-news rejection without partial mutation, signed contracts, active combat and retreat aftermath. Regression checks cover economic conservation, material freight, traffic, battle time and integrated compatibility.

The isolated carrier and out-of-order tests use explicitly labelled fixtures; those are separate from the earned careers and native journey. The final logs and check counts are in `news-0.42/logs/` and `news-0.42/verification.json`. New saved companies use wrapper 34 around unchanged wrapper 33 / economy schema 3. Existing 0.41 saves remain unchanged until their first request for regional news; adoption does not enlarge their maps or grant anything.

Reproduce model checks with `godot --headless --path . --script res://tests/regional_news.gd`. Run an information-limited career with `godot --headless --path . --script res://tests/regional_news_careers.gd -- 71 45`. The native suite, `regional_news_ui.gd`, requires a graphical display and reads the included earned seed-71 endpoint. Do not use a frame cutoff for long career tests; require their final check-count marker.

## Screenshots

![Local reports](region-earned-news-local-reports.png)

![Remembered destinations](region-earned-news-destinations.png)

![Search area over unexplored terrain](region-earned-news-search-area.png)

![Dated reports from an actual arriving wagon](region-earned-news-caravan-reports.png)

![Naturally aged earned journal](region-earned-news-stale-earned-journal.png)

## Source provenance

Built from the authoritative 0.41 archive, SHA-256 `5cdb1e65690ca940c3974d78bf0ceb25b107e73e39a8e1c93b8c5d59b9c61621`. This slice adds the information model and journal UI to that build. Other feature packs are not silently included. Historical source, audit reports and compatibility fixtures remain in the archive.
