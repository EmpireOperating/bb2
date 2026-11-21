# Physical camp founding

This slice replaces abstract camp reoccupation for newly enabled companies. A camp returns only when a real group reaches an eligible empty site and completes construction. The existing town food ledger, patrols, combat and camp recruitment remain the authorities.

## Player-facing behaviour

A displaced band can carry provisions to a nearby cleared campsite. On arrival it spends six rations and works for twelve campaign hours. It remains an ordinary visible, trackable party, labelled MOVING CAMP or BUILDING CAMP; the company can pursue and fight it. Stronger nearby enemies, guard engagement, hunger, casualties or an occupied destination can stop the attempt. Pause and tactical battles freeze construction. Abandoned construction does not refund food.

A prosperous camp can sponsor an expedition. Each additional person costs the existing eight food and two days of training. The original field party stays assigned to its source camp. The expedition physically leaves carrying provisions and must complete the same journey and construction as displaced survivors. Sending it does not create a second free copy of the home band.

Settlement transfers the founders' member identities, wounds, fallen history and enemy grade into the new occupation. Its world-party ID changes to the destination occupation's normal ID; an explicit source/destination record preserves the move. The old party is retired, not recorded as newly killed. No resident garrison is granted. Later strength growth and replacements still require the existing food payments.

Only completed construction creates the new occupation's named-loot promise. Interrupting builders does not create an occupation or reroll camp loot. Destroying an established camp retains the existing occupation-specific named-drop system.

## First-pass constants

| Rule | Value |
| --- | --- |
| Site choice | Existing generated camp locations only; within 480 world units |
| Minimum group | Two living members, currently fed |
| Clearance respite | Configured reoccupation delay, default four days |
| Site selection | Access to known roads/farms, terrain and actual path travel time |
| Guard knowledge | Local sight only; no query of distant patrol positions |
| Displaced search | Every two campaign hours |
| Provisions needed | Six construction rations plus travel allowance and two days of food per living member |
| Building time | 240 three-minute ticks: twelve campaign hours |
| Abandoned attempt | One-day retry delay; paid food remains consumed |
| Expedition supply | Six rations plus three per recruit, subject to real travel requirements |
| Sponsored expedition limit | One living expedition from each source site at a time |

Building also follows ordinary daily upkeep. Recruiting is allowed only above the source camp's existing population buffer and the additional expedition/training requirements. These are provisional balance values.

## Accounting and persistence

`src/camp_founding.gd` owns plans, retry clocks, paid expedition records and completed founder links. All provisions remain in `World.raider_supply`; construction rations are recorded as eaten, not silently removed. Remaining food is physically returned to the destination's stores and loaded normally after settlement. Expedition populations count against their sponsor's investment buffer while away.

`camp_founding` version 1 and `World.physical_founding=true` must appear together. The optional setup flag defaults false: older saves keep their previous reoccupation behaviour and are not silently migrated. Restore validates the destination generation, exclusive site reservation, phase/payment/timer consistency, paid expedition markers and founder lineage. Partial construction resumes deterministically after JSON save/load.

Hooks are in Campaign setup/snapshot/restore, World reoccupation, Overworld step/sync, Bandits ordering/restore/deployment, CampLife training/assignment, CampRecon resident counts, RaiderNeeds and Traffic/Farm target selection, plus party descriptions. The new occupation's reconnaissance record is created before paid wound care queries its population.

The component deliberately allows defeated historical party records to retain surviving member health when they were retired by relocation; only their new linked occupation can act. Do not sum historical party health to count the current population. Filter retired/defeated world parties first.

## Integrating with Prototype 0.42

The isolated compatibility branch starts from the supplied `Battle-Brothers-2-Prototype-0.42.zip`, not from a replacement of the main build. Its pinned baseline is `7d6f78cc58c25d1d28affc9a7d0324afef23765c`. It preserves the current economy, industry, material freight, regional news, progression and equipment.

That supplied build does not contain the recent recovery, fading tracks, camp reconnaissance and raider-survival branches. The optional 0.42 integration patch therefore contains those dependencies as well as physical founding. The small feature-only patch is instead based on raider-survival commit `aa58cfde08d1b3846af58e6d8f5939c7e2741ecb`. Apply one appropriate route, not both patches to the same base.

The new flag is argument 17 on the feature branch and argument 19 on the 0.42 compatibility branch. Port by parameter meaning. The compatibility order after `open_campaign` is `world_economy`, `expanded_region`, `regional_news`, `regional_recovery`, `fading_tracks`, `camp_reconnaissance`, `raider_survival`, `camp_founding`.

In the 0.42 preview, economy/news are enabled and legacy regional recovery is disabled. Industry already owns farm repair and materials; enabling both repair authorities would duplicate responsibilities. Optional legacy recovery uses wrapper 35 there while legacy wrapper-33 recovery saves remain recognized; ordinary economy/news saves retain 33/34. The old tracking test's wrapper assertion was adjusted accordingly.

Material wagons remain materials: fed, camp-attached raiders can target suitable visible shipments on their camp's route and physically haul them under the existing rules. Hungry/displaced parties seek food; materials never become rations. Camp stock recovery goes through `Economy.claim_camp` once; the older survival salvage path is bypassed in economy companies. Carried field rations remain a separate one-time recovery. Integration tests exercise these combinations with all new capabilities enabled.

The preview uses the separate save filename `ashen-company-physical-camps-preview.json`. This pack does not update the main Library build or deploy anything.

## Validation and observed balance

`tests/camp_founding.gd` covers real travel/building time, paused and deterministic saves, wounds/identity/grade transfer, no free residents, physical expedition recruitment and supplies, interruption, atomic malformed-save rejection and older-save behaviour. Placement, provision and council-spending fixtures are explicitly labelled; no production result is manufactured by the construction loop.

`tests/camp_founding_ui.gd` uses native Godot input with the ordinary three founders and gear. It selects builders, saves and reloads partial construction, completes the camp, then replays the saved construction branch and defeats the real builders through legal combat. Native F9 checks require a successful-load notice as well as exact state equality. Screenshots and raw logs accompany the handoff. Fixtures isolate construction from patrol interference and grant company survival supplies; they do not represent a normal campaign balance test.

`tests/founding_observation.gd` separately runs seeds 1, 7 and 27 for 45 elapsed days with the 0.42 economy, physical guards and regional news. A second branch for each seed retains abstract reoccupation as a control. Both branches receive the same day-six Ford clearance; only the company's survival budget is granted. Daily food/treasury checks and periodic exact JSON restores are required. The complete sample data and final validation summary are packaged.

The observed worlds produced **no natural founding expeditions or reoccupations in either mode**. Physical founding therefore did not cause the observed decline, but this is also not evidence that rebuilding is frequent enough. At day 46 the physical runs retained 8, 4 and 4 living field members (seeds 1, 7 and 27) and 8, 8 and 6 active camps respectively. Camps can remain occupied by residents even when their field band has died. Town food remained conserved, with large stocks accumulating in farming towns. Treat this as a mechanics-complete prototype requiring survival/raiding/guard balance work before treating the map as self-sustaining.

## Deliberate limits

New camps reuse empty generated sites; this slice does not place arbitrary camps anywhere on the map. It adds no separate raider market, trade currency, band merging, external migration, rival factions, diplomacy or resource wars. Camps remain tied to existing road/farm roles. Construction is all-or-nothing; an abandoned site does not retain a reusable progress asset. Source camp `expansions` remains the legacy abstract counter; use `camp_founding.founded` for completed physical moves and `expeditions` for paid departures.
