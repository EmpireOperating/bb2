# Painted Crossing — executed verification

## Scope and result

This is a runnable, isolated **visual-quality slice**, not a finished reference-art reproduction. The actual Godot scene has materially richer painted characters, continuous textured terrain, a detailed bridge and a larger ruined keep than the prior vector/hex-column proof. It still has repetitive static poses, sparse/repeated environmental shapes, visibly stepped banks, limited equipment-art coverage and less compositional richness than the reference.

The simulation and earlier renderer are unchanged. No full-game conversion or merge has occurred.

## Automated execution

Authoritative current run: `/home/quatro/games/battle-brothers-2-visual-evidence/integrated-final/summary.json`.

Fresh source copy and HOME/XDG; Godot 4.4.1 headless, single-threaded scene:

- Cold import: exit 0, no engine errors.
- Unchanged prototype: layout 1,669; controller 14; view 763; scenario 550; character 327; terrain 310.
- New slice: authentic loadouts 93; view/HUD/camera 17; painted character layers 206; terrain geometry/contracts 32,743; full scene/input/turn integration 46.
- **36,738 Godot checks, zero failures.** Much of this count is individual geometry-vertex checks; it is not a measure of art quality.
- **11 Python lifecycle tests pass**, covering bounded exact-child cleanup.

The runner is `python3 visual_slice/run_checks.py --output /absolute/new-directory`. It includes the unchanged prototype gates and does not run or relabel known failing legacy suites.

## Real rendered gameplay

Final native run: `/home/quatro/omabox-trial/runs/default/34037af8b7e9/`.

- Canonical AO private Omabox; real Godot 4.4.1 Compatibility renderer, **Mesa llvmpipe software GL**, Wayland, Dummy audio.
- The exact native process PID/starttime/argv matched the observed window.
- **25 completed acceptance checkpoints; 12 actual window captures.** The finite driver used external mouse and keyboard input, with passive game-state observation.
- Verified all three authentic hero kits and restart semantics; selected hero and archer; moved onto the bridge with real AP consumption; selected an enemy; executed attacks; witnessed enemy actions and next-round return; continued until real armor/HP damage without an RNG override; zoomed, panned and reset; hid/restored HUD.
- Engine exit 0; private source inventory unchanged; final wrapper receipt completed.
- Canonical driver/report pass and cleanup verified. Parent independently checked exact runtime/private HOME/cgroup and recorded box processes were absent after completion.
- Full raw run retained externally and copied to `/home/quatro/games/battle-brothers-2-visual-evidence/native-final/`.
- The final mounted runtime/art files match this candidate byte-for-byte. README and character documentation were the only document-only differences at binding time. Receipt: `.../battle-brothers-2-visual-evidence/native-binding.json`.

The first 120-second admission expired before any GUI started because memory headroom was below the safety threshold. A bounded queued attempt later admitted normally. No guard was bypassed and no user application was closed. The first native art candidate also passed, but its ground was too uniformly golden; that evidence is retained at `/home/quatro/omabox-trial/runs/default/b31bab02b061/`. A separately staged, fully retested palette correction is the accepted native run above.

Selected full-frame captures are supplied alongside this report. Offline generated paintings and layer-comparison sheets are explicitly **not game screenshots**. Images were inspected by the parent, not merely checked for file existence. This is source-project Linux execution; it does not prove target-GPU FPS, audio, exports or other platforms.

## Geometry and real equipment

Terrain measured **79,019 triangles across 30 mesh instances/surfaces**, including the off-board background. Standing anchors match logical hex centers/heights; decorations do not mutate the battle tile map. Native stream, bridge, shadows, masonry and character layers render without shader/script errors.

Hero mail/nasal/sword/kite and brigandine/kettle/axe/round combinations are separate real equipment layers. The light kit removes helmet and shield. Wear/removal/unsupported diagnostics and opaque-pixel selection are exercised by real engine tests. The painted character tests include source-pixel face/torso/boot picking at multiple zooms; the native journey exercises ordinary visible-actor clicks. It is not an exhaustive native test of every pixel or catalog item.

## Preservation and inherited limits

- All **3,585 files** in the original-download manifest were rehashed unchanged.
- `src/`, `data/`, original `tests/`, original `assets/` and the entire earlier `prototype/` have no candidate diff.
- The earlier prototype worktree remains untouched.
- Existing baseline failures remain: armor 97, weapons 37, tactical AI 4 (**138 assertions**), plus the prior legacy UI journey failures/timeout. These were already established on the unchanged game. The native runner explicitly skips that legacy journey here rather than claiming a new pass.
- No height-aware LOS, maximum cliff climb, numeric partial cover, 3D ballistics, campaign saving or initiative conversion was introduced.

## Recommendation

**Keep the 3D-environment / painted-2D-character architecture for further graphical work, but do not begin a full-game conversion yet.** This slice establishes that actual equipment layers, movement, combat, camera control and richer terrain coexist in the running engine. The remaining gap is primarily asset direction and production: varied authored poses, complete weapon silhouettes, less repetitive ruin/foliage shapes, richer scene composition and restrained material detail. The reference remains a direction, not a quality level achieved by this pass.
