# Earned dungeon economy audit — prototype 0.43

## Result

**Mechanics pass; large-dungeon balance is not signed off.** Earned companies
cleared burial mounds, recovered named equipment and brought it home. The
tested policies did not finish a garrison or royal crypt. Changing the retreat
decision won some individual chambers but did not produce a sustainable full
clear. These are automated policy trials, not human playtests or win rates.

No enemy stats, rewards, generation versions, wages or prices were changed in
this audit. Reward inflation or weaker defenders would be premature: the
results depend strongly on hiring, tactical withdrawal and the wider campaign
economy. The audit supplies reproducible failures and exact earned saves for
the next balance decision.

## Build and scope

- Main archive: `Battle-Brothers-2-Prototype-0.43.zip`, Library version 48,
  SHA-256 `cdebc73fec49000fbd87640871e44f0f6697363b065c847fc35f1ab43f779413`.
- The archive still contains version-two dungeons. Prior dungeon boss, variety,
  keys, earned-audit, placement, journal and theme patches were reconciled
  locally with 0.43. Its landmark directions and 0.43 UI label are preserved.
- Runtime: Godot 4.4.1 stable, Linux; headless careers and native OpenGL UI.
- Fresh starts use the normal three founders, 300 crowns, 24 food and 20 tools,
  the expanded region and all current campaign systems. No grants, teleporting,
  forced victories, edited enemy wear or reward rerolls occur in careers.
- Other chats retain responsibility for merging and releasing the main archive.

## Final career results

All runs have a 90-day horizon or stop at a genuine campaign ending. `verified`
is the final work-first policy. `veterans` uses that same policy but postpones
dungeons until day 40. `verified-control` disables dungeon expeditions.

| Policy | Seed | End day | Survivors | Crowns | Mounds finished | Outcome |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Work first | 1 | 16 | 4 | 0 | 0 | Unpaid wages |
| Work first | 71 | 12 | 0 | 24 | 0 | Company lost before a dungeon trip |
| Work first | 592 | 55 | 5 | 0 | 3 | Unpaid wages |
| Work first | 789 | 50 | 5 | 0 | 3 | Unpaid wages |
| No dungeons | 1 | 91 | 6 | 4 | 0 | Reached horizon |
| No dungeons | 592 | 34 | 4 | 0 | 0 | Unpaid wages |
| Start dungeons after day 40 | 1 | 91 | 5 | 38 | 3 | Reached horizon |
| Start dungeons after day 40 | 789 | 33 | 3 | 0 | 0 | Unpaid before dungeon eligibility |

Across all retained policy experiments: **20 career runs on four seeds, 63
town-to-town expeditions, and 83 reconciled career/expedition cash ledgers**.
These are correlated comparisons on the same seeds. Repeated runs used to
verify the accounting corrections and the initial flawed-rest pilot are not
counted as additional samples.

The earlier baseline finished all three mounds on seeds 71, 592 and 789, then
disbanded on days 39, 46 and 40. Its eight-person target consumed the purse
before larger expeditions. The lean and reserve experiments remain in the
evidence, including their failures; the final policy does not silently replace
their results.

## What the money says

Successful mound trips can cover upkeep and contribute to growth. In the final
seed-592 career, its three mound trips produced **638 crowns after wages and
supply purchases, before hiring and equipment purchases**. It then spent 272
crowns on gear and 268 on hires, leaving a combined **98-crown purse increase**.
The first of those trips recovered a named sword. Retained equipment is not
reported as spendable cash.

Each trip starts in town before provisioning and ends after the actual return,
shopping and up to four days of paid recovery. Its identity is:

`cash change = chests + gear sales + other loot + contract pay - wages - supplies - gear purchases - hires`

Food, repair tools, medicine and ammunition consumption are reported separately
from purchases and changes in stores. Supply purchases can leave useful stock
behind; they are not synonymous with consumption. Deaths are recorded. An
unfilled vacancy is not assigned an invented replacement price. `recovered`
reports health, wounds and repairs, not restoration of the original roster.

