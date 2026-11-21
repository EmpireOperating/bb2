# Authored terrain session / UI integration

## Runtime and ownership

Primary: `./launch-terrain-pass.sh -- --observe`, or the default `project.godot` scene `res://terrain_pass/main.tscn`. The launcher delegates to the existing Godot launcher; the scene subclasses the accepted company application. Run launchers/tests only from a private project copy with private HOME/XDG state when verifying.

Successor checkpoint: **`user://terrain-camp.json`** under custom user directory **`ashen-company-terrain-rules`**. No previous company checkpoint is imported. A fresh installation uses the inherited one-time company setup; map changes, equipment changes, deployment and camp return do not rerun it.

The explicit old company launcher in this successor checkout is **not** a successor checkpoint route: the unchanged predecessor session refuses the new project origin. Do not weaken that guard. The accepted older worktree remains independent and functional; predecessor regression tests must select the old userdir only in their private test-copy project settings.

Only the following predecessor runtime seams changed:
- `company_loop/main.gd`: overridable `_create_session()`, `_create_camp_panel()`, `_create_battlefield()`. Defaults still return the predecessor scripts.
- `company_loop/battlefield.gd`: overridable `_create_terrain()`, still returning the old painted terrain by default.
- Successor project name, userdir and main scene.

No application/controller clone. No changes to company session, camp panel, Character, compositor, accepted equipment/art, campaign, economy or damage authority.

## Map API

`terrain_pass/maps.gd` is a pure RefCounted registry:
- `ids() -> Array`: `ruined_crossing`, `woodland_road`.
- `create(id: String) -> Dictionary`: detached descriptor, or `{}` for unknown IDs.
- `validate(descriptor: Dictionary) -> String`: empty when valid; descriptive refusal otherwise; never mutates its input.

Each descriptor contains exactly `id`, `title`, `tiles`, `spawns`, `presentation`. Tiles are a complete 13×9 odd-row board, integer heights 0..2; twelve unique legal Vector2i spawn slots cover six company and six enemy ranks, including vacant slots. `presentation` has matching biome, road keys, stream Vector2i cells, bridge keys and keep wall keys. Road/ford, all water cells and all keep walls are cross-checked against the actual board. Trees, boulders and walls require matching floor tags plus explicit physical/vision blocking; ordinary forest floor is not a tree. Low rubble remains passable. All traversable cells must connect through one-level approaches; the session test independently walks the actual enabled Battle edges.

Ruined Crossing preserves bridge `6,4`, river, two additional shallow crossings, readable ramped plateaus and a coherent keep footprint. Woodland Road has a winding paved road, wooded margins, raised flank and multiple approaches, with no stream/bridge/keep. It does not enable the stock expanded-roster ambush flag.

## Session authority and failure boundary

`terrain_pass/session.gd` extends the unchanged company session:
- `selected_map_id`: initially `ruined_crossing`; map preference intentionally remains transient across a new session/cold launch.
- `select_map(id) -> bool`: camp-only; validates before changing preference, does not deploy or grant/reset anything. Failures set inherited `last_error`.
- `deployed_map`: detached public readback of the descriptor locked through battle/aftermath.
- `start_battle() -> bool`: first validates the descriptor, then restores a detached, stock-validated current Campaign snapshot, creates the same real-ford job/economic context, and calls actual `Campaign.deploy()`. A fully installed candidate is published only after success. Rejected descriptors or invalid company ownership leave the existing Campaign object, contents and deployed descriptor untouched. Successful deployment publishes a new Campaign object carrying the same owned company and physical item identities; callers should read `session.campaign`, not retain a predeployment object reference.
- Only tiles and tactical q/r plus stable visual/company IDs are installed after stock deployment. Only the first active unit's `perk_state.origin_q/origin_r` are reconciled. No `reset_segment`, `start_round`, activation-resource or other transient resets occur.
- After real deployment, sets `battle.terrain_rules_enabled = true` and `battle.set_meta("authored_map", descriptor.duplicate(true))`.
- Actual inherited Campaign settlement/retreat/return remain authoritative for wear, deaths, lost gear, loot and ammunition refill. The map is not a world-site migration.
- `_checkpoint_path` requires both successor settings and actual successor user-directory basename, preserves full-string filename validation and refuses links/directories. Inherited canonical, digested, stock-validated CAMP-only atomic save/load stays unchanged; no battle/aftermath checkpoint saving. Saves emit no `changed` signal.

## UI and passive native targets

The camp panel subclasses the accepted outfitting panel and keeps its exact Character preview and owned inventory. The header map button opens a centered modal with two map choices and Back. It fits 640×480, 960×600 and 1440×900. Pointer input is blocked behind it; equipment/deploy actions are disabled; Tab/Shift-Tab stay within the modal; Escape cancels. Choosing a map only closes the chooser and changes the next deployment. Deploy is a separate existing action. Validation errors are exposed in the camp reason label.

