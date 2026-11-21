# Ruined Crossing — systems audit

## Scope and evidence boundary

This is an **ephemeral presentation prototype over the unchanged combat engine**, not a new combat implementation or campaign mode. `scenario.gd` returns an actual `res://src/battle.gd` instance; it changes starting data only. The scenario has no Campaign instance, save writer, combat override, physics-driven combat, or replacement AI.

The headless evidence below was produced with Godot **4.4.1 stable**, using `--headless --single-threaded-scene`. No GUI was launched by this audit worker. Final integrated native testing, screenshots, limitations and the incomplete inherited UI journey are recorded separately in [VERIFICATION.md](VERIFICATION.md); static observations here are not native visual proof.

Evidence root: `/home/quatro/games/battle-brothers-2-25d-evidence/`.

- Final scenario execution: `scenario-08-full-contract.log`.
- RED/GREEN construction evidence: `scenario-01-red-factory.log` through `scenario-06-green-equipment.log`.
- Existing suites: `baseline-tests/<script-stem>/output.log` and `status.json`; aggregate `baseline-tests/summary.json`.
- Protected-byte comparison: `protected-content-manifest.json`. All **1,063 files** enumerated under existing `src/`, `data/`, and `tests/` matched both the immutable original and the private baseline test copy. No legacy source or test was repaired to obtain a pass.

## Authoritative state and integration contract

`Battle` is a RefCounted rules object, not a scene. Its live state is:

- `tiles["q,r"] = {"terrain": String, "height": int}`;
- `units[id]`, with offset `q/r`, `side`, HP, AP, fatigue, morale, active `arms`, physical `armor_parts`, and perk state;
- `side`, `round_no`, `result`, local deterministic `rng_state`, `commands`, and human-readable `events`;
- `combat_feedback(event)` for actual hit/miss, armour/HP loss, shield wear, morale, routing and death feedback.

`create(seed_value: int = 7391)` calls the existing `setup` with advanced weapons, pooled damage, core combat and personal perks enabled, **individual turns disabled**, six combatants per side and the eliminate objective. Tactical/engagement AI, inventory, double-grip and current weapon-family flags are enabled by that engine setup. The factory explicitly calls the existing `initialize_stats` for each fighter: setup otherwise does this only for initiative turns, while core hit/morale code needs those fields in side mode too.

All friendly fighters can act on their side; there is no initiative-selected actor. The renderer/controller must call `movement_map`, `move_unit`, `can_attack`/`weapon_action_reason`, `attack`/`use_weapon`, `end_turn` and `ai_step`. `battle_controller.gd` currently follows this command boundary. A successful attack command means an attempted, paid attack, **not a guaranteed hit**.

### Important side-turn and persistence limitations