Two accounting edge cases were corrected in the instrumentation: buying ammo
can immediately refill carried packs, and a cache can award tools on the same
tick that a repair consumes one. Version-two reports include these corrections.
Earlier reports use version-one instrumentation: their cash ledgers remain
exact, but ammo consumption covers post-battle refills only and net tool use
can miss simultaneous cache gains. Do not use those older unit totals for
precise supply calibration.

## Combat and return sensitivity

The career policy withdraws at the first casualty or below 60% of initial
company HP. This is deliberately conservative, and matters considerably.
Four exact earned pre-battle saves were tested with a two-casualty threshold
and the same HP threshold. Three chambers became victories with one death;
the fourth withdrew after two deaths. No combat state or RNG was edited.

Four corresponding **town-departure** saves were then replayed as separate
decision branches, using real travel, combat, rest, shopping and return. They
are not additional fresh careers and do not count as full clears:

| Seed | Dungeon | Days | Deaths | Cash change | Fully recovered at home |
| --- | --- | ---: | ---: | ---: | --- |
| 592 | Garrison | 6.97 | 4 | -175 | No |
| 592 | Royal crypt | 3.61 | 3 | -145 | Yes |
| 789 | Garrison | 5.01 | 1 | -209 | No |
| 789 | Royal crypt | 2.04 | 2 | -74 | Yes |

All four returned home; none reached the final chest. Clearing an individual
room therefore cannot stand in for an affordable completed expedition. The
two unrecovered returns also leave costs outstanding.

The wider economy contributes to the risk: one control disbanded without any
dungeon visits, while another reached day 91 with only four crowns. These
paired outcomes do not establish that dungeons alone cause insolvency.

## Policy and knowledge limits

The final driver travels only to discovered locations, revealed dungeon or
cache entrances, and destinations disclosed by signed work. It remembers
prices observed at towns, uses observed journal routes where possible, and
uses a rough distance allowance for unsurveyed terrain. It searches only
reachable known doorways; room kinds are used after visiting them. World keys
still reveal names only; maps and exploration reveal entrances.

The driver uses engine threat tiers for disclosed entrances, production combat
AI for both sides, fixed readiness thresholds, and simplified decisions. It
is not a simulation of human tactical judgment. Its frontier navigation reads
recorded compass prose and visible roads, but is not a human evaluation of
landmark directions. It can make poor purchases, miss opportunities or withdraw
too early. The baseline additionally inherited a remote cache-guard-state
filter and exact path estimates; later policies removed those advantages.

All dungeon threats, rewards, keys, rooms and enemy wear retain their generated
identity through retreat and Save/Load. No save schema or version-five
generation algorithm changed. Old version-one through version-four saves are
still covered by the theme compatibility suite.

## Verification

- Theme generation, battles and legacy compatibility: 35,214 checks, zero failures.
- Expedition journal: 59; vault keys: 103; 0.43 landmark directions: 1,219;
  all zero failures.
- Accounting edge fixtures: 10 checks, zero failures. These explicitly prepared
  boundary fixtures are excluded from earned career claims.
- Native UI: 25 checks, zero failures, two resolved real battles from exact
  earned checkpoints. F5/F9, paid town recovery, re-entry with persistent enemy
  wear, a named final chest, duplicate-loot prevention and travel home passed.
- Four battle-decision branches: 20 checks, zero failures. Four full
  town-to-town branches: 80 checks, zero failures. Design outcomes still failed
  to produce a large-dungeon completion.
- Both patches apply to untouched 0.43. Clean import, accounting, journal and
  landmark-direction checks pass on that reconstructed project.

Screenshots, logs, raw reports, ledgers and earned saves accompany the pack.
`tests/summarize_dungeon_economy.py` regenerates the CSV ledgers and checks every
included career and trip cash identity. Older reports count the last end-save
check in the log after writing the report; final version-two reports include
that check directly.

## Next balance decision

Large-dungeon progression remains open. Use the supplied earned departures for
a player-directed tactical pass, and test one change at a time against the same
states. A useful candidate is modest, one-time supplies at cleared stairwells:
it could reward partial progress without changing fixed enemies or replacing
the final named reward. That change is **not implemented or validated here**.
Any new-generation loot change must preserve existing version-five saves.
Full earned garrison/royal completion and an affordable return remain required
before claiming those tiers balanced.
