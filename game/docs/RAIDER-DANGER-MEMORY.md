# Raider danger memory — isolated integration handoff

This change gives each band a small, temporary memory of stronger forces it actually sees. Surviving founders can avoid a recently dangerous approach, choose another eligible campsite, or wait at their sponsor until a safe, funded departure is possible. It does not guarantee that a camp returns.

## Rules

New companies use raider-needs version 5. A band remembers at most four areas, each containing a last-seen position, campaign tick and threat kind. A visible stronger company or a visible, paid, active stronger town patrol supplies the observation through the existing flee decisions. Nearby observations within 64 map units refresh one area. Other bands receive no broadcast and newly recruited expeditions start with no personal observations. Actual founders retain their memories when their existing member identities move into a new camp occupation.

An area discourages travel within 96 map units during the first day, 64 during the second and 32 during the third. It expires after 1,440 campaign ticks (72 hours). Pause stops the clock; loading restores its original age. These are provisional tuning values, not a permanent territorial claim. Records contain no actor ID and never follow an unseen company or guard.

Founding and regrouping travel uses the existing terrain grid and road costs with a temporary local exclusion mask. Each changed cell is restored before the route query returns, leaving company, guard, freight and other bands' paths unaffected. A band already inside a remembered area can leave: the mask is limited by its starting distance, with grid-scale slack for off-centre positions. This is approximate avoidance, not an exact geometric barrier. Immediate flight and active patrol combat keep priority. Recording a sighting does not invalidate an already active flee path or change its replan cadence. Ordinary scouting, food raids, foraging and cargo hauling retain their existing travel decisions; resource-seeking bands still react to stronger forces they can currently see. This keeps personal caution from blocking the food flow that pays for future founders. A blocked crossing yields no movement until the route becomes usable; there is no teleport or forced path through it.

Founding evaluates the band's own cautious route and charges its actual travel duration to the existing food calculation. Unreachable or unaffordable approaches are rejected. A failed funded expedition physically returns, waits for its normal recovery delay, then considers eligible sites again; it can stay home if none is safe and affordable. Newly recruited founders plan using static site knowledge, then respond to what they encounter themselves. V5 founding no longer queries a distant live guard through a candidate site's coverage radius.

The visible band description adds “Wary of recently seen danger.” It reveals no threat coordinates or hidden actors to the player. There are no new player orders, economy currencies, spawn grants, combat bonuses or patrol nerfs.

## Integration and compatibility

- Branch: `world/raider-danger-memory`.
- Required base: camp recovery fixes commit `02faea6b65237367f090aef605a6aad4b2f7e210`, tree `84a4cfd41f22283acdab47aa991af38f94ade88c`.
- New helper: `src/raider_danger.gd`.
- Behavior hooks: `src/raider_needs.gd`, `src/bandits.gd`, `src/overworld.gd`, `src/camp_founding.gd`.
- Preview save slot: `src/main.gd` uses `ashen-company-raider-danger-preview.json`. Preserve the destination build's intended save slot when merging.
- Campaign setup signature, world food ledger, band member schema and founding snapshot schema are unchanged.

Version-5 raider-needs snapshots add a `danger` dictionary beside the existing version/camps/bands fields. Restore validates band IDs, bounded record arrays, coordinates, threat kinds, ordered nonnegative observation times and future-time rejection. Coordinates are normalized through the same Vector2 precision used by map movement, preserving fractional positions across JSON roundtrips. Versions 1–4 retain their prior snapshot shapes and decisions; there is no silent migration. Tests explicitly selecting v5 for old fixtures are comparison fixtures only.

The source preview includes earlier overworld work. The patch is only the difference from the required base and is verified by applying it to an isolated index and comparing the resulting tree. This does not establish a conflict-free merge into the other chat's newer build. No main branch or preceding integration pack was replaced.

## Validation scope

`tests/raider_danger.gd` covers actual company/patrol perception, negative visibility/funding/power boundaries, personal knowledge, unchanged ordinary flight cadence, ordinary food-return access, memory capacity and expiry, blocked-crossing waits, safe detours, physical escape from a remembered area, terrain-aware extra travel-day provisioning, nearby unsafe-site rejection, alternate campsite choice, funded waiting, identity preservation, settlement inheritance, pause, exact JSON continuation and atomic corrupted-save rejection.

The routing tests declare a flat/hill/corridor geometry fixture; they do not claim that every generated map has a detour. Founding branch tests explicitly declare old encounters and eligible alternative sites. The real preceding-build day-13 save still supplies the paid founders and resources used to test waiting and retry. New-world regressions and long observations keep generated terrain and ordinary town/camp stocks.

