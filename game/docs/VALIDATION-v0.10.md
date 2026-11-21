# Validation — generated people prototype 0.10

Tested with official Godot 4.4.1 on Linux x86-64. Native tests use a 1440×900 window, OpenGL compatibility, Mesa software rendering and isolated save directories. This validates the Godot source project; standalone Windows/macOS exports and human enjoyment are untested.

## Final suites

| Suite | Checks | Failures | Scope |
| --- | ---: | ---: | --- |
| `tests/run.gd` | 1,160 | 0 | Core tactics; 200 baseline-army battles |
| `tests/fields.gd` | 486 | 0 | 160 baseline-army battles across fields/objectives |
| `tests/world.gd` | 953 | 0 | Regional accounting, patrols, contracts and save migration |
| `tests/company.gd` | 1,163 | 0 | 30 generated-company month attempts; 65 complete battles |
| `tests/progression.gd` | 80 | 0 | XP, perks, scars, recruitment and replay protection |
| `tests/formations.gd` | 564 | 0 | Paid orders, group movement, exact costs, migration; 120 baseline-army battles |
| `tests/relationships.gd` | 123 | 0 | Social accounting and compatibility; 80 paired ridge battles (40 frozen v0.7) |
| `tests/playability.gd` | 42 | 0 | Exact forecasts, real feedback and one generated-company escort battle |
| `tests/people.gd` | 10,181 | 0 | 250 generated populations / 9,000 people; identity, costs, growth, persistence and migration |
| `tests/ui_flow.gd` | 48 | 0 | Older-save compatibility: full month; 2 battles |
| `tests/tour.gd` | 31 | 0 | Older-save compatibility: escort/recovery; 2 battles and 1 retreat |
| `tests/politics_ui.gd` | 29 | 0 | Older-save compatibility: councils, funding and regional consequences |
| `tests/progression_ui.gd` | 41 | 0 | Older-save compatibility: Ida’s recruitment, promotion and later death; 3 battles |
| `tests/scars_ui.gd` | 33 | 0 | Older-save compatibility: Bram’s injury, treatment and lasting scar; 2 battles |
| `tests/formations_ui.gd` | 33 | 0 | Older-save compatibility: clicked orders, advance and hit report; 1 battle |
| `tests/relationships_ui.gd` | 46 | 0 | Older-save compatibility: earned bond, death, grief and paid support; 3 battles and 1 retreat |
| `tests/playability_ui.gd` | 37 | 0 | Older-save compatibility: opt-in guide, forecast, feedback, reload; 1 battle |
| `tests/people_ui.gd` | 50 | 0 | Generated people: seed entry, profiles, actual hiring/growth, reload and ending; 2 battles |
| **Total** | **15,100** | **0** | **626 model battles, 16 complete native battles and two confirmed retreats** |

Of the model battles, **586 use current rules and 40 use the frozen v0.7 engine**. The generated-company coverage comprises 65 battles in the month suite, one escort in playability and two native battles. Core field/formation benchmarks retain the baseline armies so changed personal populations do not confound their rules comparisons. Fixture settlements, diagnostic retries and the release smoke battle are excluded from complete-battle totals. Check totals include repeated accounting and round-trip assertions, not that many distinct gameplay scenarios.

## Generated population and persistence

Seeds 1–250 each create six founders and 30 weekly candidates. Checks cover valid ranges, unique names within the 36-person campaign population, eight backgrounds, all six temperaments, varied aptitude combinations, two mail coats, at least three shields, no more than two bows and starting wages at most 36/day. Every starting snapshot round-trips through JSON exactly and matches a second company made with the same seed. Different seeds produce different companies.

Candidate inspection returns detached copies and consumes no RNG. A week transition reveals the board generated at campaign creation; loading preserves that same candidate. Hiring retains the advertised name, temperament, aptitudes, attributes, wage and equipment, charges the quoted fee once and leaves the deceased predecessor’s history intact. Explicit casualty and promotion fixtures isolate those accounting assertions; they are not reported as won battles.

