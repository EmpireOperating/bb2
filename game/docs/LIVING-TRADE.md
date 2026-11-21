# Physical trade in 0.31

The Living Trade dependency is integrated alongside Living Bands. [The original specification](LIVING-TRADE-preview.md) describes cargo ownership, four-hour NPC defence, physical return journeys, rescue, evidence and patrol protection. Its preview save path, schema numbers and setup signature are superseded below.

New native campaigns use schema 26, traffic version 2 and the ordinary company save. `Campaign.setup(seed, map_seed, progression, live_trade, living_bands)` keeps progression as the third argument. Traffic version 1 from the separate previews retains its original road-corner movement; version 2 uses the main build's corrected generated-road pace. Freight never advances in both the daily world loop and physical ticks.

The same three-minute clock owns movement, recovery and midnight upkeep. Battle settlement advances background bands and freight for its accounted day without moving the company, triggering offscreen company battles, charging upkeep twice or adding a free day of healing. Campaign-wide ledgers remain authoritative for every food unit and treasury payment.

Paid escort contracts keep their existing checkpoint/delivery flow and 0.30 guarded-road availability and pay. They are distinct from protecting autonomous shipments. A company that drives away raiders frees the actual goods, earns no intimidation bounty and receives no company cargo. Captured goods become camp reserves only after physically arriving there. Destroying a camp releases held cargo for its remaining journey.

Caravan and wreck sidebars offer Stop & pause. Their selection persists when leaving a town. Overlapping site hit areas cannot swallow clicks on visible wagons, wrecks or roaming parties. Missing-caravan rumours take priority over discovery rumours; further enquiries reach remaining discoveries. Inspected tracks can identify a camp without revealing surrounding terrain.

See [current validation](VALIDATION.md) for native rescue, delivery and wreck journeys, isolated branch fixtures, exact older-save continuations and full-month results. Farm Supply, new town counts, field recruitment and individual NPC-versus-NPC tactical combat remain outside this merge.
