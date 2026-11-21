# Company progression 0.30

## Design

The opening previously handed a modest company from thugs into encounters built from veteran templates. Non-opening scouts could field five or six fighters. New campaigns use explicit enemy grades with complete physical kits and lower-skilled outlaws between thugs and raiders. Camp growth still follows stolen supplies; no player-level or equipment scaling is added.

| Encounter | Composition |
|---|---|
| Crossing camp | Three to four thugs; a stronger band can gain an outlaw leader |
| Woodland camp | Outlaws in cloth/leather, with a raider leader at strength three |
| Deserter camp | Veteran leader, raiders and outlaws; stronger bands have more raiders |
| Roaming scouts | Small groups; actual current band strengths produce two fighters, with the generic count rule capped at three |
| Cargo recovery | Three to four guards using their site's grade rules |

Enemy base skill bands are 46–50, 54–58, 62–66 and 69–73; melee defence is 0, 4, 9 and 14. Health, resolve and equipment also increase by grade. Veteran leaders use mail/brigandine; ordinary raiders mix mail or leather. These are authored encounter baselines, not changes to attack/defence arithmetic. Old companies retain their previous enemies.

## Equipment economics

The existing layered catalogue already provides cheap cloth, leather, short mail, longer/heavier mail, outer protection and reinforcement. New items were not necessary. Selected base prices now give those options distinct economic weight:

| Component | Base crowns |
|---|---:|
| Quilted linen | 24 |
| Leather outer layer | 80 |
| Short mail | 160 |
| Riveted mail | 260 |
| Long mail | 380 |
| Heavy mail | 520 |
| Brigandine | 300 |
| Breastplate | 420 |
| Simple iron helmet | 25 |
| Iron cap | 60 |
| Nasal helmet | 120 |
| Bascinet | 210 |

Town pricing and reputation modify these numbers. Armour purchase quotes, the combined trade screen, resale and replacement estimates all use the same versioned prices. Condition still affects resale; merchant purses remain finite. Stats, fatigue/load, catalogue compatibility and original weapon prices remain unchanged. Greater expense is not a new armour buff. Light builds can keep low load and spend on other layers, weapons or recruits.

## Rebuilding and contracts

A cleared/protected road can now advertise escort work for an existing waiting wagon. Base pay is 100 + cargo before reputation; payment requires arrival at the destination after the checkpoint. This creates lower-risk income while travel progresses recovery. It is not guaranteed safety: patrols can leave or bands can reoccupy the road. The signed price stays fixed, and a newly threatened checkpoint requires defence. Cargo, delivery and rewards remain one-time transactions.

Clear contracts add 50 base crowns at the woodland camp and 110 at the deserter camp. Crossing pay and supply prices are unchanged. Recruitment remains two candidates per town per week; living roster limit remains six. Company plan points to guarded work or the next loading day, with the food-supply condition stated.

## Month evidence

| Policy | Successful endings | Contracts | Battles | Deaths | Replacement hires | Mean final body max / fighter |
|---|---:|---:|---:|---:|---:|---:|
| Expand toward six | 8/8 | 61 | 49 | 10 | 10 | 81.5 |
| Keep four | 8/8 | 63 | 53 | 9 | 9 | 119.0 |

Eight map/company seeds are run with each policy. Every job, hire, purchase, sale, level choice, perk, route, fight, recovery hour and upkeep payment uses production rules. No free crowns/XP/equipment, forced victories, stat bonuses or casualty removal are used. Policies stop at the actual day-31 checkpoint or company ending. They equip available loot and maintain different load budgets for ranged/light versus shield fighters. Navigation knows site coordinates; this does not test discovering routes as a human.

The four-person policy bought its first short mail as early as day three; larger companies generally bought it later because recruiting consumed their reserve. Purchases are only one source of upgrades: recovered kits also improve protection. Replacement hires are counted per person, including multiple hires after one battle. Raw records: [current month runs](month-campaigns-0.30.json), [prior-rule baseline](month-baseline-0.29.json).

The baseline uses the final policy driver against the retained prior rules. All eight baseline companies wiped out. The new cohorts all succeeded, which establishes viability under these choices and may also indicate generous outcomes for cautious delivery play. Multiple systems changed together; this is not an isolated causal measurement. Full veteran assaults, every build and less cautious strategies remain unproven. Human playtesting is still required.

![Rebuilding guidance](month-rebuilding-plan.png)

The guidance screenshot uses an explicitly cleared-region UI fixture. The quiet delivery UI test isolates acceptance, checkpoint travel, physical cargo arrival, purchase and reload. It is not counted as a naturally won campaign. The separate opening native journey fights two real battles. The end-of-month native view loads an actual earned seed-198 result from the full-month driver, containing two casualties and their replacements; it does not click through a whole month.

![An earned month-end company](month-end-company.png)

## Compatibility and entry points

Campaign schema 25 stores `progression_version: 1`. The reader rejects missing, unknown and mistyped rule versions before mutating the live company. New native-company controls explicitly enable the rules. For tooling, `Campaign.setup(seed, map_seed, true)` creates a 0.30 company; the omitted third argument retains old rule behavior for historical callers/tests. Restored older companies omit the new field and retain prior schema and pricing. Captured delivered 0.29 ongoing battles continue with identical commands/RNG/casualties and settlement.

Run `godot --headless --path . --script res://tests/month_campaigns.gd -- --new-rules` for the sixteen-company trial. Omit `--new-rules` for the prior-rule baseline; `--pilot` restricts it to four seeds, each with both policies. `--showcase --new-rules` replays the seed-198 six-person policy and captures the earned final state for the native end-view check. Native tests require a graphics display.
