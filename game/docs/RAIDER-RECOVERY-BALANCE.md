# Raider recovery balance

This pass makes physical camp rebuilding reachable through ordinary simulation. It changes raider food decisions, the use of existing camp labor, and patrol pressure. All camp stocks, carried food, theft, consumption, recruitment and construction remain in the existing World food ledger. There is no raider currency, market, or parallel town economy.

## Rules in new companies

- **Visible woodland work:** a band can walk to reachable local woodland and forage. Each ration takes 120 normal overworld ticks (six campaign hours). Work pauses with the world, is interrupted by fleeing or combat, and appears as FORAGING on the map. The daily limit is the smaller of three rations or living members plus one. Attached bands seek two days of carried food; displaced survivors can build a larger travelling reserve. Travel itself earns no food.
- **Camp labor:** living residents gather two rations each per day. A living primary field member can contribute only while actually home and available. Production still obeys the existing six-ration daily cap, sixty-ration storage cap, and guard suppression. Recruits in training do not produce food. Field foraging and camp labor use the same produced-food ledger as the earlier camp system.
- **Food for recovery:** a fed band can still seek real food shipments or farms when its camp needs replacement or expedition savings. The camp protects three days of upkeep; food already in a band's pack counts toward that band's buffer. The old calculation protected those same rations twice. Recruitment still costs eight food per person and two days of training.
- **Real carrying and journeys:** new-rule bands carry at most eight rations per living member, capped at thirty-six. An expedition loads six construction rations plus `(2 + ceil(route_hours / 24)) * members`. Route length comes from actual pathfinding. A two-person journey of one to two days therefore needs fourteen rations, which the old fixed twelve-ration load could never provide. Planning creates neither food nor people.
- **Patrol pressure:** raiders flee a visible, paid, active patrol whose power exceeds theirs by 25%. They cannot react to distant patrol locations. Guards keep their combat strength, wages and recruitment costs. A completed patrol circuit returns to town for twelve hours of rest; battle recovery retains its earlier timing. Resting guards do not provide remote roaming protection.

Founding itself still requires the existing clearance delay, sufficient surviving people and food, travel to a generated empty campsite, and twelve hours of vulnerable construction. Defeat, hunger or flight can stop it. Settlement transfers actual identities and wounds and grants no free garrison. Completed camp occupations keep the existing named-loot rules.

## Compatibility and scope

`raider_needs.version` is now 2 for new companies. Version 1 saves retain their earlier decision rules and three-field band state exactly. Version 2 records and validates `forage_ticks`, `forage_day`, and `gathered`. Unsupported versions and malformed or mixed states are rejected atomically. New companies use `ashen-company-raider-recovery-preview.json` as a separate save filename.

The nineteen-argument `Campaign.setup` signature is unchanged. This branch starts from the previous physical-camp-founding **0.42 compatibility** preview, retaining economy, industry, material freight and news. Industry remains responsible for its farm repairs; the legacy regional-recovery repair path remains off in this preview. Materials cannot become food, and camp food/pack claims still pay once through the existing economy path.

The earlier `raider_survival` and `camp_founding` test factories explicitly select version 1 so those historical contracts remain tested. New `raider_recovery`, `recovery_founding`, `recovery_economy`, and `recovery_provisions` suites exercise version 2. The native new-company tests also use version 2.

## Validation method

Godot 4.4.1, headless models and actual native X11 UI with software GL. Errors are checked in logs as well as exit codes, because Godot can report a script error while returning zero. Native checks use map clicks, the normal clock, F5/F9 with both a successful-load notice and exact state equality, and the existing legal camp-interception combat journey. Screenshots were visually inspected.

The long simulations retain physical guards, ordinary town/camp starting resources, production, trade, industry and news. The only recurring-company fixture is an initial grant of company food/crowns so the observer can remain alive; towns, bands and councils receive no grants. At day 6, declared clearance fixtures remove either Ford, the first wilderness camp while retaining its field survivors, or that wilderness camp and its field band. The subsequent movement, recruiting, gathering, theft and building are normal AI. These fixtures are not claims that a player battle was simulated. Daily shared-food and council-treasury checks run throughout, with exact JSON save/load checks every ten days.

The controlled mechanics tests separately declare resource/contact fixtures to isolate costs, elapsed work, interruption and validation. They do not establish the natural founding rate; the unforced AI after clearance in the long observations does.

## Observed results

