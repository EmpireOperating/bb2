# Validation — playability prototype 0.9

Tested with official **Godot 4.4.1**, Linux x86-64. Native runs use a 1440×900 window, OpenGL compatibility, Mesa software rendering, and isolated save directories. This validates the source project; it does not establish standalone Windows/macOS exports or final human game balance.

## Final suites

| Suite | Checks | Failures | Scope |
| --- | ---: | ---: | --- |
| `tests/run.gd` | 1,160 | 0 | Core combat and 200 seeded battles |
| `tests/fields.gd` | 486 | 0 | 160 battles across four field/objective combinations |
| `tests/world.gd` | 953 | 0 | Regional policies, paired worlds, political lifecycles, migrations, exact future continuation |
| `tests/company.gd` | 1,192 | 0 | Persistent-company regression and 30 complete campaign attempts, comprising 64 battles |
| `tests/progression.gd` | 80 | 0 | XP, training, scars, service records, replay protection and earlier-save migration |
| `tests/ui_flow.gd` | 46 | 0 | Native causal chain, earned training, NPC resolution and a successful full month |
| `tests/tour.gd` | 28 | 0 | Native escort, partial-cargo recovery, concurrent deliveries and retreat |
| `tests/politics_ui.gd` | 26 | 0 | Native patronage, dispatch, relationships, prices, raids and restart |
| `tests/progression_ui.gd` | 39 | 0 | Native recruitment, earned promotion, perk choice and subsequent combat |
| `tests/scars_ui.gd` | 23 | 0 | Native critical injury, treatment and lasting combat effect |
| `tests/formations.gd` | 563 | 0 | Orders, atomic group movement, exact hit arithmetic, actual enemy-role actions, migration and 120 paired-policy battles |
| `tests/formations_ui.gd` | 31 | 0 | Native line order, advance, gap, spacing, hit report, reload and complete battle |
| `tests/relationships.gd` | 123 | 0 | Bonds, grief, hardship, paid decisions, migration, replay protection and 80 paired ridge battles |
| `tests/relationships_ui.gd` | 42 | 0 | Earned comradeship, natural death, later morale penalty, support, hunger, mediation and extra meal |
| `tests/playability.gd` | 42 | 0 | Exact read-only forecasts, one complete escort, actual feedback deltas and guide persistence |
| `tests/playability_ui.gd` | 33 | 0 | Guided first contract, travel/rest quotes, combat feedback, full record, restart and actual unpaid-disband warning |
| `tests/balance_review.gd` | 666 | 0 | 160 paired field experiments and 60 month attempts comprising 132 company battles |
| **Total** | **5,533** | **0** | **917 model battles, 14 complete native battles and two confirmed retreats** |

Of the 917 model battles, **797 use the shipped rules, 40 use the frozen v0.7 engine and 80 use an experimental reduced line bonus**. The last two groups are explicitly comparative evidence, not shipped behavior. Other frozen earlier-version suites are retained for reference and are not included. Test counts include daily accounting and save/load checks, not 5,533 distinct gameplay scenarios. Diagnostic probes, retries and the release smoke battle are excluded.

## Playability evidence

Travel/rest forecasts create a separate campaign from the complete snapshot, execute the actual action there, and summarize the result. Tests compare day, location, cash, food, arrears, consecutive unpaid days, ending and individual readiness with the actual action. Viewing the forecast preserves the original snapshot and RNG. Cases include hunger, debt, medicine-assisted healing, wounds without medicine, independently resolved/expired work, illegal escort detours and a two-day journey ending at its origin after the first day. An actually won escort supplies the delivery case: its payment correctly precedes arrival wages.

Feedback tests compare emitted HP, armour, padding and morale values against real before/after state. A recovery with only 11 fatigue reports 11 removed rather than the maximum recovery allowance. Breaking a live ordered shield link produces both the transient warning and a saved record entry. The record round-trips exactly. Feedback does not roll damage again, grant actions or change tactical state. Positioning prevents overlapping labels; stale gap labels disappear when the link is restored.

