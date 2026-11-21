# Ruined Crossing — final verification and verdict

## Verdict: playable architecture VALIDATED; visual target PARTIAL

The actual Godot 4.4.1 scene combines the existing combat simulation with a separate 3D battlefield and equipment-driven 2D characters. Native mouse/keyboard play exercised selection, movement, targeting, paid attacks, real damage, enemy responses, round progression and camera controls. It is a playable rendering proof, not a static illustration.

The reference's dense hand-painted ruins, intricate terrain and finished characters are **not matched yet**. The delivered scene is a simpler, visibly hex-built miniature with temporary vector-authored characters. Treat it as an architectural foundation candidate, not finished game art.

## Reproducible evidence

- Six final prototype suites: **3,633 checks, zero failures**, all exit 0: layout 1,669; controller 14; view 763; scenario 550; character 327; terrain 310. See [corrected-checks/summary.json](evidence/corrected-checks/summary.json) and adjacent complete logs. The QA lifecycle suite adds **11 Python tests, all passing**, with real child-process timeout, interruption, escalation and reaping checks; see [review-fix1/summary.json](evidence/review-fix1/summary.json). Earlier 3,001-check evidence is retained separately.
- Final corrected native prototype: **30 acceptance checkpoints and eight actual engine screenshots**. See [acceptance.json](evidence/native-corrected/acceptance.json). Real input clicked all six mercenaries at their heads at default and zoomed scales, selected both archer and swordsman, crossed the bridge, selected an enemy, attacked, advanced enemy turns, continued until actual armor damage, zoomed, panned and reset the camera. No hit RNG override was used; the opening attack legitimately misses.
- The native prototype process exited **0**; its receipt records exact PID/starttime/argv and unchanged staged source. The canonical private desktop task records driver exit 0 and verified cleanup. Native rendering used **Compatibility / Mesa llvmpipe**, so this does not qualify target-GPU frame rate or audio. The prototype log has no Godot ERROR/WARNING; optional speech-dispatcher library absence is recorded.
- Both shell launchers were separately exercised with real import and bounded headless startup: exit 0, no errors or warnings. See [launcher/summary.json](evidence/launcher/summary.json).
- The independent preserved 2D scene native smoke completed **`UI_SMOKE_OK result=victory rounds=4 commands=43`**, exit 0. See [runtime.log](evidence/original-smoke/engine/runtime.log). Its retained `original-2d-battle.png` was captured too early and shows the Godot splash: **rejected as gameplay screenshot evidence**, regardless of its filename or capture-exists flag.
- Original downloaded folder: **3,585 files checked, zero changed**. Protected copied `src/`, `data/`, `tests/` and font assets: **1,068 files checked, zero changed**. See [integrity.json](evidence/integrity.json). The original project/save folder was not used as a runtime working directory.

Final corrected canonical native run: `/home/quatro/omabox-trial/runs/default/9ce7c2c5c1d3/report.json`; this prototype-only QA helper completed normally with the legacy journey explicitly skipped. Earlier native evidence, including the inherited UI timeout, remains under `evidence/native-final`. Independent original smoke: `/home/quatro/omabox-trial/runs/default/262135338663/report.json`. Portable copies of reports/logs/screenshots are included here; embedded absolute paths describe the actual test machine, not required install locations.

### Failures retained, not called green

The unchanged, no-prototype baseline completed eight suites: **5,590 checks, 138 failures**. Five suites passed. `armor.gd` failed 97 assertions, `weapons.gd` 37 and `tactical_ai.gd` 4. See [baseline-tests/summary.json](evidence/baseline-tests/summary.json) and [SYSTEMS-AUDIT.md](SYSTEMS-AUDIT.md). No legacy source or expectations were changed to manufacture a pass.

In the earlier native run, after its successful prototype phase, the combined QA helper attempted the inherited full `tests/iron_ui.gd` journey. It logged **43 failed assertions** and reached its **240-second timeout**. Consequently `acceptance.json` truthfully records `legacy.uncompleted=true` and `runner_completed=false`; there is no whole-helper success claim. See [legacy-native.log](evidence/native-final/engine/legacy-native.log) and [runner-error.json](evidence/native-final/engine/runner-error.json). That broader UI regression journey remains **unvalidated**, and its cause was not established. The independent original-scene smoke is narrower evidence, not a replacement claim that every original UI workflow passed.

