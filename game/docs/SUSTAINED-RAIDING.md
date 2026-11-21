# Sustained raiding

Two decision bottlenecks made the region quiet even while camps, towns and trade survived. This pass fixes those bottlenecks using the existing physical food and freight systems.

## The causes

In the previous recovery build, daily farm production and dispatch ran together. A rebuilt farm with no leftover stock harvested one load and immediately shipped that entire load. The raid selector ran later and required stored harvest, so that farm never became a valid target again. The seed-1 baseline had all six farms repaired with zero stored food on day 40, and no further farm incidents through day 91.

Material selection had a second problem. Wanting food for future replacements excluded all material freight, even when a band was fed, carried provisions, and had no edible shipment in sight. The baseline still had material traffic but no material seizures.

## New behavior

- Harvest enters the farm's actual stock at midnight. One ordinary cart can leave after 08:00 each day. Food reaches town only on physical arrival.
- Damage or an approaching/active raid holds dispatch. Scaring the attackers away allows a still-eligible shipment to leave; a recovered-harvest cart does not consume the ordinary departure slot. Existing departure records prevent double dispatch across repeated calls and reloads.
- Provisioned bands can choose visible material freight when no wanted edible cargo is available. Food takes priority when wanted. Hungry bands, bands carrying less than two days of food, and displaced survivors refuse material detours.
- Existing route ownership, guard cover, town sanctuary, physical approach, four-hour attack work, hauling, unpacking and material accounting still apply. Materials cannot become rations.

There are no additional starting resources or raiders. The original two-day patrol ration policy, recruitment costs, camp-founding provisions and patrol-rest behavior remain in place. Farm repairs still require the existing industry inputs, council funds and safe work. The only UI change explains the morning harvest departures.

## Compatibility and integration

New companies use `raider_needs.version = 3`. Versions 1 and 2 retain their earlier dispatch and target-selection rules; loading does not silently upgrade them. The farm snapshot has no new fields: departure history already contains the date and recovered flag. The main preview uses a separate save filename, `ashen-company-sustained-raids-preview.json`.

The nineteen-argument campaign setup signature is unchanged. The branch starts at `fa8087bce74f90b00bc5994cd763ab13f19416d0`, the Raider Recovery Balance integration source, which already contains the physical-founding and Prototype 0.42 economy compatibility work. This change is incremental on that source. Preserve newer work from other chats when merging; the preview is not a replacement for their build.

Production edits are limited to `src/raider_needs.gd`, `src/farmstead.gd`, `src/farm_view.gd`, and the preview save filename in `src/main.gd`.

## Validation method

Godot 4.4.1; headless model tests plus native X11/GL UI. Logs are scanned for script errors as well as exit status. The native test uses real map buttons, the normal clock and F5/F9; each load must both report success and match the saved state exactly. Its declared clearance/contact fixtures isolate shipping and raid behavior without adding world resources. Screenshots are visually inspected.

The ninety-day world observations leave town/camp resources, guard funding, industry and trade intact. Company-only food/crowns keep the observer alive. On day 6, a declared fixture clears a guarded road camp, clears a wilderness camp while leaving its roaming survivors, or wipes both the wilderness camp and its field band. Subsequent raids, recruitment and founding use ordinary simulation. These are not player-combat simulations. Daily food/farm/treasury checks and exact JSON save/load checks every twenty days cover accounting and persistence. The recorded raid timestamps distinguish early incidents from renewed attacks late in the campaign.

`tests/fixtures/Raider-Recovery-v2-start.json` was exported from the actual preceding build, unchanged. The new tests restore it and compare it with the historical version-2 factory. Version-1 survival/founding tests and version-2 recovery tests remain separate from the new version-3 scenarios.

## Final results

**3,207 checks across 27 test runs passed**, with no failures or script errors, plus a completed asset import. The four final world observations cover 360 campaign days. Native checks: fourteen for harvest/dispatch/theft, thirteen for foraging, and twenty-one for camp construction/interception.

| Rules, seed, clearance | Farm raids total | Farm raids after day 60 | Material wagons seized | Material seizures after day 60 | Last farm raid day | Living field members at day 91 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| baseline, 1, wipe | 6 | 0 | 0 | 0 | 11 | 18 |
| sustained, 1, wipe | 20 | 7 | 10 | 3 | 89 | 14 |
| sustained, 7, frontier | 16 | 5 | 28 | 9 | 81 | 18 |
| sustained, 27, clear | 10 | 2 | 20 | 2 | 90 | 16 |

The seed-1 previous-rule control stopped at six farm raids, last occurring on day 11, and seized no material wagons. Its food theft also stopped increasing after day 40. All three final new-rule worlds had both farm raids and additional material seizures after day 60. No town had zero food at a sampled daily boundary; this does not rule out transient shortages between samples. Material counts are actual physically seized wagons, not mere target selections or attempted raids.

Seed 7 (frontier) founding records: wild_0_2 on day 14, from wild_0_1.

**Recovery caveat:** the seed-1 full-wipe camp did not rebuild within ninety days under the final rules, whereas the prior control rebuilt on day 18. That is a measured change in the wider simulation, not evidence of a guaranteed recovery interval. The paid-expedition and construction model/native tests still pass, but natural rebuilding frequency needs more balance work. Do not carry forward the preceding pack's day-18 recovery result as a claim about this build.

## Reproduction

```sh
godot --headless --path . --import
godot --headless --path . --script tests/sustained_raids.gd
godot --headless --path . --script tests/raid_pressure_observation.gd -- 1 baseline 90 wipe
godot --headless --path . --script tests/raid_pressure_observation.gd -- 1 sustained 90 wipe
godot --headless --path . --script tests/raid_pressure_observation.gd -- 7 sustained 90 frontier
godot --headless --path . --script tests/raid_pressure_observation.gd -- 27 sustained 90 clear
```

Run `tests/sustained_raids_ui.gd`, `tests/raider_recovery_ui.gd` and `tests/camp_founding_ui.gd` with a real display, compatibility rendering and a 1440-by-900 window. Final logs and the validation summary are in `docs/sustained-raiding-validation/`.

## Limits

Three seeds and ninety days do not establish perpetual equilibrium. Captured materials still use the existing camp-storage/recovery-job system; this does not add a raider crafting economy. Morning shipments deliberately expose actual harvest for part of each day, so food delivery timing and raid pressure change together. Recovery and safe periods remain conditional on resources and surviving people, rather than guaranteed timers. Repeated player interventions and broader seed coverage remain playtest work.