Guide checks distinguish enemy commands from player practice, retain optional progress separately from gameplay, and safely reset missing or malformed UI metadata. Old v0.8 campaign/battle schemas remain valid; guide metadata is optional, and old saves start with hints hidden.

### Native opening and cost warnings

Seed 7392 starts through normal New Company controls. The player opens/hides/reopens the guide, inspects a rest plan without changing state, accepts the ford clearance and travels at exactly the quoted cost. Clicked movement, a paid shield order with an actual adjacent link, fatigue recovery and safe cancellation of retreat advance the guide. F5/F9 preserves both lessons and battle state without replaying old labels.

The first legal strike is made through native soldier/hex input. Real subsequent combat produces damage feedback; the full battle record opens and survives reload. The battle ends in victory with five survivors. The company plan lists actual missing HP, repairs and earned training. Resting through that screen applies the quoted cash and readiness result, and restart restores the company and guide.

A separate new company then performs 21 ordinary rest days, reaching two unpaid days without fixture grants. Its native planner warns that another day ends the company. Selecting the two-day ridge road predicts disbanding before arrival, retaining Ashwick as the last camp. Taking that trip produces the exact predicted ending, location and arrears. This verifies a warning and its consequences; it does not make the risky action unavailable.

Player tactical turns between the explicitly clicked commands use legal automated commands and normal enemy scene processing. No tutorial health, damage, resources or victory grants are used. Native testing proves the flow works; human enjoyment and unassisted comprehension remain untested.

## v0.9 balance investigation

The same 20 seeds and legal opening-order policies were run with shipped support (+5 per neighbour, cap +10) and a test-only reduction (+3, cap +6). Both companies receive the same rules. The simple player policy does not deliberately maintain a line.

| Field / opening order | Shipped wins / losses | Reduced-support wins / losses |
| --- | --- | --- |
| Forest / Free | 6 / 14 | 10 / 10 |
| Forest / Line | 20 / 0 | 19 / 1 |
| Ridge / Free | 17 / 3 | 17 / 3 |
| Ridge / Line | 19 / 1 | 19 / 1 |

All 160 finished without draws. The reduced bonus barely changes the dominant forest-line result, also weakens enemy lines, and leaves this ridge sample unchanged. It is not enabled in the game. Forest terrain/AI/stance interactions need broader tactical policies and human observations before further tuning.

The month comparison uses the same 30 seeds and route schedule. Its alternative policy spends earned training, buys needed food, keeps five days of wages before optional hires/tools/medicine, avoids unnecessary supply buying beyond the month's end, and stops optional equipment/recruit spending once the region is secure. It can also stop its route once the world is secure. These are bundled policy differences, not an isolated five-day-reserve experiment.

| Outcome over 30 attempts | Fixed spending | Reserve-aware spending |
| --- | ---: | ---: |
| Successful month | 15 | 17 |
| Month ends short of objective | 6 | 8 |
| Unpaid disband | 9 | 5 |

The 60 attempts contain 132 battles. All use actual company purchases, wages, legal combat and world decisions. The result supports exposing the cost of recruitment and optional spending; it does not prove the campaign is balanced or that five reserve days are optimal. Shipped prices, wages, combat bonuses and AI decision rules remain unchanged from v0.8.

## Relationship and objective evidence

Model fixtures verify survival and threatened-line trust, the once-per-battle limit, retreat friction, grief duration and the three-battle natural recovery path. They exercise actual morale reduction, the two-comrade cap, range loss and Steadfast ordering; a legal lethal strike verifies the additional comrade death shock. Separate settlement fixtures isolate death, deployment IDs and repeated awards. These fixtures are explicit and do not stand in for naturally won battles.