- This combination is intentionally in-memory. Stock `Battle.restore` rejects pooled-damage snapshots with `individual == false` (`battle.gd`, restore's `pooled`/`new_turns` check). A regression test confirms rejection leaves the receiving battle unchanged.
- `Battle.snapshot()` does not serialize custom `tiles`; stock restore reconstructs one of its built-in maps. Therefore snapshot equality in these tests proves deterministic state continuation from fresh factories, **not custom-map save/load support**. Do not route this prototype through campaign saving.
- Side `end_turn` does not call individual `activate_next`/`complete_activation`. Consequently activation-timed perk resets/expiry and individual-activation automatic rally are not implemented for this mode. The authored fighters use only passive shield/steel-brow/mastery perks, not temporary or once-per-activation perks. No hidden repair or custom timing rule was added.
- Stances, side AP refill, fatigue recovery, stagger, routing, victory/defeat and the round-31 draw cap remain whatever the existing side-mode engine implements. These are not claims of equivalence with the full individual-turn campaign mode.

## Map and equipment

The complete **13 × 9** map lives in `battle.tiles`, not in decorative height metadata:

- River column `q=6` is impassable water except the **single** ford `(6,4)`. The presentation may render that ford as a stone bridge; mechanically it remains a normal 2-AP ford tile, not a new terrain type.
- Left plateau: `q=2..4, r=1..2`, height 1.
- Right plateau: `q=8..10, r=1..3`, height 1; `(9,1)` is height 2.
- Real wall blockers: `(4,2)`, `(4,3)`, `(8,2)`, `(9,2)`, `(9,5)`, `(10,5)`. Additional northern caps `(9,0)` and `(10,0)` prevent direct level-0/level-2 peak edges. The remaining peak entrances are level-1 slopes.
- Stone crossing approaches and mud banks use existing terrain types. There is no hidden cover field.
- Final integrated scenario includes genuine forest tiles at `(0,0)`, `(1,7)`, `(12,1)` and `(12,8)`. Their rendered trees retain real forest movement/LOS rules.
- Geometry-only traversal verifies all walkable tiles connect to the crossing; this deliberately ignores occupied cells and zones of control, so it is not a promise every tile is immediately reachable during combat.

Friendly positions, ids 0–5: `(5,4)`, `(4,5)`, `(3,2)`, `(3,1)`, `(3,6)`, `(4,7)`.
Enemy positions, ids 6–11: `(7,4)`, `(8,3)`, `(8,5)`, `(9,6)`, `(10,3)`, `(10,6)`.
All spawns are unique and passable. Friendly sword id 0 starts one move from the bridge, enemy sword id 6 across it. Archer ids are **3 and 10**.

Equipment uses the unchanged `data/equipment.json` and `data/weapons.json`, `Battle.initialize_arms`/`sync_arms`, `Armor.part_weight`, and **`Armor.totals`**, not invented aggregate protection. The loadouts include sword, axe, spear, bow, greatsword, mace, heavy spear, hatchet, hammer, shortbow and polearm; heater, round, buckler and no-shield combinations; and layered mail/leather/brigandine/scale bodies with caps, nasal/kettle/bascinet helmets, visor, hood and felt-cap variants. Component and arm IDs are globally distinct.

Tests validate every physical piece with `Armor.valid_battle_parts`, assembled compatibility with `Armor.valid_loadout`, carried slots with `Arsenal.valid_arms`, all protection/load fields against exact component totals, and one ammunition-equipped two-handed archer per side. Different shield graphics must not invent extra defence: existing catalog values and `shield_defence` defaults govern their actual protection, durability and load.

## Actual rules, not presentation assumptions

| System | Existing implementation and boundary | Evidence |
|---|---|---|
| Hex geometry | `q/r` are **odd-row offset**, converted to axial/cube coordinates for distance, neighbors and line interpolation (`Battle.axial`, `offset`, `distance`, `neighbors`). They are not axial coordinates stored directly. | Existing `run.gd` exercises conversion and neighbor symmetry; scenario checks map and spawn coordinates. |
| Movement | Dijkstra-like budgeted paths through real tiles; occupied cells, water, walls, AP, fatigue and melee control constrain routes. Entering enemy control stops further route expansion; ordinary movement cannot leave engagement. | Actual bridge and slope moves; illegal moves preserve state/RNG; full-battle occupancy/resource invariants. |
| AP / climb | `step_cost`: 4 AP entering mud/forest, otherwise 2, plus positive destination-minus-origin height. **No hard maximum climb** and no extra downhill cost. Pathfinder has its existing separate cost behavior; none is assigned here. | Actual h0→h1 costs 3 AP/6 fatigue; deliberately modified audit fixture h0→h2 succeeds for 4 AP. |
| Hit elevation | Core `baseline_hit_breakdown`: any downhill advantage is **+10**; attacking uphill is **−10 per level**. Ordinary chance is clamped to 5–95%; automatic shield split is a separate action. | Tests compare raw flat, +1, +2 and −2 height breakdowns, avoiding cap ambiguity. |
| Height and melee control | Core adjacent enemy control and shield-wall support require a height gap ≤1. This does **not** impose a general maximum-height melee reach rule. | Test shows a two-level gap removes ZOC while ordinary adjacent melee range remains valid. |
| LOS | `line_block_reason` traces intermediate hexes. Forest/wall tiles and intervening living bodies block. An immediately adjacent friendly rank can be shot over; a farther ally or enemy blocks. | Positive/negative actual LOS fixtures. |
| **Unsupported height LOS** | LOS does **not** compare ray altitude, terrain height, character height or rendered mesh geometry. A bare h2 hill between equal-height endpoints does not block the shot. Walls block by terrain tag regardless of rendered height. | Explicit h2-intervening-tile test remains clear. No height-LOS claim is made. |
| **Unsupported hard cliffs** | Vertical-looking tile skirts are graphics, not a cliff traversal rule. Climb is an AP cost, not a hard refusal. The scenario uses explicit walls where it needs an impassable edge. | Actual two-level climb succeeds in the declared fixture. |
| Cover | No numeric cover percentage, partial-cover armour bonus, ballistic arc or 3D occluder query. Intermediate forest/walls are binary LOS blockers; the target's terrain itself is not sampled as intermediate cover. Shields/active Shieldwall are real defence mechanics, not terrain cover. | Changing target tile to forest changes neither LOS nor hit chance in an isolated fixture. |
| Damage | `Battle.pooled_hit` delegates arithmetic to `combat_damage.gd`; body protection is armour+padding resolved once, wear distributed to physical parts outside-in, with independent head protection. Existing penetration, damage rolls, head effects, shields and weapon/perk rules are retained. | Actual accepted attacks; HP/armour feedback reconciles to state deltas and component totals; baseline combat suite passes. |
| AI and turns | Side 1 uses existing coordinated roles, targeting, legal moves, paid attacks and `end_turn`; tests can drive both sides with `ai_step`. | First enemy phase, three paired complete battles, finite ammunition and round advancement. |

## Renderer and assets: static audit only

The original `src/main.gd` is a custom 2D draw/input/campaign shell: `_draw_board` paints terrain polygons and markers; `_draw_equipped_soldier` draws equipment from catalog layer definitions. Its apparent hill symbols are not 3D terrain. This prototype does not edit or reuse that campaign shell, including its `user://` save writer.

The new presentation owners are building a separate Node3D layer:

- `prototype/hex_layout.gd` maps the same odd-row board into pointy hexes in X/Z, with a **0.65** world-unit Y step per engine height. `from_world` cube-rounds the X/Z point; the renderer still needs correct surface picking when tiles overlap in the camera.
- `prototype/terrain.gd` reads `battle.tiles` to make hex-prism surfaces, lower water beds, water surfaces and a stone-arch presentation at `(6,4)`. Ground/stone/water material code is separate from gameplay. A visible rock, arch, wall height or material opacity cannot supply a combat rule.
- `prototype/character.gd` is a Sprite3D layered-illustration presentation. Its asset source is `prototype/character_assets/build_assets.py`: deterministic authored SVG masters rasterized with `rsvg-convert`, plus PNG companions. The final loader uses an imported Texture2D when its remap exists, otherwise PNG bytes via `Image.load_png_from_buffer`, with mipmaps; it does not require a preexisting editor cache. The source identifies the art as original temporary illustration, not downloaded game art.
- `prototype/materials/palette.gd` creates a small seeded procedural pigment texture; materials/shaders do not consume the battle RNG. The original font assets retain their DejaVu/Bitstream license in `assets/FONT-LICENSE.txt`.

Terrain and character files were under active parallel development during this audit. **This report does not certify completion of every equipment layer, final ruin mesh, camera pick path, visual fading, UI action, or animation.** The actual equipment/terrain dictionaries above are the binding contract; the owners' tests and the parent's native evidence must establish the final rendered result. No native screenshot or visual comparison was produced by this task.

## Executed scenario result

`prototype/tests/scenario_test.gd`: **550 checks, 0 failures** in the final integrated run, exit 0, with no script errors (initial audit: 546; four final forest assertions added). See `evidence/final-checks/summary.json`.

- Eight real seeded openings produced **3 hits and 5 misses**, with emitted feedback reconciled to real damage. No hit RNG override is used.
- Default seed 7391: move `(5,4)→(6,4)` costs **2 AP / 4 fatigue**; attack costs **4 AP / 12 fatigue**; 3 AP remain. Its first attack really **misses at 52%**, with one enemy shield condition lost. This is expected gameplay, not a forced tutorial hit.
- The resulting enemy phase performs actual moves/attacks and returns control at **round 2 after 15 AI steps**. Its two opening sword attacks also miss; their shield-impact feedback is real.
- Both archers successfully fire through the real action API. In every complete AI run both spend their **12 arrows**.

| Seed | AI steps | Final round | Real result | Hit events | Effective HP loss | Armour loss | Death events |
|---|---:|---:|---|---:|---:|---:|---:|
| 1 | 375 | 21 | victory | 40 | 473 | 1278 | 8 |
| 17 | 484 | 31 | draw | 46 | 520 | 1572 | 6 |
| 7391 | 393 | 22 | defeat | 43 | 570 | 1557 | 8 |

Each was paired with a second fresh instance using the same seed and reached an identical final snapshot. These are bounded smoke/consistency observations, not balance statistics or a claim every seed wins. Isolated LOS/elevation/archery fixtures explicitly remove unrelated bodies or relocate actors; the opening/AI/full-battle tests use the authored scenario without those fixture edits.

## Unchanged baseline suites: honest failures retained

The scripts and inherited test helpers were inspected for file/process hazards before execution. The selected paths instantiate rules/campaign objects and use in-memory snapshots; the integrated compatibility suite reads a fixture JSON. They do not load `main.tscn` or call its save writer. The scripts ran serially in **one private copied project**, separate from the shared project/import cache, each with its own isolated `HOME`, `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME`. All had a 180-second process bound. No save JSON was found in those isolated homes after the runs.

| Unchanged script | Checks | Failures | Exit | Scope/result |
|---|---:|---:|---:|---|
| `tests/run.gd` | 800 | 0 | 0 | Bounded with existing `--battles=20` option; 20 complete battles, 9 victories / 11 defeats. |
| `tests/combat_baseline.gd` | 141 | 0 | 0 | Full script; 12 current first contracts plus compatibility/map checks. |
| `tests/armor.gd` | 943 | **97** | 1 | Full script; current slot/repair/load expectations and old migration/continuation assertions fail. |
| `tests/weapons.gd` | 789 | **37** | 1 | Full script; refill pricing, exact loot counts and survivor equipment settlement assertions fail. |
| `tests/tactical_ai.gd` | 43 | **4** | 1 | Three prior-settlement/personal-record comparisons and one new-encounter save-AI assertion fail. |
| `tests/turns.gd` | 2821 | 0 | 0 | Full script; 24 campaign fights, paired map/objective and old-save continuations. |
| `tests/integrated_compat.gd` | 18 | 0 | 0 | Full script; exact historical compatibility checks. |
| `tests/unified_campaign.gd` | 35 | 0 | 0 | Full script; unified campaign state/midnight invariants. |

Total: **5,590 checks, 138 failures; five suites pass and three fail.** No timeout or parser failure was substituted for a completed test. These failures were observed in an isolated copy containing no prototype scripts and byte-identical protected source/data/tests. They are baseline compatibility/expectation failures, not fixed here and not represented as green. Root-cause adjudication of those older suites is outside this prototype's ownership.

## Reproduction

Use the supplied runtime:

```text
/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64
```

Run a fresh isolated project copy (and isolated HOME/XDG directories):

```text
<RUNTIME> --headless --single-threaded-scene --path <PRIVATE_PROJECT_COPY> --script res://prototype/tests/scenario_test.gd
<RUNTIME> --headless --single-threaded-scene --path <PRIVATE_PROJECT_COPY> --script res://tests/run.gd -- --battles=20
```

The per-script baseline `status.json` files retain exact commands, isolated homes, elapsed durations and exit codes. No import pass was needed for these rules-only test scripts; any later visual imports should remain serialized and private. Reset this prototype by calling `Scenario.create(seed)` again, not by restoring or writing a campaign save.
