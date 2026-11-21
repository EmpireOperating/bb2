# Midgame progression review — 0.33

## Result

An ordinary, earned company can clear Blackbarrow and bring its named equipment home. The native reproduction started on day 16 with six mercenaries, 49 crowns and 62 rations. Three real victories cost two mercenaries. Four left on day 21 with 349 crowns and only four rations. They returned to town, paid for food, compared and equipped the earned named bow, and saved/reloaded successfully.

The wider progression is **not yet established as balanced**. All 41 survivors from the earlier 48 openings were continued, with 53 policy runs including additional branches. None of these policies grew beyond six deployed mercenaries. The observed bottleneck is the combination of wages, provisioning, replacing losses and sporadic paid opportunities; this is evidence to investigate, not proof that any single price or payout is wrong. A policy can satisfy the four-contract campaign goal while losing most of its company.

This delivery adds reproducible validation, earned checkpoints, results and native screenshots. All 236 runtime source/data files remain byte-identical to the previously delivered 0.33. Combat values, enemy strength, prices, pay, recovery, access rules and saved-game formats are unchanged. No equipment rating, readiness warning or recommended-gear gate was added.

## Exact continuation of the opening

The earlier runs stored summary outcomes rather than day-ten saves. We replayed their original policies with snapshot export enabled. Every one of the 48 outcomes matched the delivered report exactly. The 41 surviving companies carry their actual casualties, money, purchases, progression, injuries, formation and world history into this pass. No mercenaries, equipment, XP, money, health, supplies or victories were injected.

The source seeds are `1 + n × 197`, n = 0…15. Seven opening companies had already ended; they were not resurrected. The opening policies were cautious expansion, four-person equipment investment and three-person rushing. Their exported checkpoints are in `tests/fixtures/early-saves-*.json`.

## Campaign continuation results

| Midgame policy and source | Runs | Company still alive at ending | Campaign success | Additional hires | Largest fielded group | Claimed a named item |
|---|---:|---:|---:|---:|---:|---:|
| Compact; first-half gear companies | 7 | 3 | 2 | 1 | 4 | 0 |
| Mixed; same first-half gear companies | 7 | 2 | 1 | 2 | 4 | 0 |
| Expansion; first-half cautious and rush companies | 11 | 6 | 5 | 10 | 6 | 0 |
| Planned mixed; holdout gear companies | 8 | 8 | 8 | 7 | 5 | 4 |
| Planned expansion; holdout cautious and rush companies | 15 | 13 | 13 | 20 | 6 | 7 |

Five additional planning pilots use already represented companies, bringing the total to 53 continuations. “Alive” includes unsuccessful month endings; it is not synonymous with victory. A named-item claim can occur in an optional vault without clearing the dungeon. Hires include replacements. These are small deterministic cohorts with different starting states, policies and tactics, not randomized comparisons or human win-rate estimates.

The initial policy bought expedition provisions early, visited towns cyclically and advanced into crypt fights using the existing generic player AI. The revised planning policy reads road schedules, earns through guarded deliveries while recovering, fits usable salvage before selling it, spreads basic equipment purchases across people, and provisions at departure. It attempts the expedition later and withdraws after a victory leaves fewer than four active survivors. These are test-driver decisions, not restrictions in the game.

The holdout policy also holds its line in crypts, uses ordinary attack, shieldwall, spearwall, wait, recovery and weapon-switch commands, and examines optional vaults before advancing. Enemies retain the production tactical AI. A late-round fallback prevents the test policy from creating an endless standoff. The drivers know map and room topology; this is an advantage over a first-time human player.

## Weapons, perks and encounter progression

Earned companies fought outlaws, raider scouts, veteran deserters and undead. Purchases and recovered gear introduced swords, hammers, polearms and crossbows alongside modest starting weapons. Actual battles exercised ranged fire, reloads, spearwalls, counters and alternate carried weapons. All development and perk choices use earned points and each person's unrestricted personal pool.

Most companies could not afford their intended full mixed loadout. Low-tier perks dominate, and only some longer-lived fighters reached mastery choices. These results therefore do **not** establish late-game mastery, duelist, ranged-versus-melee or twelve-person balance. Raw `commands_by_initial_weapon` counts identify the actor's starting weapon, not necessarily the weapon used after a switch; special commands include reloads and stances, and are not damage totals.

## Earned dungeon branches and native reproduction