Actual upkeep creates hunger, unpaid wages, strain and repeated hardship. Tests check the bounds, paid recovery, full-company wages and arrears, rations, meal limit and repeated-action refusal. Support preserves the dead partner's history; mediation cannot buy positive trust. JSON round trips retain effects and decision limits. Invalid trust/history sums, grief attached to living people, strain, duplicated ledgers and mismatched active-battle comrades are rejected. Version 0.7 migrates with neutral relationships while preserving progression and RNG.

The ridge comparison runs identical armies and 40 seeds through the frozen v0.7 battle engine and the current one, using the same simple legal-command policy. Defender victories fall from **40/40 to 33/40**, with seven defeats and no draws. Those seven losses are combat defeats, not captures of an occupied banner. A separate abandoned-ridge scenario verifies that enemies move legally to the objective and capture it by round six. The change strengthens objective-target and position scoring and delays distant enemy line orders; it adds no troops, damage or free actions.

The relationship native journey below establishes the visible bond → natural loss → later morale consequence → paid support chain. Maximum grief/strain combinations and natural three-battle grief expiry are model checks, not separate native journeys.

## Formation and enemy-command evidence

Model fixtures establish that orders charge each soldier 2 AP / 4 fatigue; normal line movement adds 1 AP per hex; group movement charges each member's actual destination terrain. A simultaneous advance can occupy a selected ally's vacated hex. An unselected occupant, engagement, water, map edge, duplicate selection, insufficient AP or fatigue refuses the whole command without partial movement or cost.

Actual hit calculations verify stacked shield support, the additional ordered-line bonus, a spear thrust over an ordered shield, loose-order arrow protection and its melee penalty. Moving or routing a supporter removes the corresponding bonus immediately. A soldier can move back into position on a later turn and restore the link. Every displayed modifier is summed and compared with the real 5–95% attack chance.

Separate explicit enemy fixtures execute normal commands: a shield moves ahead of its archer; a spear prefers the screened second rank; a trapped bow withdraws with the ordinary AP charge and opportunity strike; an axeman routes around two shields over several turns and attacks a wounded bowman. These establish the specific behaviors under controlled positions, not universal tactical competence. No test grants the AI free movement, damage or actions.

Mid-enemy-turn plans, focus, roles, formation orders, costs, RNG and subsequent commands match exactly after JSON restore. Corrupt orders and target IDs are rejected atomically. Version 0.6 camp and active-battle snapshots upgrade to version 0.8 without changing soldier progression; old battles receive Free order, neutral social state and no fabricated plan. Subsequent enemy decisions use the new AI.

The 120 paired-policy battles start from the same seed and company for each policy; the only initial intervention is a legal paid opening order. Subsequent player turns use the existing simple action policy, which does not deliberately maintain its line. These measure consequences and state integrity, not optimal human tactics.

| Field · 20 seeds per policy | Free order: W/L/D | Shield line: W/L/D | Loose order: W/L/D |
| --- | --- | --- | --- |
| Ford capture | 9 / 11 / 0 | 1 / 19 / 0 | 6 / 14 / 0 |
| Forest elimination | 6 / 14 / 0 | 20 / 0 / 0 | 8 / 11 / 1 |

The sharp differences expose unfinished balance and policy limitations: a slower line can lose the capture race, while protected second-rank fighting can dominate this forest policy. Passing these tests does not establish that every stance is equally useful or that the AI always makes a good decision.

## Progression and individual identity

Model checks exercise each perk through legal combat commands: Shield drill changes shieldwall defence and fatigue, Weapon handling changes attack odds and fatigue, Second wind changes recovery, and Steadfast changes actual morale loss and routing. Critical-injury fixtures separately verify all three scar types, no duplicate scars, the two-scar limit, and their next-deployment effects. A temporary wound can heal while its permanent scar remains.

Settlement fixtures verify distinct battle/contract XP, per-kill caps, rank thresholds, available training points, the level-4 cap, a maximum of three selected perks, and no repeat awards after replay or JSON round trips. Late hires receive no bonus for contracts signed before they joined. Death preserves previous XP, scars and service records; a fallen soldier's unused choice cannot be spent. A replacement gets a new identity and begins at zero.

