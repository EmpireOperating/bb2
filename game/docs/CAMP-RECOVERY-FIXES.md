# Camp recovery without forced respawns

This pass fixes two decision deadlocks. It does not add free raiders, food, a new economy, or a guaranteed respawn interval.

## Why the seed-1 camp stayed empty

The previous sustained-raiding build did recruit founders. High Pass Outlaws paid sixteen food to train two people on day 11; they finished on day 13. No expedition departed because its launch check counted those people twice: in the camp's three-day resident buffer and in their fourteen-ration travel/construction pack.

The actual previous-build day-13 save is included as `tests/fixtures/Camp-Recovery-v3-day13.json`. It was exported from commit `f6862eb8db247ebc6b567fe2052330fd5e37c901` using ordinary elapsed simulation, with only the declared day-6 camp/field-band wipe and company survival grant. The unit test reproduces the blocked decision directly from this save.

| Day-13 sponsor budget | Rations |
| --- | ---: |
| Actual food held | 26 |
| Actual route/construction provisions | 14 |
| Protected buffer for people remaining at home and other field members | 8 |
| Correct total requirement | 22 |
| Previous requirement, including six duplicated resident-buffer rations | 28 |
| Food remaining at the sponsor after the fourteen-ration transfer | 12 |

The corrected check subtracts the departing, already trained residents from the home buffer. Their carried supplies cover their upkeep. Untrained people still cost eight food each and two days of training; training upkeep and all other mouths remain budgeted. Being one ration below the corrected requirement still refuses launch without side effects.

Under the old decision, the trained people stayed home consuming food while the sponsor waited for unnecessary extra reserves. The ninety-day control reproduces the absence of founding. Under the corrected rule, the same unassisted seed-1 world completes construction on day 17.

## Failed expeditions can try again

Previously, a surviving failed expedition blocked its sponsor from creating another expedition but had no return/reprovision/retry behavior of its own. The new rules reuse that paid party:

- A stronger visible company or funded patrol still takes precedence and can force retreat.
- Survivors physically return to their active sponsor. No remote refill or teleport occurs.
- At home, available supplies feed them; a new departure requires real route provisions and the other residents' protected buffer.
- The existing twenty-four-hour retry delay still applies. Target eligibility, distance, pathfinding, visible guards, construction time and food costs remain unchanged.
- A second attempt keeps the original people, wounds and expedition record. Failed construction does not refund spent food.
- A lone survivor cannot found a camp and no longer permanently locks the sponsor's future paid recruitment. That survivor remains an actual living party. If the sponsor is destroyed, survivors use the existing displaced-band behavior.

Regrouping expeditions do not claim passing freight while returning. Ordinary raiders keep the sustained-raiding food/material priorities from the preceding pack.

## Compatibility and integration

This is a separate branch, `world/camp-recovery-deadlocks`, based on the sustained-raiding handoff at `f6862eb8db247ebc6b567fe2052330fd5e37c901` (base tree `7adc7a60163babd56f3e96fddacda688e7c69f35`). It is incremental on that handoff, not on plain Prototype 0.42. Preserve newer changes from other chats when merging.

Production edits are limited to `src/camp_founding.gd`, `src/raider_needs.gd`, and the preview save filename in `src/main.gd`. The campaign setup signature and founding snapshot structure are unchanged. New companies select `raider_needs.version = 4`; version-1, version-2 and version-3 saves retain their original rules rather than silently upgrading. The preview uses `ashen-company-camp-recovery-preview.json`. Keep the destination build's intended save slot when integrating.

`tests/fixtures/Sustained-Raids-v3-start.json` preserves the actual preceding initial state. The new suite verifies its exact historical factory and continuation, while the earlier survival/recovery/sustained suites retain their respective rules.

## Validation method

Godot 4.4.1. Model tests check both process exits and script-error output. Native X11/software-GL tests use the real UI, normal campaign clock and F5/F9; a load must report success and match the full snapshot exactly. Screenshots are inspected visually.

The native recovery journey explicitly loads the real blocked day-13 fixture with the new rule selected for comparison; this is not user-save migration. Normal daily decisions launch the founders. Company-only viewing/threat placements expose and interrupt the actual travelling party. The survivors then return, resupply and retry through ordinary simulation. Paid patrols retain their ability to interrupt attempts. The separate native founding suite verifies completed construction and legal player combat against builders.

