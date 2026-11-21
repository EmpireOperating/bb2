# Road contracts — 0.34

This gameplay update adds intermediate paid battles to address the limited growth observed in the 0.33 midgame review. It retains the existing combat math, enemy grades, equipment prices, modest starts, passive recovery and company limits.

## Play

Visit a town's Contract Board. From day 8, outlaw hunts and stolen-arms jobs appear; from day 15, mercenary blockades also appear. Use the board's page arrows to see all postings. Accept a job, travel to its named landmark and choose **Deploy the Company**. You can complete it even if somebody has already cleared that landmark's camp.

| Posting | First day | Fixed enemy force | Base crowns |
|---|---:|---|---:|
| Hunt the outlaw gang | 8 | 4 outlaws + 1 thug | 440 |
| Recover stolen arms | 8 | 5 outlaws + 1 raider | 650 |
| Break the mercenary blockade | 15 | 4 outlaws + 3 raiders + 1 veteran | 980 |

Existing faction reputation adjusts the quote at signing. It then stays fixed. Each town posts one of each eligible kind per week, rotating destinations among its adjacent landmarks. The deadline is six days after signing, clipped to the campaign's final day. An accepted job survives a weekly refresh until completed, abandoned or expired.

Victory pays the quote, awards ordinary contract progression and recovers ordinary battlefield salvage. The stolen arms are returned to their merchant; there is no additional quest-item inventory or guaranteed equipment reward. Retreat, defeat, abandonment and expiry consume that posting without payment. The same identity cannot be accepted again. Later weekly postings are separate jobs.

The company decides which fight to take. There are no equipment ratings, recommended-gear warnings or level/headcount gates. Enemy composition does not scale with the company. The only compatibility restriction is that the eight-enemy job requires the expanded formation system; older six-slot saves can still take the other two.

## Scope and persistence

These are private bounty encounters created when deploying at the designated landmark. They are not persistent roaming parties or an expansion of the physical freight economy. A bounty victory does not destroy the separate camp garrison or release its food cargo. Incidental scouts, camp assaults and caravan fights retain their own outcomes and payments. Ordinary world simulation still advances after battle.

Existing companies with campaign progression enabled gain postings automatically. Existing active contracts retain their behavior. New active road jobs and battles save/load through the existing campaign snapshot wrapper, with validation for their identities, quotes, targets, dates and force grades. Older executables cannot load an active road contract; retain an older save if returning to those builds.

## Matched campaign continuations

The new driver loads the exact earned day-ten/eleven companies from the prior release. It targets eight fighters, buys supplies and equipment, fits usable salvage, recruits using real earnings, spends earned development/perks, and pays normal wages and recovery costs. No people, items, money, XP, health or victories are granted. The control uses the same policy while ignoring new road postings. Each company's two branches start from the same saved state.

| Opening cohort | Matched companies | Reached 8: new / control | Alive at ending: new / control | Combat deaths: new / control |
|---|---:|---:|---:|---:|
| First-half equipment policy | 7 | 2 / 0 | 3 / 7 | 33 / 1 |
| Second-half equipment policy | 8 | 2 / 0 | 3 / 8 | 33 / 2 |
| First-half cautious/rush policies | 11 | 6 / 0 | 9 / 11 | 48 / 2 |
| **Total** | **26** | **10 / 0** | **15 / 26** | **114 / 5** |

The additional paid work establishes a route to eight through earned recruitment. It also exposes companies to many more dangerous battles: survival is substantially worse under this aggressive policy. The new branches hired 96 mercenaries, including replacements, versus 24 in controls. None of these figures is a human win-rate estimate or proof of final balance. Controls often have little paid work after local camps disappear, so their low losses are not equal-combat comparisons. Some seeds are shared across different opening policies; these are 26 saved companies, not 26 independent worlds.

The driver favors the cheaper hunt, attempts stolen arms with at least five active fighters and would attempt blockades with seven. Those are driver choices, never game restrictions. It knows world topology and uses the normal legal tactical AI for both sides. The 52 continuations did not select a blockade; that job has separate model and native coverage below. They do not establish twelve-person, late-perk or veteran-endgame balance. The second-half equipment cohort uses additional seeds with unchanged values, not an independent human playtest.

All six raw cohort results are included as `road-growth-{new,control}-{gear,gear-holdout,baseline}--1.json`. Pilot runs and the repeat used to export native checkpoints are excluded from this table.

## Native verification

All three jobs were played through the real interface, travelling with the normal clock and resolving combat through legal production commands. F5/F9 preserved signed jobs, active battles and settled outcomes. Actual payouts, consumed postings and surviving company state were checked.

- **First hunt:** seed 592's earned day-11 company, four living mercenaries and 122 crowns. Victory paid 471 crowns and cost one mercenary. Three returned on day 13 with 572 crowns. A real town hire cost 138, leaving four living and 434 crowns.
- **Stolen arms:** an independent branch of the same company's naturally grown day-22 checkpoint, eight living and 404 crowns. Victory paid 761, leaving eight alive and 1,117 crowns on day 24 after upkeep.
- **Blockade:** another branch of that identical day-22 checkpoint. Victory paid 1,147, cost one mercenary and left seven alive with 1,506 crowns on day 24 after upkeep.

The latter two are alternatives, not sequential victories by one unchanged party. Both use its actual earned equipment and progression. Screenshots include the board, accepted contract, battlefield, aftermath and first bounty-funded hire.

## Validation and reproduction

Godot 4.4.1 was used. `road_contracts.gd` passes 94 checks covering posting dates, exact forces, cleared camps, fixed quotes, weekly rollover, separate incidental fights, retreat, expiry, save corruption rejection, exact active-battle continuation and single settlement. The six matched continuations pass 1,448 checks. The native journey passes 57 checks with three real fights. The separate native-fixture export repeats seed 592 and passes 77 checks; it is not counted as another matched company.

Regression suites pass with zero failures: campaign progression (262), roster compatibility (26), company roster (101), procedural generation (15,100 across 128 seeds), farm (46), town guards (34), bandit edges (52), integrated living world (104), and combat baseline (141, including twelve actual opening victories). Old 0.31 fixtures retain exact tactical continuation and settlement.

Run model tests with:

```sh
godot --headless --path . --script res://tests/road_contracts.gd
godot --headless --path . --script res://tests/road_growth.gd -- gear -1
godot --headless --path . --script res://tests/road_growth.gd -- gear -1 --control
```

Repeat the last two commands with `gear-holdout` and `baseline`. For native checks, run `tests/road_contracts_ui.gd` with a display and fresh `XDG_DATA_HOME`. Its checkpoints are `roads-gear-592-first-contract.json` and `roads-gear-592-grown.json`, reproducible with `road_growth.gd -- gear 592`.