Version 0.5 camp, active-battle and aftermath saves migrate without replacing the company, world or battle state. Earlier service receives one explicit credit from recorded battle/kill totals, with unchosen perks and no invented scars. Saving and reloading cannot repeat that credit. Earlier deaths and the current-day migration summary retain chronological order. Version 0.2–0.4 migration remains covered by the world/company suites.

The native progression journey described below reaches level 2. Higher ranks and all perk/scar combinations are covered by model checks, not claimed as separately completed native campaigns.

## Controlled regional comparison

Two world models began with identical state. One received a single ford clearance on day 1; the other received no intervention. Both then ran autonomously to day 31, including all council, caravan, patrol and raider decisions. Clearance here is a model fixture to isolate causality; actual company combat and patronage are exercised separately through native controls.

| Stonecross result after 30 daily ticks | No intervention | Ford cleared once |
| --- | ---: | ---: |
| Food delivered | 30 | 344 |
| Days with unmet food demand | 25 | 0 |

In the intervened world, another band paid to reoccupy the ford on **day 16**. There was no return timer. Treasury income and later patrol decisions diverged as deliveries changed. Intervention did not solve every threat: the ridge still launched five town raids in each of these two runs.

A separate full-month check destroyed every band and confirmed that none spontaneously returned. Another pair compared an uninterrupted world against a world saved/reloaded after every daily tick; their subsequent IDs, accounts, decisions, cargo and event histories matched exactly.

## Resource and lifecycle checks

Food invariant:

**town stocks + undelivered wagon cargo + loose raider stores = initial food + production − town consumption − company purchases − raider spending/destruction.**

Council invariant, per council:

**treasury = starting treasury + taxes + delivery tolls + patronage − patrol spending − raid losses.**

Both are checked through full regional policies: no intervention, one clearance, repeated clearance, heavy purchasing, shipment recovery and a reserved escort. JSON round trips preserve the complete state.

Additional checks cover:

- Recruitment spends 36 food from a genuinely seized load; only unspent cargo can be recovered. Empty cargo cannot be recovered or paid twice.
- Funded expansion creates a new generation. A stale generation cannot clear it; clearing all bands prevents respawns.
- Town raids transfer actual food, remove actual treasury crowns, and affect subsequent taxes.
- Company patronage transfers 90 crowns, queues a selected road, and cannot be overwritten by another purchase while pending.
- A council buys its patrol and pays its daily wages. Equal strength covers traffic without destroying the band. An unpaid patrol withdraws.
- NPC resolution and exhausted cargo cancel accepted work neutrally, without a reward, completed-contract credit, or reputation penalty.
- Positive/negative reputation changes real supply and contract quotes. Distrust blocks escort work while leaving clearance available to rebuild trust. Abandonment incurs one penalty.
- Patrol movement, orders, accounts, reputation and future decisions survive save/load. Corrupt accounts, duplicate active patrols, invalid ownership and invalid reputation are rejected without partial mutation.
- 0.2/0.3/0.4 migration preserves company state in camp, battle and aftermath. 0.4 reserved escorts migrate in all three phases without paying unfinished work or replacing cargo.
- Permanent deaths, wound treatment, individual gear, repairs, recruit identity and idempotent battle settlement retain current-version regression coverage.

Explicit fixtures are used in model tests to isolate settlement, corruption and outcome rules. They are not presented as naturally won battles.

## Native journeys

### Comradeship, loss and the next fight

Two normal New Company confirmations select seed **7393**. Aldric and Bram survive an escort and W003 recovery, using paid line orders under actual threat. By day 10 their trust is **4**. Their native companion screen shows the two dated causes; F5/F9 preserves the bond.

