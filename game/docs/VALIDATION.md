# Validation — formation 0.32

**3,901 assertions, zero failures in 11 final suites**, on Godot 4.4.1 Linux. Counts include repeated checks, not that many unique scenarios.

| Suite | Checks | Evidence |
|---|---:|---|
| `company_roster` | 101 | 20/12 hiring and swaps, upkeep/recovery, reserves, combat settlement, ambush, death pruning; three paired 12-v-12 legal-AI battles |
| `roster_edges` | 36 | High unit IDs, perk origins and corrupt saves; edge placement on all maps/objectives; isolated contract-XP branch |
| `roster_compat` | 26 | Exact delivered 0.31 snapshots, tactical continuation and settlement across two seeds; adoption at camp |
| `living_integration` | 104 | Prior living-world integration and older-save migrations |
| `inventory` | 31 | 4 AP, Quick Hands, Bags and Belts and equipment persistence |
| `recovery` | 21 | Passive repairs, healing, supplies, injuries and temples |
| `turns` | 2,821 | Initiative, waiting and 24 historical campaign fights |
| `archer_rules` | 396 | Friendly adjacency, ranged lanes and three model battles |
| `ammunition` | 291 | Supply conservation, 12 campaign battles and nine historical continuations |
| `roster_ui` | 48 | Native pointer moves/swaps, all twenty reserves, twelve allies, 24 queue portraits, twelve targets, combat settlement and F5/F9 |
| `opening_ui` | 26 | Real three-founder start, fourth hire, travel, camp victory, mail upgrade, recovery and exploration |

## Test boundaries

The capacity fixtures explicitly grant funding and food, visit towns and advance the production day clock to hire across weekly pools. These establish roster limits, persistence and UI behaviour; they do not demonstrate unaided growth to twenty. The 12-v-12 fixtures use existing authored tactical templates and legal production AI commands, with paired saved/restored continuations. They do not add twelve-enemy encounters to the campaign.

The native capacity journey uses real mouse presses/releases for formation changes and ordinary combat commands for its twelve-person victory. A separate visual fixture exposes all twenty-four queue entries and twelve enemy targets. An explicit hunting-band fixture checks ambush placement; a forced casualty/retreat branch checks death pruning. The contract-XP edge test deliberately sets a victory to isolate payout logic. These manufactured branches are not counted as earned victories or balance evidence.

The separate opening journey uses actual New Company, recruitment, travel, a legal camp victory, earned armour purchasing, passive recovery and exploration, without supplying money, damage or wins. It finished on day four after one real battle. This is a playability check, not a full-month difficulty benchmark.

## Compatibility and scope

The exact 0.31 archive used as baseline has SHA-256 `8b2fcee8c4edd71a49e9e20806776dc375c04037a4da4e7cd32595789ff32f84`. Two baseline companies (seeds 198 and 7391) supplied original camp/start/settled/aftermath snapshots plus completed tactical continuations. Current code matches these before roster adoption. Older regression suites also retain prior compatibility evidence.

Only roster/deployment integration, battle capacity/dimensions, corresponding validation, UI and tutorial command tracking changed. Equipment/weapon catalogues and all data files are byte-identical to 0.31. Combat formulas remain unchanged. Existing month-policy results belong to 0.31 and were not rerun or presented as 0.32 balance evidence.

## Reproduce

Run `godot --headless --path . --script res://tests/company_roster.gd` from the extracted project, or substitute another model suite. Native suites `roster_ui.gd` and `merged_maps_ui.gd` require a display and an isolated `XDG_DATA_HOME`; they write screenshots into `docs/` and use that isolated game's save file.

The release is also imported and started from a clean extracted archive, then run through the historical `--smoke` journey. Native full-roster and opening screenshots are included in `docs/`.
