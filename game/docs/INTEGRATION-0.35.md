# Combined campaign — 0.35

## What changed

This release merges the delivered Hinterlands, Living Camps, Dungeon Challenge and Earned Dungeon Audit packs into the exact 0.34 master. The weekly road contracts, equipment progression, perks, ammunition, modest starts, formation and reserves remain. No enemy-stat, economy-price or reward-value tuning was added during integration.

- All three towns have physical rural supply, harvest carts, local raids, paid patrols and recovery commissions. The market town produces four food/day in gardens and still depends on imports.
- Camps can gather limited food, pay for recruits, train them over two days, care for survivors and dispatch new physical parties. Previously dead raiders stay dead; replacement identities are distinct. Camp destruction stops that occupation's recruitment. Existing reoccupation rules and delay still apply.
- Victorious camp destruction has a seeded chance of named equipment: 15/25/35 percent by founding strength. These are prototype odds, not claimed Battle Brothers values. The entitlement is reserved per occupation and cannot be rerolled by save/load. Scouts and separate road bounties do not award the parent camp's drop.
- New dungeons use fixed tiers, different battlefields and nonmagical undead bosses. Trapped vaults, rubble shortcuts and concealed caches have persistent, paid choices. There are no recommended-equipment ratings or party-level entry gates.
- New dungeon fights and regrouping take two hours, with normal hourly recovery and midnight upkeep. Overworld fights retain their one-day cost. Original version-one dungeons retain their one-day settlement. Returning from the aftermath screen does not charge again.

## Playing and saves

Import `project.godot` in Godot 4.4.1 and run. Start a new company for every combined world capability. Existing companies and ongoing battles load with their saved capabilities and progress; they are not silently given regional farms, replacement camps or rerolled dungeons. The original main save filename, `ashen-company-save.json`, is retained. Preview save filenames were not adopted. Older executables cannot necessarily open a new-world save.

Both New Company paths enable all ten setup flags and challenge dungeons. Twenty living mercenaries and twelve deployed remain the limits. New recruits still fill the field until twelve. Gear, levels and backgrounds never determine access to contracts or dungeons.

## Conflict resolution

The original 0.33 base was reconstructed by reversing the cumulative world patch, then verified against the Dungeon Challenge manifest's original runtime hashes. Changes were merged from that common base into 0.34. The world pack's replacement README, preview title and isolated save path were deliberately not used.

The camp-clear settlement conflict preserves both branches: road bounties retain their separate force/payment, while actual camp destruction awards its reserved named item before contract cleanup. Legacy camp-clear settlement retains its original generation behavior. Daily camp recruitment runs after council wages. Dungeon entrance placement avoids every regional farm. Challenge battle templates, room validation and the two-hour clock coexist with regional and renewing-camp save state.

The incoming `earned_dungeon_ui.gd` name collided with the earlier native audit. Both are retained: the incoming test is `earned_challenge_ui.gd`; the original keeps its existing name. No original 0.34 source, test or evidence file was removed.

## Fresh progression runs

Ten model careers use ordinary three-founder starts with 300 crowns, actual recruits and purchases, physical salvage, earned development/perks, passive recovery, normal travel, world clocks and legal tactical AI. There are no resource grants, forced victories or manufactured equipment in these careers. Seven use an expansion policy targeting twelve; three are alternative expedition policies for already represented seeds.

| Policy | Seed | Largest field | End living | Career deaths | End crowns | Ending | Blackbarrow |
|---|---:|---:|---:|---:|---:|---|---|
| expedition | 592 | 11 | 11 | 2 | 620 | Survived month | Cleared |
| expedition | 789 | 9 | 9 | 2 | 144 | Survived month | Unfinished |
| expedition | 1380 | 7 | 7 | 1 | 0 | Unpaid wages | Not entered |
| growth | 1 | 5 | 0 | 5 | 21 | Wiped | Not entered |
| growth | 71 | 12 | 12 | 0 | 660 | Survived month | Not entered |
| growth | 198 | 4 | 0 | 6 | 89 | Wiped | Not entered |
| growth | 592 | 12 | 12 | 1 | 387 | Survived month | Not entered |
| growth | 789 | 10 | 10 | 2 | 215 | Survived month | Not entered |
| growth | 1380 | 7 | 7 | 1 | 0 | Unpaid wages | Not entered |
| growth | 1580 | 4 | 0 | 5 | 139 | Wiped | Not entered |