In the third completed fight, W009 recovery at Cairn Ridge, **Bram dies naturally**. Aldric survives with three further battles of grief and next-deployment morale **81 instead of 85**. His companion screen retains Bram's trust and marks him fallen. The company then takes a ridge clearance and deploys into a fourth actual battle: Aldric's unit and sidebar both show 81 morale and a four-point grief penalty. Saving and reloading preserves it.

The player confirms retreat before fighting that fourth battle. Grief remains at three and no battle XP is paid. A native **Support grief** decision spends an ordinary day of company wages and rations, clears one loss and preserves Bram's bond and history. The now-inapplicable support button is disabled; scene restart restores the exact state.

A separate fresh company rests 17 normal days. Its original rations run out, two hungry days produce strain **2**, and Aldric/Bram trust becomes **−1**. Mediation is disabled while food is unavailable. Buying 24 rations costs 24 crowns. Mediation then spends one day, **36 crowns and six rations**, bringing trust to zero and strain to one. An extra meal consumes six more rations and removes the last strain. Final resources are **28 crowns and 12 rations**, preserved by restart. No fixture grants, forced kills or synthetic victories occur in either native sequence.

### Form, advance, break and reload a line

A new company accepted and travelled to the ford through normal controls. The formation screen selected its four shield/spear soldiers and issued a line order, leaving each at **7 AP / 4 fatigue**. Bram and Tostig's adjacent shields produced the actual extra support. A native eastward group advance cost each **3 AP / 9 more fatigue**, preserved the link and moved all four exactly one hex.

A subsequent individual move separated Bram and Tostig and removed both line bonuses. F9 restored the linked positions, orders and spent resources exactly. An ineligible mixed order changed nobody. Edda adopted Loose order while spaced, then moved beside Merek and lost the arrow protection. The native hit report displayed the simulation's arithmetic. The real enemy turn assigned a shared focus and roles; the battle ended in victory, settled once and survived scene restart.

### A recruit's training survives her death

Seed 7392 completed a real escort. Natural vacancies allowed normal recruitment on day 8. **Ida, deserter, soldier ID 6**, joined at 0 XP. Recovery of W003 at Brackenwood earned her 30 battle XP and 10 contract XP: **level 2, 40 XP**.

The service screen selected **Shield drill**, saved and reloaded it, and refused a second choice without another point. A later W009 recovery at Cairn Ridge deployed the same recruit and perk. Guarding through native controls used **4 AP and 10 fatigue**; F5/F9 preserved that effect. Ida died to Ivar in that second personal battle on day 16. Her two battle records, selected perk and earlier **40 XP** remained, with no new combat or contract XP on death. Restart restored that memorial exactly. Fallen Bram's record was also readable and untrainable in this journey.

This journey completed three battles including the opening escort. All recruitment, provisions, travel, contract selection and training used normal controls. The updated AI changes who survives; tests check the actual saved outcome rather than assuming the previous release's casualty list.

### A scar outlasts treatment

Seed **7400** was selected through repeated normal New Company controls. Bram survived the ford at **1 HP** with a three-day deep wound and **Damaged lung**. Three ordinary treatment days restored him to **55 HP** and removed the temporary wound; the scar remained in his service record and save.

In the next real ridge battle, a legal step and guard generated 21 fatigue. The actual enemy turn ran; Bram began his next turn with **1 fatigue** because his damaged lung removed only 20, rather than the usual 25. Save/load preserved that state. He died later in the second battle; his scar and service record remained readable. Other allies were deliberately left idle in the first turn to isolate fatigue recovery; this is not a balance benchmark.

### Full campaign

Seed 7392, created through the New Company controls, completed day 30 with **two company contracts won, all bands removed, six living soldiers, two permanent memorial entries, 102 crowns and no arrears**. The secured-region ending correctly accepts fewer than four wins.

The company fought the ford and ridge. Patrols resolved the forest threat independently, withdrawing its accepted clearance without a reputation penalty. The test used normal travel, purchases, recruitment, repair, treatment and company upkeep. It spent earned training through the native service screen before later fighting. It restarted the main scene and restored the exact final company/world snapshot.

