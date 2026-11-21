# Earned dungeon progression audit

Tested with Godot 4.4.1 against Prototype 0.33, Library version 37, plus the previously delivered Dungeon Challenge dependency. The source archive SHA-256 is `30093b267e727f94fe8c7878cbb84479620b35d590bf772c42596598701f2e5f`. Its gameplay source matches version 36. This is an incremental integration pack; it does not replace the main release or perform a merge.

## Result

Ordinary companies can earn a Blackbarrow clear. Two of the six final-policy seeds cleared; four did not. These runs establish possibility and expose attrition, not a calibrated player win rate. The policy was developed on seeds 1, 198 and 1380; seeds 71, 592 and 789 were subsequent holdouts. No further policy tuning followed the holdouts.

| Seed | Blackbarrow | End day | Living | Career deaths | Crowns | Visits |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | Unfinished at month end | 31 | 3 | 11 | 72 | 3 |
| 198 | Wiped | 27 | 0 | 10 | 80 | 2 |
| 1380 | Cleared | 28 | 5 | 5 | 863 | 3 |
| 71 | Unfinished at month end | 31 | 3 | 8 | 15 | 3 |
| 592 | Unfinished at month end | 31 | 4 | 8 | 92 | 4 |
| 789 | Cleared | 19 | 2 | 6 | 912 | 3 |

The company in seed 1380 began with three generated founders, 300 crowns, 24 food, 20 tools and six medicine. It earned contracts, purchased supplies and recruits, used recovered equipment, spent earned growth/perks, and cleared the first guard on day 9 with only two survivors. It withdrew, earned replacement/recovery costs, returned twice, and cleared the warden on day 28. The survivors' final levels were 5, 5, 3, 4 and 2. Its final reward was **Oswin's Boar spear** (+9% damage, -17% load), alongside the normal 600-crown final chest.

## Production changes

- Challenge-schema dungeons (inner version 2) now charge **two hours for battle and regrouping**, using the same discrete hourly clock as exploration. Ordinary recovery runs during those hours and consumes normal tools/medicine; midnight still charges wages and rations. The displayed encounter button states the two-hour cost.
- A wiped company records its ending immediately, while still settling elapsed encounter time. The existing month deadline caps the clock at midnight after day 30, including a wipe.
- Released inner-version-1 dungeon saves retain their original 24-hour battle settlement. Overworld battle settlement is unchanged.
- Removed prescribed party-size/level recommendations from the entrance. Threat and supply costs remain visible; preparation remains the player's decision.

Enemy rosters, stats, morale, tactical rules, room generation, rewards, XP, hiring/prices, and the 30-day campaign deadline are unchanged. No magic or permanent-stat consumables were added. The outer save format and stored room/item state are unchanged; an existing version-2 save uses the new cost on its next battle settlement.

## Same-policy comparison with the old clock

The final expedition policy was also rerun against the exact pre-fix source, with the same seeds and no player-resource changes.

| Seed | Old 24-hour clock | New two-hour clock |
| --- | --- | --- |
| 1 | Unfinished, day 31; 3 living, 8 deaths, 117c | Unfinished, day 31; 3 living, 11 deaths, 72c |
| 198 | Unfinished, day 31; 2 living, 10 deaths, 99c | Wiped, day 27; 10 deaths, 80c |
| 1380 | Cleared, day 28; 5 living, 4 deaths, 789c | Cleared, day 28; 5 living, 5 deaths, 863c |

The time fix is a consistent dungeon pacing rule, **not evidence that the old game was impossible**, and it does not guarantee an easier campaign. Changed arrival dates affect available jobs, recruits, recovery, world activity and subsequent encounters. The paired outcomes do not establish improved balance or profitability. The patch also includes hourly recovery during regrouping; it is not a pure isolated change to a numeric day counter.

## Seed 1380 economy

Every crown reconciles through read-only wrappers around production actions. Purchases and sales must succeed through normal stock/ownership checks. These are whole-career flows, not a counterfactual measure of dungeon profit.

| Flow | Crowns |
| --- | ---: |
| Starting purse | 300 |
| Contract receipts | +1,335 |
| Other encounter pay | +80 |
| Dungeon chests, including finale | +883 |
| Sales of owned gear | +264 |
| Seven paid hires | -879 |
| Purchased armour | -47 |
| Purchased weapons/shields | -118 |
| Purchased supplies | -580 |
| Wages | -375 |
| Final purse | **863** |

Five career deaths and remaining equipment/supplies are not assigned a monetary value. The final named item was retained, not sold. Final stores: 52 food, 29 tools, 12 medicine, 86 company ammunition. A profitable cash ending can still cost a large part of the company.

## Test method and limits

`earned_dungeon.gd` starts ordinary fresh all-feature companies. It does not grant money, people, items, XP, damage, victories or dungeon completion. It uses real production travel/ticks, jobs, purchases, hiring, equipment assembly, training, supplies, combat, retreat, rooms, treasure and saves. All staged snapshots round-trip through the real save validator, and each final cash balance and world ledger is checked. Opponents and player soldiers both use normal legal AI commands; this is not human tactical play.

The scripted policy knows overworld destinations and uses only connections revealed by visited dungeon rooms. It aims for an expedition from day 8, normally grows toward six members, retains five days of food/wage reserve before departing, buys inexpensive shields, refits owned salvage, and does protected paid work while wounded when available. It deliberately leaves after its first dungeon victory to test recovery and return. It does not optimize for zero casualties or exploit free resource grants. The driver knows dungeon coordinates without first buying a rumour; native entrance/rumour/travel behavior was covered by the dependency's earlier tests.

Earlier exploratory strategies (forced combat retreats, a smaller roster, and deferred recruiting) also failed repeatedly. One initial pilot contained driver errors in waiting and revisiting occupied rooms and was discarded. These exploratory runs were not used to tune enemies or claim a success rate; the final six runs and matched three-run baseline are supplied in full.

Native `earned_challenge_ui.gd` passed **58 checks with two real battles**. It explicitly loads the model-earned `entry-1` and `entry-3` snapshots from seed 1380 through F9. It verifies the exact restored campaign, actual native crypt combat and two-hour charge, post-victory withdrawal/re-entry, cleared-room persistence, the warden's reserved named item, and F5/F9 at active battle, aftermath, withdrawal and treasure. These are two continuations of the same earned career, **not a full fresh-to-finale native playthrough**. A one-crown temporary mutation inside the inherited Save/Load assertion is immediately undone by F9 and never funds play. The native finale is claimed immediately; the model policy rests/refits first, so final supply totals differ legitimately.

Screenshots show the real native application. Unit timing tests use explicitly constructed timing/deadline fixtures; the earlier challenge regression uses declared prepared equipment/XP fixtures. Neither is counted as an earned campaign.

## Remaining decisions

Blackbarrow has a demonstrated earned route, but these runs are very costly and several companies run out of month. Higher-tier dungeons still have only the earlier prepared-party proof; their full earned progression is not established by this audit. Before changing their enemies, decide how those tiers fit the existing 30-day campaign horizon. Human tactical playtesting remains necessary to judge whether attrition and treasure feel fair. No further balance or campaign-length change is included here.