The native UI journey starts from that real paid-founder fixture with v5 explicitly selected. Ordinary daily decisions launch the founders. Company-only placement creates a real observed stronger threat; the expedition's location and supplies are not edited. The test follows physical return and waiting, selects the band on the map, checks the displayed caution, exercises pause and F5/F9, and advances until the unrefreshed encounter expires. Screenshots are native rendered game frames, not mockups.

Five 90-day world observations use seeds 1, 7, 27, 42 and 99. The first four clear a camp on days 6, 30 and 60; if the requested camp is already empty, the fixture selects the nearest active alternative. Seed 99 clears every camp and defeats every roaming band on day 6. A declared company-only survival grant prevents the observer starving; towns, farms and raiders receive no added resources. Food ledgers are checked daily and exact save/load every twentieth day. Reported town food is sampled at daily boundaries and cannot exclude shortages between samples.

## Final results

**3,439 checks across 30 final runs passed**, with zero failures or script errors, plus completed asset import. There are 22 model suites (2,894 checks), three native UI journeys (55 checks), and five 90-day observations (490 checks; 450 simulated days).

| Seed / scenario | Completed camps | Paid expeditions | Retry departures | Farm raids after day 60 | Living field members at day 91 | Delivered trade shipments |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 / repeat | 3 | 3 | 2 | 6 | 18 | 241 |
| 7 / repeat | 0 | 3 | 4 | 3 | 16 | 239 |
| 27 / repeat | 0 | 2 | 4 | 3 | 14 | 228 |
| 42 / repeat | 2 | 4 | 4 | 6 | 14 | 262 |
| 99 / suppress | 0 | 0 | 0 | 0 | 0 | 212 |

Historical v4 comparisons use the preceding committed handoff’s raw observations, included in this source. They are comparison evidence, not additional final test runs. The repeated-clearance fixture can choose a different active camp on days 30/60 after the worlds diverge, so these are whole-scenario comparisons rather than an isolated estimate of memory’s effect on one camp.

| Seed | Prior v4 camps / retries / late farm raids | V5 camps / retries / late farm raids |
| --- | --- | --- |
| 1 | 3 / 2 / 6 | 3 / 2 / 6 |
| 7 | 0 / 4 / 3 | 0 / 4 / 3 |
| 27 | 0 / 13 / 2 | 0 / 4 / 3 |
| 42 | 1 / 2 / 7 | 2 / 4 / 6 |
| 99 | 0 / 0 / 0 | 0 / 0 / 0 |

Seed 1 rebuilds the cleared camp on days 17, 54 and 85, matching its prior v4 recovery sequence and preserving late raiding. Seed 27 reduces retry departures from 13 to 4 and ends with 14 field survivors instead of 12, but still completes no camp within the observation window. Seed 42 completes camps on days 35 and 66; its v4 comparison completed one on day 30. Seeds 7 and 27 remain valid examples of recovery being blocked rather than forced. All five runs sampled no town at zero food at daily boundaries; this does not exclude transient shortages.

The seed-99 suppression control retained no surviving field members, no active camps and no new expeditions or founding after the day-6 wipe. Existing trade continued. Daily ledger checks and exact periodic save/load passed in every run. Daily town-food samples and individual camp states are retained in the JSON; they are not proof against transient shortages or a guarantee of eventual recovery.

The native memory journey passed 20 checks, including an asserted longer route around the remembered encounter after physical return and waiting. The native construction/interception regression passed 21 checks and the farm/freight regression passed 14. The tests use production movement, costs, saves and battle settlement, with their declared setup fixtures documented above.

Balance interpretation: the memory makes avoidance visible and removes repeated use of some dangerous approaches, but it can also suppress founding and raiding for longer. Treat the current duration and radii as a playtest baseline. No recovery timer forces a positive outcome. Final logs and exact outcomes are retained in `docs/raider-danger-validation/summary.json`.

## Reproduction

Use Godot 4.4.1 stable. Import `project.godot` once, then run model tests headlessly, for example:

```sh
godot --headless --path . --import
godot --headless --path . --script tests/raider_danger.gd
godot --headless --path . --script tests/raider_danger_observation.gd -- 7 5 90 repeat
```

Native regression scripts require a display and OpenGL compatibility rendering:

```sh
godot --path . --rendering-method gl_compatibility --resolution 1440x900 --script tests/raider_danger_ui.gd
```

Additional regressions and final results are recorded in `docs/raider-danger-validation/`. Observation JSON files are in `docs/raider-danger-<seed>-v5-<scenario>.json`.

## Limits

Three days and the avoidance distances need playtesting. Memory is personal and approximate, with no camp intelligence network. Danger can still block the only crossing; founders can lose supplies, be intercepted or die. Some camps may remain empty. This change does not fix every strategic dead end or establish long-term economic equilibrium. Historical comparisons below measure whole-world outcomes, not proof that a particular patrol caused every failed expedition.
