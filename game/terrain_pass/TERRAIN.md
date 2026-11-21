# Descriptor-driven terrain candidate

## Delivered scope

One `terrain_pass/terrain.gd` builds **Ruined Crossing and Woodland Road** from the locked `battle.get_meta("authored_map")` descriptor. It reads actual `battle.tiles` for rule heights and obstacles; deployment must validate and keep those tiles equal to the descriptor. Missing metadata clears the old scene and exposes `build_error`, rather than silently creating a crossing.

No predecessor renderer, mesh helper, painted PNG, company character, equipment art, camera, lighting, exposure, Filmic or sprite color shader was edited by this lane. The new class inherits only reusable helpers: exact odd-row Layout, mesh emission/counting, masonry bridge construction and existing opaque/stipple occlusion. It overrides the coordinate-dependent construction path entirely.

### Composition

- Broad, low-contrast green/earth fields replace dense yellow-brown per-hex dressing. The original earth/meadow/paving paintings remain actual bound textures, deliberately subdued rather than replaced with flat placeholder assets.
- Road masks come from authored road/ford keys and adjacent road connections. The shared spatial mask fades at nonroad edges; the shader contains no fixed Z stripe. Shared top vertices have continuous forest/wet/gravel masks, avoiding colored-hex seams.
- Dark wet soil, sparse bank gravel and shallow crossing bars distinguish water approaches. Stream and bridge placement—including offboard continuation—use only the descriptor. Empty lists produce no water/bridge on Woodland Road. Shallow-water bars retain exact standing floors with a thin water patch above them; they are not submerged character animation.
- Actual height discontinuities receive wide, irregular, oriented rock strata. Equal-height neighbors have no internal skirts. Broad authored plateau/ramp heights remain exact; art does not change climb legality or invent slopes in the movement model.
- Keep walls follow adjacent explicit wall obstacles, with matching curtain arms, broken corners, foundations and fallen masonry. Nearby low rubble uses the actual rubble-tagged floor; no extra tall lane blockers.
- Woodland uses cool greens, branched canopies, forest litter and open understory. Every tall tree, wall and boulder is tied to an explicit blocked obstacle tile. Ordinary forest floor gets no invented tree. All tall obstacle mesh vertices fit their exact rule hex.

### Interfaces and fixed rendering domain

Exposes `world_anchors`, `tile_surfaces`, `ground_batches`, `cliff_edges`, `geometry_stats`, `water_surfaces`, `bridge_roots`, `occluders`, `faded_occluders`, `decorations`, `backdrop_bounds` and `build_error`. Bridge roots publish their tile through metadata. Anchors are terrain-local coordinates equal to `Layout.world(cell,height)`; the existing fade API accepts **world-space feet**, including transformed terrain roots.

All playable top centers/corners retain the original radius-one geometry and 0.65 height step. No game/global RNG is consumed. Rebuild frees the old generated root immediately, re-creates one root, and clears previous materials/fade references. Materials stay opaque: occluders use the unchanged `opacity`/discard path, with shadow restoration. There is no environment or sprite tone-domain compensation here.

## Real headless results

Godot **4.4.1.stable.official.49a5bc7b6**, private project copies and separate HOME/XDG state, `--headless --single-threaded-scene`:

The ground-shadow follow-up reran the terrain and UI suites only; predecessor rows below retain their earlier evidence.

| Gate | Actual final result |
|---|---|
| `terrain_pass/tests/terrain_test.gd` | **5,909 checks, 0 failures** |
| `terrain_pass/tests/ui_test.gd` | **92 checks, 0 failures** |
| Predecessor painted terrain | 32,743 checks, 0 failures |
| Original prototype terrain | 310 checks, 0 failures |
| Shared hex layout | 1,669 checks, 0 failures |

Terrain coverage includes actual top vertices/heights, material mask continuity, road-rule correspondence, shifted synthetic river/bridge/keep, actual arch opening, stream geometry confinement, explicit obstacle footprints, low dressing bounds, source seals, global/simulation state preservation, all-obstacle fade/restore under orthographic/perspective cameras and transformed roots, deterministic actual mesh arrays and different-map rebuild cleanup.