Two of seven expansion careers reached twelve on day 29. Three wiped and one disbanded after unpaid wages. Reaching twelve late in a thirty-day campaign does not establish sustainable long-term payroll or higher-tier dungeon progression. Seed 592's expansion company finished with no food; cash and headcount alone are not measures of a healthy company.

The expedition branch of seed 592 entered with six, won three actual Blackbarrow battles, lost two, claimed its named final reward and rebuilt to eleven by month end. Seed 789 entered but did not finish; seed 1380 never reached the policy's departure conditions. The driver knows world topology and dungeon layout, favors easier paid jobs, and uses generic production AI. Its readiness and departure thresholds are test-policy decisions, not in-game restrictions. These small deterministic runs establish possibilities and failure modes, not human win rates.

Raw reports and earned formation checkpoints are in `docs/integrated-campaigns/`. The original pack audits remain clearly separate from this merged-build evidence.

## Native verification

Four native journeys passed on the merged build using isolated user data and Godot's actual rendered interface:

- **Regional travel:** a normal fresh company travelled through all three towns and farms, read actual raid evidence and reports, and reached day four without injected positions or resources. 39 checks.
- **Camp loot:** seed 27's ordinary founders won a legal camp battle and recovered Torsten's Boar spear. F5/F9 preserved the item and cleared camp. A separate new company naturally reached paid camp training. This suite uses disclosed positioning fixtures for inspection and the camp assault. 14 checks.
- **Earned dungeon continuation:** two unmodified earned seed-1380 checkpoints from the incoming audit continued through real battles, two-hour settlement, withdrawal/re-entry, reserved final treasure and F5/F9. This is two native segments of that earlier earned career, not a full fresh native career. 58 checks.
- **Earned twelve-person battle:** seed 71's actual day-29 integrated checkpoint loaded with twelve and 772 crowns. The saved formation deployed into a mercenary blockade. Victory took thirteen rounds, cost two mercenaries and paid 1,274 crowns; ten returned on day 30 with 2,015 crowns after upkeep. Signed job, active battle, aftermath and formation survived F5/F9. No people, resources, gear or XP were granted. 21 checks.

Screenshots cover the native world reports, named camp drop, dungeon treasure, earned twelve-person formation and blockade aftermath. The test suites automate legal player commands; they are not human tactical playtests.

## Model and compatibility checks

Eighteen merged regressions pass 6,734 assertions: road contracts, Hinterlands, Hinterlands edges/dungeons, camp lifecycle/edges/loot/months, dungeon clock/challenge/compatibility, original dungeons, combined integration, named integration, roster compatibility, ammunition, farm edges and guard edges. Repeated state checks contribute to those totals; they are not distinct scenarios.

Additional focused checks pass:

- `integrated_roads`: 94 checks, repeating the road-contract lifecycle with all new world capabilities.
- `merged_features`: 29 checks, ensuring road victory cannot steal a camp's reserved named reward and an underground midnight advances farms, camp training, upkeep and an unrelated signed bounty correctly. Position, time and one forced-victory settlement fixture are explicitly declared; this suite is not balance evidence.
- `integrated_compat`: 18 checks against five phases exported by the untouched 0.34 runtime. Every serialized field, tactical command continuation, payment, loot, clock and camp return matches. Original capability flags and version-one dungeons remain unchanged.

Fresh-career outcomes include genuine losses and unpaid-wage endings. Development-only test errors were corrected: an incorrect field name, insufficient scouting rations in a clock fixture, and an in-memory representation comparison replaced by exact serialized-save comparison. No production failure was hidden by forcing an outcome or weakening save validation. Final logs are in `docs/validation-0.35/`.

Reproduce with Godot 4.4.1:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/merged_features.gd
godot --headless --path . --script res://tests/integrated_compat.gd
godot --headless --path . --script res://tests/integrated_campaigns.gd -- 71
godot --headless --path . --script res://tests/integrated_campaigns.gd -- 592 --expedition
```

The remaining growth seeds are 1, 198, 592, 789, 1380 and 1580; the other expedition seeds are 789 and 1380. Run native scripts with a graphical display and fresh `XDG_DATA_HOME`: `hinterlands_ui`, `camp_life_ui`, `earned_challenge_ui`, and `integrated_earned_ui`. The last uses the packaged, reproducible seed-71 twelve-person checkpoint.
