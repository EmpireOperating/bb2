# Continuing campaign — 0.36

## Behavior

New native companies have no thirty-day finish. Wipes and three unpaid days still end the company. The ordinary three-founder starting equipment and resources, 20-living/12-field limits, enemy forces, combat math, item prices and contract payouts are unchanged. Player access remains independent of equipment ratings, backgrounds or party level.

The delivered Battle-Time-Freeze pack is merged over 0.35 using its alternate source patch for the previously integrated two-hour clock. Tactical victory, defeat and retreat pause campaign time, including loaded older active battles. Settlement still handles real casualties, wounds, XP, wear, salvage, rewards and ammunition. Immediate camp-clear consequences reconcile without a daily tick. Already settled saves keep their recorded date/resources; no refunds or duplicate rewards.

Four hours of dungeon rest now use ordinary midnight rations and wages. Previously every rest charged an additional whole day's food, so resting for 24 hours could cost seven days' rations. This was an excessive recovery expense in the fresh runs. Healing and repairs still require time, food/medicine/tools under the normal recovery rules; scouting fresh rooms still costs food, and supplies do not regenerate. Hungry companies may rest but cannot gain free food-dependent healing.

The calendar work also extends weekly recruits, market validation, signed contract deadlines, company/world save dates, relationship history, camp generations, replacement identities, XP ledgers and purchase history. Validation retains types, identities, per-event values, unique records and conservation checks. Day-derived bounds replace month-only aggregate limits where appropriate. Historical data still grows; this release does not claim unbounded memory/performance.

During fresh travel a cleared camp reoccupied after an escorted wagon departed. Arrival checked the camp's new state, left the wagon at the old waypoint and produced an invalid save. Legal departure now commits the final escort leg. Reoccupation behind the convoy cannot cancel that commitment; ordinary physical roaming contacts remain possible. Both continuous travel and the legacy instant-travel helper use the rule.

## Existing companies

Old saves round-trip with their original people, equipment, map and capabilities. An older active campaign retains its month objective; after the month, a surviving company can use **Continue campaign**. This is also available on a previously completed 0.35 company. It clears only the calendar ending, adds no resources/health/XP, keeps losses and current market stock, and saves as an open campaign. Wiped or disbanded companies cannot continue.

The main filename remains `user://ashen-company-save.json`. Open campaigns use wrapper version 32 with `career_base_version` preserving the underlying schema. Monthly saves retain their previous wrapper. New open campaigns require this executable or newer. Old battles also receive the universal zero-time settlement rule.

The original five recruit weeks retain their existing generated records. Further weeks add two ordinary randomized offers per town, using a separate deterministic weekly seed; browsing and reload do not reroll them. Display first names can repeat over long careers; offer and soldier identities remain distinct. Stats, talents, backgrounds and modest starting kits use the existing generators.

## Fresh earned progression

Four fresh companies used the final zero-time/rest rules, ordinary founders, paid recruitment/supplies/equipment, earned XP/perks and legal tactical AI. No resources, people, equipment, victories or XP were granted. The driver attempts Blackbarrow and then Fallen Watch, returns for work/recovery and runs until a genuine ending or the end of day 90.

| Seed | Day | Living | Career deaths | Crowns | Food | Blackbarrow | Fallen Watch |
|---|---:|---:|---:|---:|---:|---|---|
| 1 | 9 | 0 | 5 | 68 | 24 | Not cleared | Not cleared |
| 71 | 91 | 12 | 8 | 22,572 | 42 | Day 27 | Day 50 |
| 592 | 91 | 12 | 6 | 32,679 | 52 | Day 23 | Day 45 |
| 789 | 91 | 12 | 5 | 35,430 | 48 | Day 24 | Day 42 |

These are four deterministic policy runs, not human win rates. Seeds 71, 592 and 789 were previously productive growth seeds; seed 1 is a difficult opening. The driver knows world and room topology, targets twelve, buys a limited set of intermediate equipment and selects preparation thresholds. Those are test choices, not player gates. It does not evaluate every build, buy every premium kit, maintain twenty paid members or attempt King's Sepulchre.

The concrete progression goal is met: surviving companies recruit and buy upgrades beyond the first month, clear Blackbarrow and reach/clear Fallen Watch. Losses and replacement hires remain real. The day-90 wealth also exposes a limit: mature twelve-person companies can accumulate substantial money by repeating smaller road jobs. This pass is not a claim that the late economy is finished. Travel scale, premium-equipment spending and later contract variety need balancing together; no enemy-stat nerf or equipment gate was added to manufacture success.

Daily resources, hires, purchases, combat outcomes and expedition attempts are in `docs/long-campaigns/long-final-*/report.json`; exact earned saves accompany the reports. Development runs with the old rest surcharge and the discovered escort error are outside the release cohort. Their outcomes are not counted as successful final-build runs.

## Native acceptance and limits

- **Battle clock:** 86 checks; two actual victories and two real UI retreats across overworld/dungeon battles, exact active/aftermath/return F5/F9, frozen time and no battle upkeep. Prepared timing fixtures, not earned careers.
- **Career continuation:** 31 checks; loads the exact earned 0.35 seed-71 day-31 company, clicks Continue, completes a real road hunt for 572 crowns, buys supplies, rests to day 36, sees two week-six recruits and saves/loads. No grants. The battle leaves all twelve alive.
- **Fallen Watch:** 13 checks; loads the actual final-build seed-789 captain-room save, fights the nine-enemy boss encounter, wins with twelve living and three wounded, claims 1,400 crowns and Aldren's Reinforced mail, and verifies no duplicate chest after F5/F9. This is a native continuation of an earned model career, not a full native 41-day playthrough. The model driver rests after the boss before looting, so its completion date is one day later than the native segment.
- The calendar suite runs a funded 120-day observer fixture to isolate clock, markets/recruits and serialization, including corruption rejection and legacy continuation. It is not economic evidence. The escort and 24-hour underground food checks are explicit state fixtures.
- Historical 0.34 combat continuation stays exact. For old post-battle fixtures, only a test-owned copy adds the removed day back before comparing its historical oracle. The live company is separately checked for frozen time.

Screenshots were visually reviewed for the continuation button, day 31, week-six recruits and the earned boss aftermath/treasure. The final battle version-label typo was corrected afterward; it does not change gameplay.

23 successful model/native runs contain 6,142 assertions, including repeated state checks; this is not a count of distinct scenarios. Exact successful logs and counts are in `docs/validation-0.36/`.

## Reproduce

Use Godot 4.4.1 from the project directory:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/career.gd
godot --headless --path . --script res://tests/career_edges.gd
godot --headless --path . --script res://tests/battle_clock.gd
godot --headless --path . --script res://tests/long_campaigns.gd -- 789 90 final
```

The other earned seeds are 1, 71 and 592. Native scripts require a graphical display and isolated user data: `battle_clock_ui`, `career_ui`, `fallen_watch_ui`. They render real Godot controls and use legal battle commands.

## Scope for the next merge

The new Expanded Region pack was downloaded and inspected but is not part of this release. It is a separate six-town map/camera expansion based on Living Camps and still carries the old month-only schedule. Its campaign `setup` eleventh positional parameter means expanded geography; this release's eleventh parameter means open campaign. A future merge must reconcile that signature explicitly, generalize `Career.TOWNS`/weekly generation/market and road-posting assumptions to the saved map, preserve wrapper 32 and frozen battles, and retain the main save filename. Do not overwrite current files with the pack snapshot or apply its cumulative 0.33 patch here.

Source hashes and merge provenance are in `CAREER-0.36-SOURCES.json`. Earlier reports and validation remain historical evidence for their own releases.
