# Terrain Rules — bounded Battle Brothers adoption

## Authority and opt-in

`Battle.terrain_rules_enabled` defaults to `false` and `setup()` resets it to `false`. The successor deployment adapter enables it after installing a validated authored map. The predecessor remains on its original rules. This is the existing Battle simulation, command ledger, RNG and damage system, not a second combat engine. Custom terrain fights are not added to the stock snapshot format; the successor saves camp only.

`Battle.movement_edge(unit, from, to)` returns `{ap, fatigue, reason}`. Enabled ordinary movement queries, route search, movement execution and group costs share `TerrainRules.edge`. `step_cost` uses the same geometry without a unit/Pathfinder. Withdraw, Hook, Rotation and Footwork therefore cannot bypass blocked terrain or the one-level edge limit; their ability prices remain unchanged. `terrain_attack_reason` is the one enabled attack-geometry path used by both `in_range` and `reach_block_reason`, hence weapon commands and AI. Reaction admission uses the same height-aware melee/ZOC predicates. `strike` remains the existing damage resolver, not a public action-admission replacement.

## Ordinary movement

Costs apply to the entered tile. Height changes in **either direction** add **1 AP / 4 fatigue**. Ordinary traversal is capped at **one level per edge**. Pathfinder reduces terrain AP by one, with a minimum of two, halves terrain fatigue, removes the elevation AP charge, and **does not halve elevation fatigue**. Existing `perk_rules` still owns whether personal perks are active.

| Authored tags | AP | Fatigue | Pathfinder AP / fatigue |
|---|---:|---:|---:|
| `grass`, `hill` | 2 | 4 | 2 / 2 |
| `road`, `stone`, `ford` | 2 | 2 | 2 / 1 |
| `forest`, `mud`, `rough` | 3 | 6 | 2 / 3 |
| `rubble`, `rocks` | 4 | 8 | 3 / 4 |
| `swamp` | 4 | 14 | 3 / 7 |
| `sand` | 2 | 6 | 2 / 3 |
| `shallow_water` | 4 | 12 | 3 / 6 |

`water`, `deep_water`, `wall` and `blocked: true` are impassable. Unknown terrain refuses movement rather than receiving a cheap default. A `forest` floor is not automatically a tree. Authored tree/wall/boulder obstacles use explicit flags.

Sources: retained research [24], [29], [47], [48], [85]. Paved Pathfinder fatigue **1** follows the explicit guide table and wiki's “half”; the unofficial snapshot's conflicting paved value is not silently adopted. The source-declared traversal cap is one; **native retail descent/fall enforcement was not obtained**. Applying that cap to safe displacement geometry is this bounded prototype policy, not a claim about every vanilla forced fall.

### Routing, payment and formations

The enabled route search retains nondominated AP/fatigue labels at each tile, then selects an affordable route by lowest AP and fatigue tie-break. This fixes an actually reproduced defect: a 6 AP / 10 FAT sand route previously erased an 8 AP / 8 FAT road alternative at their shared junction, making the destination falsely unreachable with eight fatigue free. The positive test executes the real alternative route and charges 8 / 8. Movement explanations check the current affordable route before presenting resource-shortage diagnostics.

No path-preference `+4` is charged as movement AP. There is no new ZOC preference heuristic. Routes show terrain costs, **not a guarantee of reaching the end through reactions**. Execution charges each attempted edge and rechecks remaining resources after reaction fatigue; a hit, death or insufficient remaining capacity can terminate an accepted route partway. The return value means an accepted command/attempt, not guaranteed arrival.

Formation advance retains its predecessor restriction that all selected members must be unengaged; disengage them individually first. Its simultaneous occupancy semantics remain intact. Each member now pays its own exact AP/fatigue pair, including Pathfinder, and arrival brace reactions use the same height rules. This is not a new coordinated disengagement ability.

## Engagement and attacks

