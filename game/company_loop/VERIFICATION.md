# Company Outfitting — verification and boundaries

## Candidate and preservation

This isolated company loop is based on accepted Equipment Study commit `bdac7019aa5860bc9435958e479f26b099be6322`, on branch `spike/company-outfitting`. No main-game merge or public push. `src/`, `data/`, `tests/`, `assets/`, `prototype/`, `visual_slice/` and `sprite_study/` remain byte-identical to that base. The original Iron 0.46 download's 3,585-file preservation manifest also matched. The accepted equipment PNGs, source foundation, terrain, lighting and fixed Compatibility color material are unchanged.

The native runtime was frozen at tree `1bfbc382b09d8ca045dd10500fe4dc84572e111f`. Subsequent additions are documentation, inert evidence and checkpoint-UI regression/runner coverage, not application-runtime changes. Final source/package/review identities are retained outside the source tree under `/home/quatro/games/battle-brothers-2-company-evidence/` to avoid self-referential hashes.

## Automated execution

Engine: **Godot 4.4.1.stable.official.49a5bc7b6**. Cold import and all suites run in copied projects with private HOME/XDG and `--headless --single-threaded-scene`.

`python3 company_loop/run_checks.py --output /absolute/new-evidence-directory`

Final aggregate: **38,915 Godot assertions, zero failures; 24 Python tests passed**, across 26 completed commands including import. `evidence/headless-summary.json` retains exact commands, markers and results. The new company subset covers:

- Session: 669 checks, including a genuine victory in 218 steps / round 12 / 206 commands; real loot, wear, second deployment, real enemy-inflicted casualty followed by retreat, ownership, duplicate-settlement rejection and corrupt checkpoint/path refusal.
- Character: 214 checks, stable heads/cache, original equipment resolver, removal, damage, real picker geometry, presentation motion/cancellation without simulation mutation.
- Camp panel: 204 checks with production session/renderer/PNG dependencies, routed pointer/keyboard/wheel input, real equip/remove, exact preview identity, condition preservation, lifecycle and 1440×900 / 960×600 / 640×480 bounds.
- Integrated app: 42 checks; phase boundaries: 7 checks; checkpoint-failure UI: 11 checks. Invalid existing bytes are not overwritten, deployment blocks on save failure, retry resumes without healing or granting items.
- Separate domain process reload: 110 additional checks, outside the aggregate, including another deploy/retreat/return.

The runner requires positive assertion completion markers, not just exit code zero. One exact inherited test-only image-export warning is allowlisted solely for the unchanged old sprite-character test; it was reproduced independently on immutable `bdac701`. No application/native warnings occurred. The old sprite-study default-scene assertion is explicitly superseded by the new company entrypoint test; preserved launchers remain tested. Earlier legacy armor (97), weapons (37) and tactical-AI (4) failures are not fixed or counted as passing.

RED attempts are retained in the external evidence directory, including absent integration, initial user-directory mismatch and the modern `weapon`-command presentation boundary. They are not counted as successful runs.

## Native external-input acceptance

Canonical private Omabox run: `0a7390510c62`. Ordinary external mouse/keyboard events drove the actual Godot window; the application exposed a passive observer, not a mutation/test command interface. No user-desktop takeover or user campaign save access.

**41 observed checkpoints; 13 actual engine screenshots; two separate engine lifetimes; exit 0 and verified cleanup.** Retained acceptance/report files are in `evidence/`; the complete driver, observations and raw logs are in the external `native-final/` directory.

The native journey verified:
1. Six real company members and owned stash in saved camp.
2. Equip an owned kettle helmet and axe; visible composition changes and item identity preserved.
3. Copper and silver head identities; remove/re-equip the exact helmet, revealing/restoring the head.
4. Deploy exact people, item IDs/conditions and appearance into real individual initiative.
5. Read-only field inspection matches the camp equipment; move onto the bridge and execute an accepted attack with genuine combat feedback.
6. Advance activations to round 3 with real enemy actions and damage.
7. Withdrawal confirmation blocks commands; cancel preserves state; confirm settles once without payout.
8. Return to camp with shield **40→39**, mail **95→63**, and kettle helmet **100→66**; no repair/reset.
9. Close and cold-relaunch: exact company, inventory and encounter results restored from the private checkpoint.

Native withdrawal had no deaths; death/loot/victory acceptance comes from the real headless domain battles, not a fabricated GUI victory. Native source manifests matched all 1,985 staged source files before and after both lifetimes. Additional engine-generated `.import`/`.uid` metadata was separately identified. Both native/import logs had no errors or warnings. The private processes, runtime and home were removed by the canonical runner after evidence collection.

Screenshots inspected for actual pixels: camp equipment, silver bare head, battlefield and aftermath. The camp figure retains bold painted materials and clear equipment silhouettes; the overview is necessarily smaller/softer. The native window used a scaled 936×550 surface inside a private 960×600 desktop; UI remained usable, but screenshots are not a target-resolution art benchmark.

Renderer: **Mesa llvmpipe software OpenGL, Compatibility**. This verifies actual shader compilation, draw output and interaction—not hardware-GPU FPS, audio, exported binaries, Windows/macOS or blind human playability. Audio was Dummy. Shared Texture2D identity is tested in-engine; no claim of pixel-exact full-screen identity across every zoom/postprocess mode.

## Scope and limits

- One authored repeatable crossing, six startup companions and a small physical inventory; no world travel, shop, recruitment, rest/repair, new-company recovery screen or full campaign UI.
- **Camp-only autosave.** Active combat is not serialized; quitting resumes the last camp. Return to camp persists outcome, casualties and wear. Single-writer Linux atomic rename, not a multi-process database or power-loss/directory-fsync guarantee.
- Three painted male head variants repeat across six real generated identities. Names, backgrounds and stats remain actual campaign data; visual IDs are not yet a sex/age/portrait-accurate full character generator. Shared body/stance; short lunge/recoil/guard pulses, not full attack animations.
- Limited accepted equipment art families. Some base garments share artwork; covered inner armor is mechanically present but may be visually suppressed by an authored complete outer outfit. Bow/spear remain carry poses. Existing salvage assemblies are not dismantled by this small UI.
- Existing height costs/hit modifiers and binary blockers only; no height-aware LOS, hard maximum cliff climb, partial-cover percentage or physical 3D projectiles.

Recommendation: keep this simulation/presentation separation and shared equipment composition as the foundation. Judge the next step by playing the equip/fight/return loop, not by expanding terrain or catalog breadth before the existing experience is satisfying.
