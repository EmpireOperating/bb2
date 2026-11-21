# Terrain successor implementation contract

Base: `5ad919b4f81126a24603e9375449c488b3549174`. Branch `spike/terrain-rules` only. Read BRIEF.md, the source audit and cited research in `/home/quatro/games/battle-brothers-2-terrain-rules-evidence/` before acting.

## Ownership

- Rules lane: `src/battle.gd`, new `src/terrain_rules.gd`, `terrain_pass/tests/rules_test.gd`, `terrain_pass/RULES.md` only. All Battle consumers/reactions/AI sharing those rules belong here. No campaign/damage module/catalog/legacy edits.
- Integration lane: new `terrain_pass/maps.gd`, `session.gd`, `main.gd`, `main.tscn`, `camp_panel.gd`, `battlefield.gd`, `tests/maps_test.gd`, `tests/session_test.gd`, `tests/ui_test.gd`, `INTEGRATION.md`; minimal virtual factory seams in `company_loop/main.gd` and `company_loop/battlefield.gd`; `project.godot`, new `launch-terrain-pass.sh`. Do not edit company character/compositor/gear or company session/camp panel. Parent owns runner/docs/packaging outside these files.
- Terrain lane: `terrain_pass/terrain.gd`, `materials/**`, `terrain_assets/**`, `tests/terrain_test.gd`, `TERRAIN.md`. Reuse accepted builders/textures; no modifications to predecessor renderers, scene environment or equipment.
- Parent: integration runner/receipts/native acceptance, final documentation/review/package/commit. No child GUI, staging or commit.

## Rule adoption and limits

Add `Battle.terrain_rules_enabled = false` (reset false by setup). Successor adapter explicitly enables it after real Campaign deployment; predecessor scenes/tests retain exact old mode. No second combat simulation. Public Battle APIs remain authoritative; one helper returns actual AP and fatigue, one attack-geometry reason path serves Boolean and explanation.

Research: `research/vanilla-terrain-rules.md` and `citation-evidence.md` are mandatory. Implement supported ordinary movement table, both-direction elevation surcharge, Pathfinder, ordinary one-level traversal cap (source-indicated, native descent caveat documented), ordinary melee/reach height cap1, conventional ranged cap4 and downhill range bonus, flat downhill+10/uphill-10 per level, height-aware ordinary ZOC excluding unable actors, and safe shared displacement geometry. Keep planar distance unchanged. Preserve actual costs of nonordinary movement abilities unless research explicitly supports changing them. Add the source-backed ordinary disengagement opportunity-attack behavior through normal move validation/execution, with paid failed attempts and no resource/RNG mutation for invalid commands. Do not charge path heuristic +4 as movement AP.

Terrain names used by maps: grass/hill=flat2AP4FAT; road/stone/ford=paved2/2; forest/mud/rough=rough3/6; rubble/rocks=4/8; swamp=4/14; sand=2/6; shallow_water=4/12. water/deep_water/wall and `blocked:true` are impassable. Unknown terrain must refuse in enabled mode, not silently be cheap. `forest` is floor, not automatically a tree. A tile may separately set `obstacle:"tree"|"wall"|"boulder"`, `blocked`, `vision_blocking`, `cover`. Map obstacles below deliberately use explicit hard blockers.

**Unresolved visibility/cover is NOT certified vanilla.** Initial candidate keeps the current intermediate-hex hard-blocking model but consults explicit vision blockers (forest floor alone is not one). Bodies retain the documented predecessor model until a separately reviewed coherent source closes the gap. No invented interpolated 3D eyes/ballistic rays, no claim that height LOS/75% cover/scatter are finished. Expose this limitation in RULES.md and player help. A parallel source follow-up may tighten this boundary; do not guess while awaiting it. Do not add swamp combat multipliers without source-linked tests; if omitted, document. No unrelated perk/damage rebalancing.

## Authored content interface