- Ordinary ZOC: adjacent tile, absolute height difference at most one, living/nonfleeing melee-capable holder. Stunned, dying, sleeping, entangled and horrified flags exclude the holder. Ranged weapons do not exert ZOC. Reach does not enlarge its radius. The current project does not gain new status-application systems; a stagger is not silently reinterpreted as a stun.
- **Ordinary disengagement is now a legal paid attempt.** Leaving any controlled tile, including another controlled destination and routed movement, triggers controlling hostiles' free strikes in stable unit order. A connecting strike stops departure; misses permit it. AP/fatigue for that attempted edge remain spent. Existing incoming-hit/miss fatigue and damage still apply. The controlling unit spends no AP/fatigue, and these strikes do not consume the custom brace/riposte counter. Processing stops at the first hit/death; full retail multi-controller ordering was not recovered.
- Invalid requests are rejected before movement payment or opportunity RNG. A valid attempt that fails because a real strike hit is not classified as an invalid request.
- Withdraw preserves its fixed **4 AP / 12 fatigue**, but enabled mode also stops its departure on a connecting opportunity strike. Footwork/Rotation retain their fixed perk prices and safe-disengagement semantics. Hook retains the real weapon-action price and only pulls into a legal vacant neighboring tile; no fall damage or new forced-movement effects are added.
- Melee and reach attacks have a **one-level target height cap**. Horizontal polearm reach does not create vertical reach. Distance-two reach also checks the discrete world-midpoint hex's high-ground condition from the readable skill validator. The inherited cube-rounding tie-break and open/allied thrust-lane policy are retained, not certified as the native visibility algorithm.
- Current conventional ranged weapons have a **four-level target height cap**, and gain **one horizontal hex of maximum range per level downhill** (subject to that cap). No uphill range subtraction is invented. Existing weapon minimum/base ranges and Bow Mastery remain authoritative. All conventional ranged families, including throwing, are blocked by actual hostile ZOC.
- Accuracy is **flat +10 percentage points downhill**, **−10 per level uphill**. The existing core formula already agreed; enabled non-core previews now use that same terrain modifier. Planar `distance` is unchanged, as are the existing distance accuracy penalties, damage, perk bonuses and head-hit rules.
- Brace considers entry into the height-aware controlled area, including entry from an adjacent but previously height-separated tile. Riposte requires a currently capable holder and legal melee geometry. Their existing reaction charges/counters remain unchanged.
- Hypothetical AI shot geometry ignores the querying actor's old body position. This fixes a reproduced read-only planning inconsistency without moving the real actor or consuming RNG. Actual AI commands still pay through Battle. AI strategy remains heuristic; no claim of globally optimal attack planning, risk avoidance or every reserved-action AP/fatigue tradeoff is made.

Sources: official disengagement description [3]; readable skill/actor/defaults [24], [25], [29], sampled Aimed Shot/Javelin/Impale [31], [33], [72]; wiki corroboration [46], [50]. The max-range and four-level policy concerns the existing conventional projectile catalogue, not all vanilla monster/special/AOE abilities.

## Visibility and cover — explicit limitation

**This is not complete vanilla LOS or cover.** Enabled mode retains the predecessor intermediate-hex hard-blocking model, but terrain blocks only when it has `vision_blocking: true`. Bare forest floor no longer blocks a shot. Bodies retain the predecessor hard-blocker behavior and immediately adjacent allied-rank exemption; the latter is not advertised as the full vanilla cover algorithm. `cover` metadata does not invent an additional rule.