Eighteen matched branches start from unmodified, legally earned entrance saves. Five claimed a named item and one completed the whole first dungeon. These are tactical alternatives for existing companies, not eighteen additional independent campaigns. Failed attempts and partial expeditions are retained in the results.

The full-clear provenance is:

1. Seed 592, ordinary three-founder campaign, cautious opening through day ten.
2. Exact exported opening state continued with expansion spending through day 16. Three recruits had been hired with actual earnings. Entry mercenaries ranged from level 1 to level 3, using mostly militia spears, a shortsword and shortbow.
3. Defensive exploration from the saved entrance: first-floor descent guards, a second-floor guard chamber and the warden. Optional vaults were explored through legal connected-room moves.
4. Three tactical victories, passive recovery during paid dungeon rests, earned training and two casualties. The side vault yielded **Roderic's Ash longbow**; the final chest yielded **Torsten's Flanged mace**. Both names and rolls came from the existing reserved rewards.
5. Native UI repeated entry, exploration, fights, stairs, rests, both chests and withdrawal. F5/F9 preserved entry, an active battle, the second floor, final reward and exit. The final chest remained empty after reloading.
6. A second native continuation travelled home with the four survivors, spent 40 crowns for 24 rations, previewed the named bow without changing inventory, confirmed equipping it and saved/reloaded. It ended on day 21 with 309 crowns and 28 rations.

The native test loads the earned entrance checkpoint; it does not replay the first sixteen days through mouse clicks. Those days are covered by the production campaign simulations and exact opening reconstruction. All later clicks and battles are real game operations. No `prepare()` or XP-granting dungeon fixture was called; the shared fixture supplies only its route-finding helper.

![Earned final chest](earned-dungeon-reward.png)

![Named weapon comparison after returning to town](earned-named-comparison.png)

## Next balance target

Investigate the supply of intermediate paid work and the opportunity cost of expanding the company. The living world can resolve camps while the player travels or recovers; guarded deliveries can cover survival without producing much growth. More varied, worthwhile risky work is the next design question. A blanket enemy nerf, larger starting bankroll or automatic gear grant is not supported by this pass.

The current campaign ends after thirty days and has three towns, three camps and three dungeons. This test does not settle whether a fully developed twelve-person company should be reachable within that window. Higher dungeon tiers and the parallel dungeon-variety work are outside this baseline review.

## Validation and reproduction

**1,727 checks passed across 17 suites**, including the 48 opening reconstructions, 53 continuations, 18 matched dungeon branches and two native journeys. Runtime identity, coverage, fixture hashes and per-suite results are in `midgame-validation.json`; raw logs are in `midgame-validation/`. The earlier integration suite was not redundantly rerun because no runtime code changed.

With Godot 4.4.1, generate the four exported opening files:

```
godot --headless --path . --script res://tests/early_campaigns.gd -- baseline 0 --export
godot --headless --path . --script res://tests/early_campaigns.gd -- holdout 8 --export
godot --headless --path . --script res://tests/early_campaigns.gd -- gear 0 --gear --export
godot --headless --path . --script res://tests/early_campaigns.gd -- gear-holdout 8 --gear --export
```

Continue companies and run the earned branches:

```
godot --headless --path . --script res://tests/midgame_campaigns.gd -- compact gear
godot --headless --path . --script res://tests/midgame_campaigns.gd -- mixed gear
godot --headless --path . --script res://tests/midgame_campaigns.gd -- wide baseline
godot --headless --path . --script res://tests/midgame_campaigns.gd -- mixed baseline 395 --planned
godot --headless --path . --script res://tests/midgame_campaigns.gd -- mixed gear 1 --planned
godot --headless --path . --script res://tests/midgame_campaigns.gd -- wide baseline 789 --planned
godot --headless --path . --script res://tests/midgame_campaigns.gd -- mixed gear-holdout -1 --planned --defensive
godot --headless --path . --script res://tests/midgame_campaigns.gd -- wide holdout -1 --planned --defensive
godot --headless --path . --script res://tests/earned_expeditions.gd -- planned
godot --headless --path . --script res://tests/earned_expeditions.gd -- wide
godot --headless --path . --script res://tests/earned_expeditions.gd -- mixed-gear
```

The packaged native fixture preserves the tested entrance. Run `earned_dungeon_ui.gd` then `earned_return_ui.gd` in an imported project with a graphical display and isolated user-data directory. Both use ordinary saves. Older raw logs use `actions` for the subsequently clarified `commands_by_initial_weapon` diagnostic and floating-point seed suffixes; these naming changes do not affect game state.
