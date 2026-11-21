# Grassland visual refinement — verification

## Verdict and scope

**PASS as an additive cosmetic refinement of the isolated Procedural Woodland candidate.** Low, curved/fanned grass clumps are now visible at normal tactical zoom. Native pixels, ordinary inputs/cold restore, the complete current headless cohort and independent source review pass on the same runtime bytes.

Same launcher: `/home/quatro/games/battle-brothers-2-procedural-woodland/launch-procedural-woodland.sh`.

Evidence root: `/home/quatro/games/battle-brothers-2-grassland-evidence/` (paths below are relative to it).

- Tested/reviewed/native source: `freeze-candidate-01/project`,2284 entries.
- Exact source-manifest SHA256: `2130f642c287125b4cf4b570ecad64080563335128a53129575741c040ca230d`.
- Runtime: Godot4.4.1, SHA256 `54215149d52efb1d653a3dec39d0993587bdf5daa2c56e787b5ee88417fb1339`.
- Later root README clarification and this document are inert delivery-only differences, not untested runtime edits. The delivery acceptance records their exact classification.

## What changed

One added `_create_battlefield()` override in `procedural_woodland/main.gd` selects thin grassland battlefield/terrain subclasses. The terrain calls the accepted landscape builder first, then appends a single `GrasslandTufts` batched mesh/material. Seven differently fanned, curved/tapered opaque blades form each tuft. Descriptor-local hash samples and FastNoiseLite create irregular patches, variable heights/rotation and gaps, in muted green/olive/straw colors.

Generated seeds73/74 produce2075/2019 clumps, about2.29/2.23 per eligible hex, adding43575/42399 triangles. All maps share a hard cap2857 clumps/59997 added triangles. Actual tested tips reach about.442 world units above the floor. This is a static tuft layer—not tall dense grass, wind, a new biome, cover or concealment mechanics.

Road paint is checked across the full fan footprint, not only by the host tile tag. Water/bridges/blocked tiles are excluded; standing-centre and exposed-cliff clearances are retained. The inherited lit opaque painted material is automatically bound to the normal world-XZ fog texture before rendering. Grass shadows are off. No per-clump nodes, collisions, occluders or new public observer fields are introduced.

## Preserved boundaries

The accepted2280-file recipe delivery remains immutable at `/home/quatro/games/battle-brothers-2-procedural-woodland-evidence/freeze-delivery/`.

At the runtime freeze,2279 original files remain byte-identical; only the one main factory override changes. Four new files provide the subclass adapters, tuft mesh and regression test. No generator, scene/project configuration, session, checkpoint namespace/origin/format, combat/initiative/RNG, visibility rules, existing terrain geometry/materials/assets, character art, camera/light or14 old procedural tests changed. No original/live-game path or real user save was a write target. Current camp saves remain compatible because the company/selection authority is unchanged.

## Executed gates

- **Vertical RED/GREEN:** actual production-scene missing-grass RED16 checks/4 failures; density RED146/2; final new suite154/0. No missing-preload/parser failure was counted as RED. Receipts and source pins: `implementation/HANDOFF.md`, `implementation/source-pins.json` and retained `runs/grassland-*` directories.
- **Complete current cohort:** private IMPORT +36 suites,40491 checks, zero failures/errors/warnings/timeouts; every child exit0/reaped, no source drift. `runs/final-candidate-01/receipt.json`, full source inventory and every raw-log SHA were reconciled; summary `final-headless-summary.json`. Separate-process cold reader immediately follows writer.
- **New real-engine coverage:** actual production factories for generated73/74 and fixed Crossing/Woodland; mesh/color/height/density/cap checks, actual vertex road/standing/cliff clearance, exact inherited ground/exposed-face arrays, parent-measured complete geometry, normal fog texture/shader binding and all three knowledge states, deterministic rebuild/cleanup, no refresh rebuild, unchanged full Campaign/Battle/tiles/descriptor and global/combat RNG. Synthetic hidden-occupancy/visibility fixtures are labeled as such, not native input evidence.
- **Independent review:** `review/REPORT.md` and `review/verdict.json` PASS on the exact2284-entry pin, no blockers. Independently executed private IMPORT and286 focused checks clean/reaped; audited—not reran—the complete40491-check cohort and hashes. Two reviewer-parser setup errors remain retained, with no candidate edits or engine failures. Source/geometry/fog integration review does not itself claim pixel acceptance.

## Native input, pixels and cold save

Actual canonical private run: `/home/quatro/omabox-trial/runs/default/b427eaa8af88/`. Unchanged reviewed helper uses the real successor launcher, ordinary external clicks/keys, a read-only frozen stage and private writable HOME. **46 checks, zero failures.** Both exact engine lifetimes exit0/reaped with source intact; final task status passed/driver_success true, canonical cleanup verified and private runtime/HOME absent.

The workflow selects generated73 without rerolling/deploying, deploys, pays for scouting out/back with terrain discovery/refog, withdraws/returns, selects/deploys74, switches fixed/generated choices and performs a distinct-process cold camp restore. The actual complete checkpoint is byte-identical to the pre-grass native acceptance checkpoint (`f22f4c8699eb448fd6bd78874f4b5cbdda39fb2373a6698adbb5aaf4e5ada703`), as are the observed owned-company/resource state and generation metadata at cold restore.

Parent inspected actual seed73/74 close views and remembered overview: tufts visibly break up the formerly plain ground; roads, blue hex outlines, actor feet and unknown black terrain remain readable, without conspicuous hovering or material faults. Individual tufts are too small in full-board overview to judge fine detail. Parent readback: `native/candidate-01/parent-verification.json`.

`native/candidate-01/grassland-before-after.png` uses unretouched same-seed74 native image crops with separately drawn labels. Raw full-window sources are retained. A small-label first comparison was retained separately and replaced with a readable ASCII-label composition; no game image pixels were synthesized.

Rendering was software Mesa llvmpipe Compatibility, audio Dummy. These checks do not establish target-GPU FPS/audio, another OS, universal seed performance, native battle victory/casualty, human balance or visual preference. There is no live merge, commit, public publication or full overworld integration in this pass.