| Production map | Whole triangles | Surfaces | Mesh instances | First headless build |
|---|---:|---:|---:|---:|
| Ruined Crossing | 48,839 | 26 | 27 | 216.519 ms |
| Woodland Road | 42,987 | 31 | 32 | 181.822 ms |

These counts independently traverse **all generated geometry, including offboard landscape and empty batch instances**. Both satisfy 80,000 triangles / 80 surfaces. Timings are one headless CPU construction sample, **not FPS, GPU performance or an accepted native image**.

Fifteen pinned SHA-256 source seals preserve reused original terrain/helpers/textures and the camera/environment/sprite-color domain from `5ad919b4f81126a24603e9375449c488b3549174`. These are focused terrain dependencies, not a substitute for the parent's full protected-art manifest.

## Ground self-shadow correction

Following the parent's isolated GPU diagnosis, the only runtime correction is
`ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF` in
`_build_fields()`. Only `ContinuousFields` stops casting; it retains the exact
original lit field material and shadow reception. Exposed faces, broad outcrops
and unfaded tree/wall/boulder meshes retain casting. Global shadows, palettes,
geometry, material code/parameters and simulation are unchanged.

The test-first regression covers both production maps and the shifted fixture:
no continuous-ground caster, the sole original shadow-receiving material,
unchanged field-shader bytes, cliff/scenery casters, plus existing fade/restore
checks. Real Godot RED was **5,909 checks, 3 failures**, all and only the new
ground-caster assertion. After the single-line fix, terrain was **5,909/0** and UI
**92/0**, with exit 0 and no error/warning diagnostics. Cold import was also clean.
Every process used a private project and a separate private HOME/XDG state;
no GUI or source-project import was performed.

Exact raw logs, commands, engine/source/log SHA-256 receipts, original owned-file
snapshots and final diffs are under
`/home/quatro/games/battle-brothers-2-terrain-rules-evidence/ground-shadow-fix/`.
The field shader remains SHA-256
`10c12789b58e9309196f0aab62696a864c927e13722688a95711f24beeaf75e1`.
The initial copy-inventory assertion included the worktree `.git` pointer while
the copy correctly excluded it; the failed setup receipt is retained, and
`copy-qualification.json` proves that this metadata-only omission was the sole
difference, with all project/source/asset hashes equal.

These are headless rendering-state and UI regressions, **not an art-quality or
new GPU-image acceptance claim**. Native final-image acceptance remains the
parent's responsibility. No staging or commit was performed by this follow-up.

## Evidence and qualification limits

Raw RED/GREEN logs, commands and receipts: `/home/quatro/games/battle-brothers-2-terrain-rules-evidence/terrain/`. First RED was the absent renderer. The production registry arrived before the first geometry build, so subsequent primary builds use both production descriptors; a clearly marked shifted fixture remains supplemental. The first ground attempt exposed shallow-water handling and failed; the retained file name does not turn that attempt into a pass. Later REDs caught absent roads/water/obstacles/strata and visible per-cell material seams.

The cold import attempt `14-cold-import.log` **is not clean acceptance**: the asynchronous integration lane's `terrain_pass/main.tscn` was absent from that snapshot, although Godot returned exit 0. All four final explicit script suites subsequently completed without errors/warnings from that private copy. Parent must rerun a complete cold import after integration finishes.

**Native visual review remains pending.** No GUI was launched, no art acceptance is claimed, and no source was staged or committed. Parent owns actual map-choice/deployment, camera/picking/occlusion screenshots, full gameplay/regression acceptance, final review and packaging. In particular, inspect the cooler field palette, ruin silhouette, shallow-water bars and finite descriptor-defined offboard stream endpoints in the unchanged Compatibility lighting before accepting the art. Rendering occlusion is not gameplay LOS or a claim of vanilla cover parity.

## Owned files

- `terrain_pass/terrain.gd`
- `terrain_pass/materials/fields.gdshader`
- `terrain_pass/terrain_assets/field_mesh.gd`
- `terrain_pass/terrain_assets/strata_mesh.gd`
- `terrain_pass/tests/terrain_test.gd`
- `terrain_pass/TERRAIN.md`

To rerun, use a complete **private copy** of the project with private HOME/XDG state, then execute the exact engine with `--headless --single-threaded-scene --path <private-project> --script res://terrain_pass/tests/terrain_test.gd`. Do not import the user's live worktree to obtain test evidence.