An earned attribute choice grants the displayed aptitude-dependent gain, records it and leaves the separate perk choice available. Spent, unearned and posthumous choices are refused without mutation. Profiles, purchases, gains and histories persist. Malformed age, talent, temperament, movement, development, duplicate candidate names and incomplete recruit pools are rejected atomically.

## Actual mechanical differences

With gear and other state held fixed, tests check aggressive accuracy/cost, cautious incoming and outgoing hit arithmetic, independent versus sociable positioning, restless movement/guard cost, resolve and stoic morale shock, and personal recovery at the actual turn boundary. A legal movement spends its exact personal fatigue. Two soldiers making the same three-AP group step spend 3 versus 12 movement fatigue; one exhausted member blocks the entire group without partial movement or charges. Active-battle snapshots preserve personal fields and RNG exactly.

The existing progression tests still verify perk and scar effects. Wound/scar fixtures use the person’s actual maximum HP, and economy assertions use the company’s actual wage sum instead of assuming six fixed wages.

## Native generated-company journey

A fresh native launch creates six generated founders and immediately saves them. F9 retains that exact company. New Company keyboard input creates seed 7392, then seed 842, then 7392 again; the repeated seed reproduces the whole initial snapshot. The random-seed control changes the proposal, and cancellation leaves the current company intact. New companies offer the optional guide.

The journey opens founder and candidate profiles, verifies unavailable training/full-company hire controls, and deploys the generated people through normal contract and travel input. Active combat reload preserves temperament, abilities and RNG. The ford battle is actually won with five survivors. Dora earns her first promotion, develops attack skill from 72 to 75 with aptitude 1, and separately learns Weapon handling. The next town’s inspected recruit is hired through the profile and survives reload with the same identity and potential.

The same company continues through a second actual battle, replacements, paid supplies, treatment and rest. This deliberately ordinary spending policy ends on day 24 through three unpaid days, with four living soldiers. That is a tested loss path, not a successful full month. The ending and memorial reload exactly. Separately, the 30 generated model month attempts reach **20 successful endings, 3 shortfalls, 5 unpaid disbands and 2 total losses**, across 65 battles. These are automated-policy outcomes, not a measure of human difficulty.

![Generated candidate, fully disclosed before purchase](generated-recruit.png)

![Real promotion spent on a personal attribute](generated-development.png)

## Older-save compatibility

The earlier native journeys contain assertions about Aldric, Bram and Ida. They now explicitly load a frozen v0.9 starting save through the normal load path, then use the current game for actual camp input, purchases, combat, treatment, training and social consequences. They do **not** stand in for generated-company testing. The dedicated generated journey disables this fixture mechanism entirely.

Older campaign saves preserve their people, gear, wounds, progression, relationships, recruit boards and active battle state. New personal fields are neutral; no age or temperament is invented. Migration checks cover a guarded active v0.9 battle and older schema paths. Old saves lacking optional guide metadata correctly resume with hints hidden; the compatibility guide journey explicitly enables hints through the UI before testing hide/show persistence.

The older native full-month journey still reaches day 31 with six living soldiers, two memorials, two victories, a secure region and 102 crowns. Compatibility journeys total 14 completed battles and two retreats. Input and normal legal combat commands supply their outcomes; no combat wins or resource grants are injected after loading the declared starting fixtures.

## Limits and release checks

Two aptitudes and one temperament provide mechanical individuality; portraits, branching background events, evolving temperament, companion dialogue, reserve rosters, individual initiative and an expanding talent tree remain future work. The party cap is six living soldiers. Names and backgrounds come from finite pools. Age affects generation only. Background bias is not a class restriction, and all weapons currently use one attack-skill stat.

The historical v0.9 balance experiments are preserved in `VALIDATION-v0.9.md`. Their fixed-founder month rates should not be treated as the new population’s results. Further human playtesting should examine whether personal differences create useful equipment, formation and development decisions, and whether the economic warnings are sufficient.

The release process checks archive CRC, imports a clean extracted copy and runs its headless smoke battle. Screenshots are captured from the native application and visually reviewed; they are not mockups. The ordinary unsupported-VSync warning from the software display is benign. Script errors and failed checks are not accepted.
