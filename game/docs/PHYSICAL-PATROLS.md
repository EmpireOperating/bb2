# Physical town patrols

This first slice makes the farm town's council patrol a real moving party. It builds on the isolated farm-supply preview, not on the other chat's main 0.30 build. Open **Town Guard** to inspect it or support its council.

## Behaviour

- Existing council taxes and deliveries pay the existing 90-crown formation cost. Five guards depart from their actual town. The default route serves the farm's camp corridor; an existing queued council order can select the other adjacent road.
- Guards walk a terrain-aware circuit through their farm, a road approach and home. They detect the assigned camp's band within 120 map units by day or 80 at night, pursue only while it remains visible, and avoid chasing more than 360 units from home.
- Protection is local: a paid, sufficiently strong patrol within 60 units deters new farm/freight attacks and permits farm repairs. It gives no automatic strength or camp clearance across an entire road. Fighting, returning and unpaid guards provide no passive protection.
- On reaching raiders within 18 units, guards interrupt the supply raid and engage that same finite party. Existing cargo recovery rules handle freed freight/harvest; no food or bounty is awarded to the player for the NPC action.
- NPC combat uses a deterministic field-resolution model with simultaneous attrition once per world hour. Both five-slot guard and six-slot band health records take actual losses. It is not a hidden execution of the tactical combat engine. A victorious patrol removes the field band, not its main camp. Two surviving guards or fewer fall back; total casualties destroy the patrol.
- Survivors walk home before recuperating. Rest lasts 24 world hours; living guards heal only while paid. Dead guards never heal. At most one replacement joins per recovery day in town, costing 18 council crowns. A recovered patrol can redeploy with at least three fit guards. The physical patrol remains in continuing service; the older abstract four-day watch expiry does not apply to it.
- Wages cost 6 council crowns/day. An unpaid patrol loses protection, physically returns, and waits. It resumes recovery when funded. A destroyed patrol remains in history; a new formation requires another 90 crowns and receives a new ID.
- **Support the Guard · 90 Crowns** transfers company money into the council's accounted treasury while at its town. It does not create instant troops, protection, reputation, XP or a free payroll. Existing council orders remain separate.
- When a fight is visible, **Engage Their Attackers** uses normal free-roam pursuit. On tactical deployment the company takes over and surviving guards withdraw. The same enemies retain NPC-inflicted wounds and deaths; there are no extra allied tactical units in this slice. Guard health cannot also take offscreen damage while the player fights.

Only parties within company sight are drawn. The sidebar conceals an offscreen patrol's live details away from its town; its town supplies a status report. No guard route reveals unexplored terrain. NPC victory immediately cancels any player pursuit of that defeated band. Pausing and management screens freeze world movement; accounted background travel/rest/battle days use the same three-minute steps.

## Integration

`Campaign.setup(company_seed, map_seed, live_trade, living_bands, rural_supply, physical_patrols)` adds an optional sixth argument, default false. New preview companies enable it. Schema-26 farm and older previews keep their original patrol rules without silent conversion.

`Guards` owns the physical party's route, health, detection, fight timer, retreat, rest, paid-day marker and reinforcement history. `World` still owns formation records, council money and every food unit. Derived `physical_faction`/`physical_site` fields tell World which council to omit from abstract daily movement and road-wide strength. Its existing dispatch still pays for one active patrol at a time. The other two councils retain their old abstract behaviour.

`Overworld` remains the movement authority. Its synthetic friendly-party list excludes the physical council so it is not drawn twice. `Bandits` adds a validated `fighting_patrol` mode and freezes the engaged party's position while the fight resolves. `Traffic` and `Farm` exclude engaged raiders and consult nearby guard protection. `GuardView` draws observed patrols and handles the report/help/funding controls.

The preview uses campaign schema **27**, guard component version **1**, and a separate `user://ashen-company-physical-patrols-preview.json`. These version numbers are local preview allocations: reconcile them with the main branch before merging. Guard records cross-check the existing world patrols, positions/routes, roster sizes, payment dates, combat targets and band modes. Candidate components validate before committing a load. World/band/farm old-version fields remain exact when guards are disabled.

Incremental base: farm-supply commit `23174ae055d8860fb7045b4c30ab4918a3d36044`. Preserve the main chat's newer equipment, passive recovery, weapon switching, fog, perks, progression, dungeon work and save migrations. Review the small shared hooks rather than replacing the main project with this 0.27-derived source preview. Tactical battle rules, player progression, equipment definitions, people generation and the map generator are unchanged.

## Scope and tuning

This is one council's five-person service, not physical conversion of every faction. Guards do not assault camps, maintain garrisons, trade equipment, escort a specifically selected cart or consume a regional population pool. Replacement manpower is limited by slots, money, town presence and one recruit per day. Returning parties are not separately hunted in this slice. Farm harvest carts remain non-ambushable; inter-town freight retains its attack/rescue system. Existing daily town-stock raids still run independently.

Strength estimates and hourly NPC attrition are prototype tuning. Ordinary starting companies in this source still have the older equipment; balance must be checked after merging main's modest starts. The patrol can survive a fight and still be unable to replace its dead because raids reduced the town's taxes and treasury. This is a real possible outcome, not an automatic recovery guarantee.

## Validation

- `tests/guards.gd`: paid formation, pause, local coverage, physical movement, natural contact, bilateral attrition, withdrawal, exact JSON continuation, atomic corrupt-load rejection and unchanged older saves.
- `tests/guards_edges.gd`: declared casualty/funding/contact fixtures isolate healing without resurrection, one paid recruit/day, exact wages, unpaid physical return, destroyed patrol history, paid new formation and NPC victory during player pursuit. Six full 30-day worlds use company-only food/money fixtures to keep the economy running; all councils, guards, raids and freight remain autonomous.
- `tests/guards_ui.gd`: two ordinary seed-1 native journeys with mouse/key controls. First: formation, real field battle, casualty return, town recovery and actual player-funded replacement. Second: intervene in a live fight, deploy against the same wounded band and win using legal tactical AI actions. F5/F9 checkpoints cover movement, combat, return, recovery and assistance. No position, injury, resource or victory fixtures are inserted.
- Farm, bandit, traffic, overworld and ammunition/perk compatibility regressions pass. The integration pack contains exact counts and logs. Screenshots `guards-*.png` are actual native captures, visually inspected.

The historical `tests/world.gd` v0.3/v0.4 migration failures remain. This branch produces byte-identical output to the unchanged earlier baseline: missing `kind` accesses at lines 159/325 prevent that script completing. The timeout/failure is recorded, not counted as a pass. Dedicated current guard/farm saves and the listed compatibility tests pass. Older documents in this source describe their own historical slices, not additional validation performed for patrols.
