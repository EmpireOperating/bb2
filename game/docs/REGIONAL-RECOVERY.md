# Regional recovery preview

This branch adds paid reconstruction, vulnerable relief wagons, local guard priorities and dated town reports to the six-town expanded map. It is a separate integration candidate based on **Prototype 0.36**. It has not replaced or merged into the main Library build.

## Play the preview

Open `project.godot` with Godot 4.4.1 and start **New company**. The **RECOVERY** button below First contract opens the town report. Six town tabs share the existing discovery rules. Reports are collected in person and remain dated after leaving; remote tabs do not reveal live positions or terrain.

The preview uses `user://ashen-company-regional-recovery-preview.json`. Existing saves retain their own capabilities and rules. Loading an older save does not silently enable paid repairs, adaptive guards or relief. Start a new preview company to exercise this feature.

## Implemented loop

| System | Rules |
| --- | --- |
| Reconstruction | A raided farm needs 960 safe three-minute ticks (48 hours of work). The council pays 12 crowns and supplies 6 existing town food once per raid. Work waits for safety and resources, pauses when threatened, and resumes without another charge. |
| Local safety | Living hostile bands within 120 world units block work unless nearby paid guards or a sufficiently strong company cover the farm. An active distant camp alone no longer prevents rebuilding. An active farm raid always stops work. |
| Harvest | Repair completion restores production. Existing physical harvest carts must deliver food before it reaches town. Existing stock-based prices respond to those actual deliveries; no prosperity bonus is applied. |
| Relief | At dawn, a town below three days of food can receive an emergency load when no existing freight is already coming. An eligible donor pays 8 crowns and keeps at least four days of food (minimum 24) plus two days of guard wages. The recipient has a three-day dispatch cooldown. |
| Transport | Relief uses the existing directed trade routes, their full cargo quantities and normal next-day departure. It has first access to spare food before routine dawn launches. There are no new caravan formats, free food or teleporting deliveries. |
| Raids and recovery | Existing roaming bands can intercept, capture and haul relief. Destroying their camp releases identifiable cargo onto its real final journey. Existing escort and recovery contracts continue to recognize these ordinary wagon IDs. |
| Patrols | Paid town guards prioritize their own raided or damaged farm, then incoming freight within their home district. Relief has priority among incoming wagons. They can respond to visible local bands from other camps. Existing wages, wounds, deaths, replacement costs and retreat behavior remain. |
| Reports | Town reports contain their observed stock, price, farm output, repair state and up to three recent relief records. A remote report stays unchanged until the next visit. The report links to the existing farm and guard panels. |

Map labels and caravan detail identify relief wagons. Moving markers remain selectable over town markers, including when a wagon and guard share a mooring.

## Integration boundaries

The original expanded-region pack was built before continuing campaigns. The prerequisite port reconciles it with 0.36: unlimited calendars, weekly recruits and road bounties across all six towns, frozen campaign time during battles, dungeon rest rules and committed escort behavior are retained.

`Campaign.setup` positional flags **11, 12 and 13** are respectively `open_campaign`, `expanded_region`, and `regional_recovery`. In the earlier standalone expanded pack, argument 11 meant expansion; do not copy those old call sites over the 0.36 signature.

Recovery state is `campaign.rebuilding`, distinct from the existing soldier `Recovery` subsystem. Capability wrapper **33** contains `recovery_base_version` (31 or 32) and the version-1 `regional_recovery` component. Validation builds temporary objects before committing a load. It checks town identities, repair work against actual farm damage, food/crown ledger support, shipment identities, dispatch days and report shape. Timestamp normalization preserves exact save/load behavior.

`World.tick(defer_shipments=false)` preserves the old default. A recovery-enabled campaign defers scheduled departures, runs `rebuilding.daily`, then calls `world.dispatch_shipments`. Preserve this order when integrating other daily-world changes. `Guards.restore` receives an optional recovery capability flag for cross-camp target validation; old saves keep their original target restrictions.

No perk, progression, contract-generation or combat-balance design was changed by the recovery feature. The prerequisite expansion port necessarily extends career and road-job town lists. New contracts or a different save wrapper from another branch must be reconciled during integration rather than overwritten.

## Validation

See `regional-recovery-validation/summary.json` and the accompanying logs. **1,996 assertions, zero failures**, across 17 suite invocations. `dungeon_clock` intentionally runs the shared battle-clock suite again; these totals are not 1,996 independent scenarios.

- Recovery model: 44 checks, including real repair charges, physical harvest delivery, relief dispatch/delivery, dated reports, exact JSON roundtrips and atomic rejection.
- Recovery edges: 45 checks, including captured and recovered relief, unavailable food/funds, paid work pausing for a second camp's band, cross-camp guard targets, repair-site holding, zero-time battle settlement and dawn allocation priority.
- Natural observation: 224 checks across two paired seeds, from day 1 through day 46. Only company survival money and rations are supplied. No town food, council funds, camp clearances or NPC casualties are injected.
- Native recovery UI: 21 checks. Actual mouse/keyboard input opens reports, switches services and selects a relief wagon. F5/F9 retains repairs, cargo and local/stale reports. Repair time and harvest deliveries run through the production clock.
- Native expanded-map UI: 27 checks, including camera input, transformed free travel, all six towns, pagination and loading an original fixed map. Full-map render measured about 27 ms/frame on this software-rendered test machine; this is not a hardware performance guarantee.
- Compatibility: expanded map/career, continuing career, camp battles, shared battle clock, farm/guard models, road growth/contracts and hinterlands dungeon paths pass.

Native screenshots beginning `recovery-native-` use declared placement, clearance, completed-freight and surplus-store fixtures to make specific UI states reviewable. Large company resources and full map visibility in those screenshots are test fixtures, not starting-game changes. `recovery-expanded-` captures are this run; older unprefixed screenshots and validation files remain historical evidence from their own versions.

## Economy findings and limits

This proves the interactions, **not a balanced regional economy**. In the untouched-world runs, more farms were repaired, but cumulative food shortages increased. Relief was rare and the one naturally dispatched shipment was seized. These are observed limits, not passing prosperity claims.

| Seed | Recovery | Damaged farms at day 46 | Sum of town shortage-days | Relief outcomes |
| --- | --- | ---: | ---: | --- |
| 1 | Off | 2 | 82 | None |
| 1 | On | 1 | 105 | 1 seized |
| 7 | Off | 3 | 97 | None |
| 7 | On | 2 | 147 | None |

The existing directed trade network limits who can help whom. If a town has no food for repairs and no eligible donor on an incoming route, it can remain stalled. Guard losses and repair costs also matter. There are no automatic bailouts or guaranteed relief arrivals. The next economic tuning pass should address relief reach and reserve allocation, guard survival, and ways to restart an exhausted producer. The controlled clearance and delivery tests prove the recovery path when those real prerequisites are met.

## Reproduce

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/regional_recovery.gd
godot --headless --path . --script tests/recovery_edges.gd
godot --headless --path . --script tests/recovery_observation.gd
```

Run `tests/regional_recovery_ui.gd` and `tests/expanded_region_ui.gd` in a native display with a dedicated `XDG_DATA_HOME`. Their screenshots are written under `docs/`. Compatibility test names and full output are in the validation directory. Some historical test suites regenerate their own evidence; restore unrelated fixture changes before making an integration commit.
