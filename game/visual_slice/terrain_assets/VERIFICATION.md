# Painted terrain slice — headless evidence

The terrain source is `visual_slice/terrain.gd`, inheriting only the existing mesh/occlusion helper owner. No original source, prototype terrain, scenario or combat rules were modified.

## Contract and integration

- `build(battle)` reads authoritative tiles only. The same 117 logical cells, 0.65 height step, sole `(6,4)` ford, eight walls and four forests remain authoritative.
- `tile_surfaces[key]` is now a **Node3D standing anchor**, not a separate drawable hex column. `world_anchors[key]` stores the shared Layout coordinate (terrain-local world layout); use the anchor's `global_position` if transforming the terrain root. `ground_batches` holds the single drawn ground-top mesh.
- `update_occlusion(camera, world_feet)` reuses the conservative existing body-sample OBB checks. Only actual wall/forest objects fade. `geometry_stats` measures submitted mesh instances/surfaces/triangles after each build.
- Actual supplied `earth.png`, `meadow.png`, `paving.png`, `rock.png` textures are bound. They are not regenerated procedural replacement art. Ground blends world-space samples, with no tile-color variation or painted hex borders. Masonry uses triplanar painted rock.
- Nonplayable landscape and stream extend beyond the board as real mesh geometry, without adding tiles or collision. Only genuine height differences receive faces. Layered rocks, low plants and irregular leaf-card trees remain decorative.
- Bridge paver tops are exactly y=0; arch voussoirs leave an actual opening above water. Keep walls/window arches occupy actual `(8,2)`/`(9,2)` wall footprints. Wood door/banner geometry adds no new walkable blockers.

## Executed checks

Runtime: local Godot **4.4.1 stable**. Commands ran in `/home/quatro/.hermes/cache/scratch/painted-terrain-proof/project`, with isolated HOME and XDG directories. No GUI was launched by this worker.

- RED/GREEN ground, bridge, keep and landscape attempts are retained in `evidence/01` through `evidence/10` logs. Budget failures are preserved, not called passes.
- Headless editor import: exit 0; no ERROR, SCRIPT ERROR or Parse Error lines.
- Final painted terrain: **32,743 checks, 0 failures**, exit 0. Includes exact centers, actual radius-1 boundaries, no same-height skirts, texture bindings, real bridge/window openings, wall footprints, conservative fades, rule/RNG immutability, rebuild determinism and geometry budget.
- Existing scenario: **550 checks, 0 failures**, exit 0; actual bridge move, attack/AI and complete seeded battles exercised by the inherited suite.
- Existing prototype terrain: **310 checks, 0 failures**, exit 0.
- Final measured terrain: **79,019 triangles, 30 MeshInstance3D instances, 30 mesh surfaces**, including landscape beyond the board. Standing anchors add no mesh submissions.
- `git diff --exit-code 3c5c436 -- src data tests prototype` was clean. Parent-owned project/scene/character/launcher work is outside this worker's scope.

## Limitations

This is **not visual acceptance**. Headless import and dummy-renderer tests do not establish native Compatibility/OpenGL shader output, llvmpipe FPS, screenshot quality or final reference fidelity. The parent owns native rendered review and playable integration. Geometry is close to the explicit 80k terrain triangle ceiling. Water uses moving opaque painted/procedural flow and foam, not reflections/refraction. Leaf cards have geometric silhouettes and painted meadow shading, not a production foliage atlas. Ground remains an authoritative stepped tactical height field; rocks soften but do not replace those real height boundaries. No campaign/save integration or new movement/LOS rules were introduced.