**3,433 checks in 33 test runs passed**, with zero failures or script errors, plus a clean editor import. The twelve independent long observations cover 585 campaign days. A further twenty-day deterministic replay records the founding party's provenance; it is not an additional independent world. Native foraging has 13 checks and native construction/interception has 21.

| Rules, seed and clearance scenario | Elapsed days | Founding day | Living field members at end | Paid recruits completed | Paid expeditions launched | Food stolen from farms/freight |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| baseline-1-frontier | 45 | None | 8 | 9 | 0 | 114 |
| recovery-1-frontier | 45 | 14 | 20 | 30 | 0 | 114 |
| baseline-7-frontier | 45 | None | 4 | 12 | 0 | 80 |
| recovery-7-frontier | 45 | 14 | 20 | 6 | 0 | 88 |
| baseline-27-frontier | 45 | None | 6 | 8 | 0 | 92 |
| recovery-27-frontier | 45 | 15 | 16 | 12 | 0 | 104 |
| recovery-1-clear | 45 | None | 18 | 24 | 0 | 114 |
| recovery-7-clear | 45 | None | 20 | 8 | 0 | 103 |
| recovery-27-clear | 45 | None | 16 | 16 | 0 | 102 |
| recovery-1-wipe | 90 | 18 | 18 | 48 | 1 | 114 |
| recovery-13-none | 45 | None | 18 | 14 | 0 | 122 |
| recovery-42-none | 45 | None | 16 | 18 | 0 | 133 |

The frontier fixture clears `wild_0` on day 6 and leaves its actual field survivors. All three version-2 worlds rebuilt it on day 14 or 15 (about eight to nine days after clearance); none of the three version-1 controls rebuilt it by day 46. The final version-2 field populations were 20, 20 and 16 versus 8, 4 and 6 in the matching controls. Retired migration records are excluded from living counts.

The road-clearance fixture clears Ford on day 6. None of the three new-rule worlds rebuilt it within the 45-day observation. Rebuilding is conditional on food, people, routes and local guard pressure, rather than a respawn guarantee.

The seed-1 full-wipe fixture destroys the wilderness camp and its field band on day 6. `pass_1` launched the paid two-member expedition `pass_1_1_r2` on day 16. That exact party founded `wild_0_2` at day 18, 04:18; the provenance is recorded in `raider-balance-recovery-witness-1-wipe.json`, whose samples exactly match the first twenty days of the longer run. The camp remained active through day 91. The region ended with 18 living field members, 48 completed paid recruits, 24 patrol victories and one successful new occupation; observed daily field population peaked at 22. This supports the recovery loop without a population explosion in this run.

No town had zero food at a sampled day boundary in these twelve observations. That is a sampled stock result, not proof against every transient shortage or future imbalance. Farm raid totals mostly stabilized early, while some freight theft continued later. In the 90-day full-wipe run recorded theft stopped increasing after day 40. Long-term raiding frequency and target choice therefore remain explicit follow-up balance work; healthy camp persistence alone does not prove an indefinitely active raiding cycle.

## Reproduction

Import `project.godot` in Godot 4.4.1, or use:

```sh
godot --headless --path . --script tests/raider_recovery.gd
godot --headless --path . --script tests/recovery_founding.gd
godot --headless --path . --script tests/recovery_economy.gd
godot --headless --path . --script tests/recovery_provisions.gd
godot --headless --path . --script tests/raider_balance_observation.gd -- 1 recovery 45 frontier
godot --headless --path . --script tests/raider_balance_observation.gd -- 1 baseline 45 frontier
godot --headless --path . --script tests/raider_balance_observation.gd -- 1 recovery 90 wipe
```

Run `tests/raider_recovery_ui.gd` and `tests/camp_founding_ui.gd` with a real display, compatibility rendering, and 1440 by 900 resolution. Long-observation output goes to `docs/raider-balance-<mode>-<seed>-<scenario>.json`. Only mode `baseline` selects the old survival rules. Final packaged logs and the check summary are in `docs/raider-recovery-validation/`.

## Limits

This is a first balance pass across a small seed sample, not a claim of perpetual equilibrium. Clearing a guarded road and clearing a remote camp need not produce the same recovery time. A complete wipe should be harder to recover from than leaving provisioned survivors. The system still uses the generated map's camp sites; it does not add arbitrary new sites, external invasions, raider markets, band mergers or faction wars. Longer campaigns, more seeds, repeated player clearances and the frequency of renewed farm raids remain playtest targets.