There is **no height-aware sight clearance, eye-height interpolation, ballistic ray, 75% cover diversion, friendly interception, Bullseye cover rewrite or miss-scatter implementation**. The initial cover helper was corrupt. A follow-up recovered a coherent **historical, unofficial vanilla-like** helper ([pinned source](https://raw.githubusercontent.com/kovasap/battle-bros-decompiled/e06d68df0915827967f98a05d0c705c1f53df0b7/scripts/config/tactical_entity_common.nut), lines 31–85), but its native coordinate/direction mapping, current-retail parity and the native visibility algorithm remain unverified. That older helper scans target-adjacent candidates rather than every intervening tile; it has deliberately not been approximated here. Retained qualification: `research/followup/followup.md` in the evidence root. Thus being above a wall does not certify a legal shot over it here. Visual occluder fading is presentation only. These limits must also remain visible in successor player help.

Swamp's sourced melee-skill/melee-defense/ranged-defense multipliers are **not implemented in this pass**. The `swamp` movement table is supported; whole combat-property parity is not. No injury/trait movement-property system, equipment/damage rebalance, headshot elevation bonus or unrelated perk change was added. Existing authored perks, including the predecessor Bullseye effect, remain prototype mechanics rather than claims of vanilla parity.

## Evidence and regression status

Evidence root: `/home/quatro/games/battle-brothers-2-terrain-rules-evidence/rules/`.

All runs used **Godot 4.4.1.stable.official.49a5bc7b6**, `--headless --single-threaded-scene`, private project copies and separate HOME/XDG state, with display/session-bus variables removed. No main-worktree import, GUI, commit or protected-art edits were performed by the rules lane. `run.py` retains raw logs, exact commands, source copies and process exits for each attempt.

- Final focused suite at `21-command-coverage/`: **`TERRAIN_RULES_TEST: 11402 checks, 0 failures`**, exit 0, no runtime errors. Covers all cost tags, both sides/row parities, all six movement directions, uphill/downhill, Pathfinder, affordable tradeoff routes, actual movement/attack/group/Withdraw/Hook/Rotation/Footwork paths, reactions, AI, invalid-request state/RNG preservation and opt-in reset.
- Vertical failures and their subsequent passes are retained: forest `01/02`, movement `03/04`, route defect `05/06`, geometry `08/09`, disengagement `11/12`, reactions/invalid Hook target `13/14`, AI self-blocker `16/17`. `07` used a nonexistent fixture weapon alias (corrected to `javelins`); `10` also dereferenced an empty ledger after an expected refusal (guarded in `11`); `15` initially selected a nonadjacent ramp on one row parity (corrected before `16`). These setup issues are not presented as product RED evidence.
- Paired exact-base/candidate predecessor runs: `18-legacy-baseline/`, `19-legacy-candidate/`, `20-legacy-session-origin-corrected/`. `regression-comparison.json` verifies **byte-identical raw logs for all 15 compared scripts**: nine pass, five retain identical existing failures, one is incomplete in both versions. The company test initially ran under the successor project origin and correctly refused predecessor saves; its corrected private run uses the baseline `project.godot` userdir only, not altered test expectations.
- Passing predecessor gates: scenario 550; general rules 1160; combat baseline 141; archer 396; perks 134; ranged perks 7513; individual turns 2821; fields 486; company session 669.
- Existing failing gates: formations **5**, engagement AI **6**, tactical AI **4**, weapons **37**, armor **97**. `people.gd` raises an inherited out-of-bounds fixture error and is terminated at 120 seconds in both versions, with identical partial logs and **no completion claim**. These are not silently rewritten or called green.
- Additional real integration snapshot `22-live-map-integration/`: maps **98/0**, session **391/0**; real enabled Crossing victory and Woodland defeat, plus casualty/retreat. Those concurrently owned tests were run read-only; final frozen integration/native acceptance remains the parent lane's responsibility.

These are engine-level model/command tests, not proof of native visual quality, human usability or exact retail parity.

## Source references

Mandatory retained report and verbatim evidence: `/home/quatro/games/battle-brothers-2-terrain-rules-evidence/research/vanilla-terrain-rules.md` and the adjacent `citation-evidence.md`. Citation numbers above refer to that ledger. Principal public sources:

- [3] https://battlebrothersgame.com/tactical-combat-mechanics — official free-strike/paid-failed-disengagement description.
- [24] https://raw.githubusercontent.com/ninkjin/Battle-Brothers-Scripts/162f498ac7c49b4c317bbf54718a595ecef6a65a/scripts/entity/tactical/actor.nut — traversal declaration, movement surcharge and ZOC predicate.
- [25] https://raw.githubusercontent.com/ninkjin/Battle-Brothers-Scripts/162f498ac7c49b4c317bbf54718a595ecef6a65a/scripts/skills/skill.nut — attack height/reach/midpoint and range formula.
- [29] https://raw.githubusercontent.com/ninkjin/Battle-Brothers-Scripts/162f498ac7c49b4c317bbf54718a595ecef6a65a/scripts/config/character.nut — movement arrays and height constants.
- [47] https://battlebrothers.fandom.com/wiki/Pathfinder — terrain-cost reduction, elevation fatigue exception.
- [48] https://battlebrothers.fandom.com/wiki/Global_Map — actual terrain tile distinctions.
- [50] https://battlebrothers.fandom.com/wiki/Hit_Chance — asymmetric height accuracy and visibility/cover distinction.
- [85] https://gamerofpassion.com/battle-brothers-perk-guide — retained guide table, especially paved Pathfinder fatigue and elevation examples.

The commit-pinned script snapshot is unofficial translation/decompiler material claiming v1.5.2.2, **not publisher-authenticated or byte-verified retail source**. Corrupt recovered Pathfinder/cover function bodies were not used as semantic authorities. Confidence and conflicts remain those of the research report.