The successor battlefield uses the same company Character, inherited controller, camera/environment and combat UI. It overrides terrain construction, rule-driven hover/blocker styling, map/help labels and passive observations only. Hover shows the authoritative movement-map AP/fatigue cost or Battle refusal reason; rejected attacks show the actual Battle reason.

`--observe` keeps the inherited passive file **`user://company-observation.json`** within the successor userdir. It is not an action endpoint.

Important fields:
- Top-level `selected_map_id`, `deployed_map_id`, `map_title`, `terrain_pass`.
- `camp.actions.map_chooser`: `{center, rect, clipped_rect, visible, disabled, text, reason}`; `camp.buttons.map_chooser` is its center.
- `camp.map_chooser_open`; `camp.map_choices.ruined_crossing` / `.woodland_road` use the same target shape; `camp.map_close` is Back's target. IDs are stable, coordinates are actual viewport/canvas-transformed observations, not guessed screen pixels.
- Existing `camp.targets.roster`, `.slots`, `.items`, and `camp.actions.equip/remove/deploy` remain available.
- In battle: `terrain_rules_enabled`, `terrain_profile`, `tile_profiles` (terrain, height, obstacle, blocked, vision_blocking, cover and ordinary base-cost profile), `movement_options` (actual reachable AP/fatigue and `[q,r]` path), `attack_reasons` by enemy tactical ID, `terrain_geometry`.
- `units` retains real AP/HP/positions/screens and adds actual `fatigue`, `fatigue_max`, `company_id`, `activation_origin`; inherited initiative and accepted-actor layer diagnostics remain present.
- Existing `buttons.retreat`, `buttons.confirm_retreat`, `buttons.cancel_retreat`, and aftermath `buttons.return_to_camp` are ordinary routed controls.

## Tests and commands

Use the exact Godot 4.4.1 runtime with `--headless --single-threaded-scene --path PRIVATE_PROJECT --script ...`. Private HOME/XDG directories are mandatory; do not import or run tests against accepted/live worktrees.

Scripts owned here:
```
res://terrain_pass/tests/maps_test.gd
res://terrain_pass/tests/session_test.gd
res://terrain_pass/tests/ui_test.gd
```
After the session suite, in a **new process using the same private HOME**, run:
```
Godot --headless --single-threaded-scene --path PRIVATE_PROJECT \
  --script res://terrain_pass/tests/session_test.gd -- --cold-load
```

The session suite writes exact oracles for both completed map fights and a distinct postcasualty retreat trial. The cold reader checks full-fight camps (including total defeat), rejects resurrection/redeployment of a wiped company, and deploys/retreats the living postcasualty company without setup. UI tests instantiate the packaged production scene and route real Window mouse/key input through map choice, owned equip, both production map deployments, confirmation, settlement and return. No renderer/rules/gear doubles or hidden action dispatcher were used.

Raw RED/GREEN logs and command receipts are external under `/home/quatro/games/battle-brothers-2-terrain-rules-evidence/integration/`. Early failed fixture/parse attempts are retained separately. The initial full-fight assertions assumed both sequential battles would leave survivors; production ordinary-disengagement adoption changed the real second outcome to defeat. Tests now preserve that legitimate complete defeat and separately prove the living postcasualty cold-deployment path, rather than repairing fighters or forcing a result. The centered modal initially retained an offscreen minimum-size-derived position at 640×480; a real routed failure was fixed with a centering container.

Latest child production run: maps **98 checks / 0 failures**; session **390 / 0**; separate-process cold reader **10 / 0**; routed UI **92 / 0**. The same unreset company completed Ruined Crossing as victory (137 steps, round 8), then Woodland Road as defeat (92 steps, round 8). The independent Woodland retreat trial reached one actual casualty after 76 steps before ordinary retreat. Both production terrain descriptors built through the real scene/renderer in routed UI tests. The private primary launcher imported and started successfully; its passive readback reported saved CAMP, the successor checkpoint origin, and Ruined Crossing as the intentionally transient default choice. These are headless execution results, not visual acceptance.

Parent owns `terrain_pass/run_checks.py`, aggregate/frozen-source acceptance, native GUI runs, release packaging and commit. Child execution was headless only; no GUI, staging or commit.

## Explicit limits

- Ordinary movement/elevation/attack adoption is opt-in. The unchanged precursor factories and rules mode remain separate.
- Visibility still uses intermediate-hex hard blockers plus the inherited body model. Height-aware LOS, probabilistic partial cover/interception/scatter and exact vanilla visibility parity are **not certified**. No swamp combat multipliers were added. The field guide explicitly discloses this.
- Tactical scenes are not saved: quitting during battle restores the last camp checkpoint, not the live fight. Map preference is transient; prior owned equipment/conditions/casualties are not.
- Real headless victories/defeats and routed UI tests do not establish native terrain beauty, GPU rendering, human wayfinding, fun or balance. Native visual acceptance, actual opaque picking/fading and screenshots remain with the parent.
