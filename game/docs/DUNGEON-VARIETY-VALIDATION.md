# Dungeon variety validation

Godot 4.4.1 stable on Linux. Native checks use the actual Godot application at 1440×900 with the compatibility renderer. The offscreen display reports an unsupported VSync warning; it does not prevent rendering or test completion.

## Automated checks

| Suite | Checks | Failures | What it establishes |
| --- | ---: | ---: | --- |
| dungeon_variety | 3,699 | 0 | Eight generation seeds, repeatability, connectivity, optional vault routes, fixed rewards, discovery, old-save adoption, strict corrupt-save rejection, twelve-melee and twelve-archer deployments |
| dungeon_variety_journeys | 263 | 0 | Three prepared expeditions, actual combat and retreat, enemy wear, chest maps, named rewards, return visits, no repeated settlement, fixed battle time |
| dungeon_challenge | 2,166 | 0 | Original three landmark expeditions and decision rules on the new version |
| dungeon_challenge_compat | 22 | 0 | Exact older dungeon save compatibility |
| dungeons | 1,155 | 0 | Original dungeon behavior and full expedition |
| dungeon_tactics | 153 | 0 | Existing landmark boss behavior |
| dungeon_tactics_retreat | 27 | 0 | Exact earned boss wear after retreat/re-engagement |
| battle_clock | 241 | 0 | Uniform frozen combat time and settlement timing |
| battle_clock_world | 25 | 0 | World-state timing around battle settlement |
| career | 359 | 0 | Calendar/continuation fixture; not economic evidence |
| career_edges | 17 | 0 | Career continuation edges |
| dungeon_variety_careers (71 / 592 / 789) | 434 / 276 / 273 | 0 | Three fresh companies under normal campaign rules |
| dungeon_variety_earned_ui | 18 | 0 | Exact earned tier-three final fight and chest through native controls |

The two prepared headless complexes cleared three and two floors, respectively, plus every side treasury; their survivor counts were twelve and ten. The barrow ended with all six. These fixtures explicitly supply equipment, XP and provisions and are not balance evidence.

The final isolated native prepared run passed 184 checks with zero failures: twelve actual dungeon battles across a barrow and two large complexes, 3 recovered maps, native travel, optional guarded treasuries, F5/F9 in combat and after loot, withdrawal/re-entry and persistent opened chests. All three expeditions completed. Their gear, XP and supplies are explicit preparation fixtures.

## Earned progression

Each career begins with three ordinary founders and 300 crowns. The driver earns pay and XP, buys supplies/equipment, hires and develops mercenaries, travels and fights normally. It knows destinations and room graphs and uses the production AI for player actions. It attempts small barrows after day eight with at least five available fighters, and complexes after day thirty with at least ten. Those are test-driver decisions, not game restrictions. Optional treasuries are skipped by these economic runs. Failed expeditions can be retried after recovery and work. The audit stops after all six clears, a genuine campaign ending or passing day ninety.

| Seed | Sites cleared | Last clear day | Audit end day | Living at audit end | Career deaths | Crowns | Food |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 71 | 5/6 | 69 | 91 | 12 | 8 | 13658 | 0 |
| 592 | 6/6 | 58 | 61 | 12 | 10 | 3393 | 51 |
| 789 | 6/6 | 59 | 61 | 12 | 6 | 5446 | 69 |

Seed 71 cleared its barrows on days 13, 16 and 20. It left the first complex unfinished on day 34, returned and cleared it on day 50, and cleared the second on day 69. Its tier-three attempt ended unfinished on day 83 with nine survivors from twelve entrants; the company later rehired and reached the audit horizon with no food. This is a recorded supply/recovery limitation, not a successful six-site run. This patch does not tune the broader world economy or recovery systems.

Seed 592 cleared its barrows by day 16. Its complexes cleared on days 36, 50 and 58, with an unsuccessful visit to the second complex on days 38–42 followed by a successful return. Seed 789 cleared all six by day 59. Both drivers returned to town and recorded their final reports on day 61. End-of-audit living counts include subsequent hiring and are not the survivors of the last dungeon fight.

The native earned check loads the unmodified seed-592 checkpoint immediately before the tier-three final fight: day 58, ten mercenaries. Nine survive the actual fight. The chest yields its previously reserved named brigandine; F5/F9 and leaving/re-entering preserve the cleared site and item, with no duplicate reward. Fixture SHA-256: `bd151a8844a4223aeb9c86feb994a6a38340ac1413e8ee27dcc2d809dec18dd4`. It exactly matches `variety-earned-592/dungeon_complex_2-fight.json` in the career evidence.

These are three deterministic policy runs, not a statistical difficulty study. They show that normal progression can clear the additions, and that persistent unfinished expeditions matter. They do not establish universal affordability or success across seeds, parties and human tactics.

## Packaging and reproducibility

Both patches applied cleanly, in sequence, to a fresh checkout of the stated 0.36 baseline. All twenty then-staged variety files matched the working implementation byte-for-byte. A fresh Godot import reported no errors; the clean tree independently passed dungeon_variety (3,699 checks) and dungeon_variety_journeys (263 checks). Final packaging adds this validation report and evidence without changing production code.

Run headless suites from the Godot project root, for example:

```sh
godot --headless --path . --import
godot --headless --path . --script tests/dungeon_variety.gd
godot --headless --path . --script tests/dungeon_variety_journeys.gd
godot --headless --path . --script tests/dungeon_variety_careers.gd -- 592 90
```

Run native suites in a display with a separate `XDG_DATA_HOME` so they do not overwrite a player's save:

```sh
godot --path . --audio-driver Dummy --script tests/dungeon_variety_ui.gd
godot --path . --audio-driver Dummy --script tests/dungeon_variety_earned_ui.gd
```

Initial harness attempts exposed an illegal replay checkpoint (saving an already-finished battle before settlement) and a missing exit before starting the next native company. The harness now replays a valid pre-fight save and exits each site normally. Overlapping early native attempts wrote to the same log; those runs were discarded as validation, and the final run uses isolated saves, output and screenshot paths. No game rules were weakened to make a test pass.

Existing native dungeon UI expectations were updated for the nine-site world and destination-based rumour discovery. The inherited full legacy UI suites were not separately rerun; the new native variety and earned suites exercise the changed presentation and controls. The full repository-wide test suite was not run.