## Review corrections

Independent review found two real defects before delivery: a world-up hit rectangle could miss camera-facing helmets, and a native QA timeout could leave its child alive until desktop teardown. The final picker ray-tests the actual rendered Sprite3D planes and opaque pixels, using current tweened positions and nearest visible depth. The QA helper terminates, escalates when needed, and reaps its exact child while preserving the original failure. Regression tests were observed failing before the repairs and passing afterward; the original picker restored privately fails 112 of the final 763 view checks. Native head clicks then passed at two zoom levels. These were corrected, not waived.

## Actual screenshots

These are Godot frame captures, not generated concept art or the optional offline equipment sheet:

- [Opening battlefield](evidence/native-corrected/01-opening.png)
- [Head-click selection at zoom](evidence/native-corrected/01b-head-picking-zoom.png)
- [Movement onto the bridge](evidence/native-corrected/02-crossing-move.png)
- [Attack feedback](evidence/native-corrected/03-attack.png)
- [Enemy response](evidence/native-corrected/04-enemy-response.png)
- [Real armor damage](evidence/native-corrected/04b-armor-damage.png)
- [Zoomed camera](evidence/native-corrected/05-camera-close.png)
- [Controls](evidence/native-corrected/06-controls.png)

## Reused versus new

**Reused unchanged:** Battle state, odd-row hex topology, movement/path budget, AP/fatigue, zones of control, terrain tags/heights, LOS rules, hit chances, armor and HP damage, weapon/shield behavior, equipment catalogs/helpers, morale/routing, side turns and enemy AI. Existing campaign and 2D rendering code remains present and unchanged.

**New and isolated:** an authored six-versus-six ruined-crossing starting state; hex-to-world layout; reusable prism/ruin/bridge/tree meshes and procedural materials; animated water/foliage; orthographic presentation; camera-facing character layers; command adapter; HUD, highlights, picking, movement interpolation and occlusion fading. All tall scenery corresponds to actual wall/forest tiles. Decorative debris does not introduce blockers. Equipment artwork is **45 original SVG masters plus transparent PNG companions** driven by actual equipment fields, not cosmetic overrides. See [ASSET-SPEC.md](ASSET-SPEC.md).

## Important limitations

- **Side turns, not campaign initiative integration.** Only passive perks are authored. This particular pooled-damage/side-turn configuration is ephemeral; stock restore rejects it and custom tiles are not serialized. No prototype save/load or campaign integration is claimed.
- Existing height affects climb AP and hit odds. There is **no height-aware LOS, hard maximum climb, numeric partial cover or 3D ballistic simulation**. Cliff faces are presentation, not secretly new movement rules. Walls and forests retain binary hex LOS rules.
- Characters share a static pose and family-level equipment illustrations. No walk/swing/death animation or in-battle equipment editor. Tests prove changing/removing actual equipment changes/removes layers; the live scenario shows distinct valid loadouts.
- Character grounding uses blob shadows, not animated silhouette shadows. Terrain/props receive real directional shadows. No atmospheric particle system was added.
- Rapid consecutive combat popups can overlap. Fine terrain/art details and the compact HUD need more work at small window sizes. Occlusion logic is exercised in tests; native screenshots are not an exhaustive readability audit of every possible camera/actor arrangement.
- Source-project Linux execution is qualified. Standalone exported binaries, other platforms, hardware performance and full campaign UI compatibility are not.

## Recommendation

**Continue with this rendering architecture, but do not convert the whole game or promote the temporary art yet.** State-driven 3D terrain plus layered 2D billboards works with the real engine and keeps gameplay authoritative. The next bounded milestone should replace a small character/terrain set with production-painted art and animation, then prove integration with the actual campaign initiative flow. Decide height-aware LOS and cliff movement as explicit gameplay design changes, separately from rendering. Keep the original 2D path available throughout.

Launch instructions and controls are in [../README.md](../README.md). Tests: `python3 prototype/run_checks.py --output /absolute/path/to/new-evidence`; use a fresh output folder. QA lifecycle tests: `python3 prototype/tests/native_runner_test.py`. Add `--legacy` to observe the documented inherited failures, not for an all-green gate.