The previous untrained itinerary lost the ridge and disbanded on day 23 under the new rules. Updating the itinerary to use earned training produced the successful month above; game stats and resources were not changed to force the result.

The first ford battle also retained the supply-chain proof: a real wagon was seized while the company travelled; clearance freed its food; later shipments crossed the cleared road and replenished Stonecross. Seized state, active battle and settled aftermath survived F5/F9 without duplicate pay or cargo.

### Patronage and neglect

Through the council screen, another company paid 90 crowns to direct an Ashwick patrol to the ford. Wardens reputation rose by 4; Guild reputation fell by 1. A second queued order was refused. The funded patrol departed on day 2, arrived on day 3, cleared the weaker band and released W001's 48 food. The council recorded 90 dispatch crowns plus 6 wages; Stonecross recorded 24 toll crowns. The untouched twin instead retained a seized wagon and a stronger band.

The native test checked the adjusted purchase quote, actual payment, in-flight patrol reload, neutral cancellation of the company's now-obsolete clearance, and exact restoration after scene restart. A fresh company then ignored the world until day 16 using ordinary rest controls; raids and lost town food appeared in the region and council screens without fixture grants.

### Escort and recovery

An actual escort contract reserved W001, waited with the company, reached the ford ambush and completed its eight-round defence. Defence alone paid zero. Delivery to Stonecross paid the quoted contract once and changed reputation.

The company then recovered W003 at Brackenwood. Six of its original 30 food had already been consumed: **24 remained**. W003 and the separately patrol-protected W006 both arrived on day 10. The test accounted for each shipment independently, retained the wider band, and reloaded the aftermath without duplicate goods, money or reputation. A fresh escort also exercised cancelled and confirmed retreat; confirmed retreat lost its cargo and paid nothing.

All campaign mutations used normal UI input. Player tactical turns were automated through legal AI commands and normal enemy scene processing. Animation clocks were accelerated. Native journeys did not grant health, resources or victories.

## Balance and release boundaries

The final fixed-itinerary model policy produced **15 successful months, six below the objective and nine unpaid disbands** across 30 attempts. The policy selects earned training in camp without extra resources or XP. Only 64 company battles occurred because autonomous patrols sometimes removed targets first. These are automated-policy outcomes, not estimates of human difficulty.

Equal-strength field results are: ford capture 22/40 victories, forest elimination 9/40, ridge defence 33/40, and wagon defence 25/40. Core combat produced 107 victories and 93 defeats over 200 runs. Ridge defence remains favorable to this policy; forest elimination, formation tradeoffs, escort defence and social/economic pressure need human playtesting.

Native screenshots cover formation selection/cost previews, shield links and gaps, loose crowding, hit breakdown, enemy turns, service/perk cards, histories, scars, memorials, map, councils, patrols, trade, battle/aftermath, raids, equipment and the final month. Relationship journeys retain coverage for bonds, hardship, paid support and later grief. This release visually checks the opening guide, company readiness, travel forecast, combat labels, full record, survivor care and fatal travel warnings. Final native logs contain only the virtual display's unsupported V-Sync warning and no script/runtime errors.

Release verification includes a CRC check, extraction into a fresh directory, a clean Godot editor import, and a smoke battle from the extracted source. Smoke mode never reads or writes a player's save.

Councils currently have fixed settlements and commercial rivalry. Territory conquest, wars, treaties, population dynamics, final art/audio and exported platform builds remain outside this milestone.

The campaign remains limited to 30 days and six living soldiers. Art is placeholder geometry. Training has no respec and scars have no treatment/removal. Relationships use deterministic shared events and capped morale effects; authored companion dialogue, personality-driven disputes and branching personal quests are not implemented. This archive contains the source project, not platform executables.

There is no facing, directional shield arc, formation rotation, preset deployment rearrangement or multi-turn group pathfinding. The AI shares a pressure target and uses role-aware local scoring; it does not search future turns.