`terrain_pass/maps.gd` extends RefCounted, pure static API:
- `ids() -> Array` returns `["ruined_crossing","woodland_road"]`.
- `create(id:String) -> Dictionary` returns detached descriptor or `{}` for invalid.
- `validate(descriptor:Dictionary) -> String` returns empty on valid, human-readable reason otherwise.
- Descriptor: `{id:String,title:String,tiles:Dictionary,spawns:Array,presentation:Dictionary}`.
- Complete 13x9 `tiles` indexed `"q,r"`; each `{terrain:String,height:int,...}`. Heights0..2. Odd-row coordinates. `spawns` contains 12 unique legal Vector2i positions in tactical slot order (six friendly, six enemy), including vacant ranks. No equipment/initiative/content Battle object in registry.
- `presentation` required keys: `biome` (`crossing`/`woodland`), `road` (Array of tile-key Strings), `stream` (Array of Vector2i; may include offboard extension), `bridges` (Array of tile-key Strings), `keep` (Array of wall tile-key Strings). Empty stream/bridges/keep on Woodland Road. Ground road must correspond to actual road or ford tile costs. No hidden coordinate-dependent road/river in renderer.
- Wall/tree/boulder tiles carry explicit matching obstacle and `blocked:true`, `vision_blocking:true`. Ordinary forest floor carries neither. Tall scenery only on explicit blocked tiles or outside board; low dressing does not add rules. Decorative low rubble must not masquerade as a tall obstacle.
- Crossing retains recognizable bridge(6,4), river and ruined keep, broad plateau ramps, coherent ruin footprint. Woodland contrasts with cool green/brown wooded margins, quiet winding road, raised flank and multiple passable approaches; no crossing river/bridge/keep, no stock expanded-roster ambush flag. Deployment has a practical approach to combat, not unreachable shooters.
- Store locked deployed descriptor using `battle.set_meta("authored_map", descriptor.duplicate(true))`. Renderer `build(battle)` reads that metadata. `terrain_rules_enabled` true for deployed successor battle. Descriptor must be validated before live campaign mutation. Preserve job/world ford economy; map art is not world-site migration.

## Session/UI boundaries

- Reuse actual Campaign setup/deploy/settlement/retreat and accepted company actor. Do not grant/heal/reset when choosing map or returning. Fix initial active unit position-derived origin after authored spawn installation without restarting initiative or resetting all activation resources.
- New session extends company session. `selected_map_id`, `select_map(id)->bool` camp-only; `deployed_map` locked descriptor through battle/aftermath. Expose errors. Initial selection crossing; map preference may intentionally remain transient across restart (document; avoid unnecessary save schema).
- Separate successor userdir **`ashen-company-terrain-rules`**, checkpoint `user://terrain-camp.json`. No live prior company save import. Preserve strict CAMP-only validated payload and atomic save path behavior. New session path guard must require successor origin. Private tests can set ProjectSettings before creating nodes.
- Prefer small overridable factories in parent app/field rather than copied app/controller. Old defaults stay old. New app/scene select successor session/panel/field. New field uses `terrain_pass/terrain.gd` and SAME `company_loop/character.gd`.
- Map choice may use a compact camp-owned chooser/dialog; no overlap with inventory at640x480. Changing map never deploys. Explicit deploy remains a distinct action. Modal must block background equip/deploy/field input.
- Passive observation includes selected/deployed map IDs/title, map-choice button rectangles/centers and modal state if used, tile obstacle fields and profile, actual costs/attack reasons for native automation. No hidden QA action dispatcher.

## Terrain architecture and appearance

One descriptor-driven reusable renderer (subclass accepted terrain for reusable bridge/ruin helpers only if their hardcoded assumptions are overridden). Exact shared Layout.world centers and heights. Continuous tops, exposed cliffs only, organic strata/soft silhouettes; clear climbable routes. Calmer large grass/earth groups and deliberately placed detail, recognizable road/gravel, darker damp banks. Keep original Filmic exposure/white/camera lighting unchanged; color improvement belongs in terrain materials.

Expose `world_anchors`, `tile_surfaces`, `ground_batches`, `geometry_stats`, inherited `occluders/faded_occluders`. Preserve world-feet fading/restoration/rebuild. Budget whole geometry including backdrop: aim <=80,000 triangles, <=80 surfaces; justify actual measured numbers if needed, never exclude hidden/backdrop geometry from counts. Deterministic decorative randomness must not consume game/global RNG. Native screenshots decide art quality, not test counts.

## Test-first / acceptance

Vertical RED→GREEN behavior slices; preserve raw failures. Real Godot4.4.1 in private copies/HOME/XDG. Log fixture vs production honestly. Runtime `/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64`.

Rules: exact AP/FAT path/preview/command agreement; invalid commands preserve state+RNG; height/reach both sides/parities; reactions/displacements/AI; legacy mode regressions unchanged. Test AP/FAT route tradeoffs if relevant rather than claiming general shortest-path correctness without it.
Maps/lifecycle: complete descriptors, unknown/malformed refusal before mutation, connectivity using actual enabled edge rules, real movement/attack/enemy actions and bounded complete fight on BOTH maps; repeated map changes preserve company/items; settlement once; first-origin consistency; private cold camp reload. UI real routed input down to640x480.
Terrain: mesh vertices/top heights/bridge opening/obstacle footprints/rebuild/fade/RNG and source hashes; both descriptors through same production build path. Temporary fixture descriptor only while registry missing, then production integration.
Completion markers: `TERRAIN_RULES_TEST`, `TERRAIN_MAPS_TEST`, `TERRAIN_SESSION_TEST`, `TERRAIN_UI_TEST`, `TERRAIN_RENDER_TEST` followed by `: N checks, 0 failures`.

All child evidence under `/home/quatro/games/battle-brothers-2-terrain-rules-evidence/<lane>/`. Parent verifies exact files and runs private native/cold aggregate before delivery. No broad old-test rewriting or asset churn.