Ninety-day observations retain the full town economy, farm repair inputs, industry, material freight, council funding and physical patrols. Only the observing company receives survival food/crowns. Clearances are declared outcome fixtures, not player-combat simulations. The `wipe` case clears wilderness camp `wild_0` and its field members on day 6. The `repeat` cases do so on days 6, 30 and 60; if that site remains empty, the nearest active camp is cleared instead. Each recorded clearance states whether an active occupation actually existed. The `suppress` case clears every camp and field band on day 6, testing that the world does not manufacture a recovery source.

Every daily boundary checks world/farm food conservation; exact JSON restores occur every twenty days. Raw reports retain sponsor refusal reasons and budgets, real founding lineage, clearance history, town stocks, field population, raid totals, and route shipment outcomes. Nearby-band counts are observations within 180 map units of the original wilderness site; an empty camp alone is not a guarantee of safe travel.

## Final results

**3,568 checks across 31 final test runs passed**, with zero failures or script errors, plus completed asset import. Seven ninety-day observations cover 630 campaign days across five map seeds. There are 21 model suites, three native UI runs (61 checks), and seven observation runs.

| Seed / rules / scenario | Completed camps | Paid expeditions | Retry departures | Farm raids after day 60 | Living field members at day 91 | Delivered trade shipments |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 / v3 / wipe | 0 | 0 | 0 | 7 | 14 | 241 |
| 1 / v4 / wipe | 1 | 1 | 2 | 7 | 18 | 240 |
| 1 / v4 / repeat | 3 | 3 | 2 | 6 | 18 | 241 |
| 7 / v4 / repeat | 0 | 3 | 4 | 3 | 16 | 238 |
| 27 / v4 / repeat | 0 | 2 | 13 | 2 | 12 | 225 |
| 42 / v4 / repeat | 1 | 2 | 2 | 7 | 14 | 262 |
| 99 / v4 / suppress | 0 | 0 | 0 | 0 | 0 | 212 |

The seed-1 old-rule control remains empty through day 91. The corrected single-wipe case rebuilds on day 17. Repeated seed-1 wipes on days 6, 30 and 60 are followed by founding on days 17, 54 and 85: eleven, twenty-four and twenty-five days with that camp empty. Those are measured occupation gaps, not guaranteed safe-route intervals or configured respawn times.

Seeds 7 and 27 funded and retried expeditions but completed no new camps within their ninety-day repeated-clearance windows. That outcome is retained, not overridden by a timer. The reports expose food shortages, field losses and available-target decisions; this pass does not claim that every unsuccessful expedition was caused by the same obstacle.

The full-suppression seed-99 case retained zero living field members and zero active camps after its day-6 clearance, with no replacement expedition or founding. Trade continued. No run sampled a town at zero food at a daily boundary; this does not exclude shortages between samples.

The native recovery test passed 26 checks: real daily launch, physical return, actual resupply/retry, unchanged member identities, pause and exact F5/F9. Its retry was then interrupted by an actually visible, stronger, funded patrol. The separate native founding regression passed 21 checks, including completed construction and legal combat against builders; the sustained-raiding UI regression passed fourteen.

Final logs and machine-readable results are in `docs/camp-recovery-validation/`. Historical fixture-export evidence is included separately and is not counted as one of the 31 final runs.

## Reproduction

```sh
godot --headless --path . --import
godot --headless --path . --script tests/camp_recovery.gd
godot --headless --path . --script tests/camp_recovery_observation.gd -- 1 3 90 wipe
godot --headless --path . --script tests/camp_recovery_observation.gd -- 1 4 90 wipe
godot --headless --path . --script tests/camp_recovery_observation.gd -- 1 4 90 repeat
godot --headless --path . --script tests/camp_recovery_observation.gd -- 7 4 90 repeat
godot --headless --path . --script tests/camp_recovery_observation.gd -- 27 4 90 repeat
godot --headless --path . --script tests/camp_recovery_observation.gd -- 42 4 90 repeat
godot --headless --path . --script tests/camp_recovery_observation.gd -- 99 4 90 suppress
```

Run `tests/camp_recovery_ui.gd`, `tests/camp_founding_ui.gd` and `tests/sustained_raids_ui.gd` with a real display, compatibility rendering and a 1440-by-900 window.

## Limits

Recovery remains conditional on surviving people, reachable sites, food and successful travel. The selected seeds and ninety-day windows do not establish permanent economic equilibrium. Daily town-food samples cannot exclude transient shortages between samples. Repeated player decisions, alternate seeds and longer campaigns remain playtest work.
