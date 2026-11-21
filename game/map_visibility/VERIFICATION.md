# Battlefield & Fog — verification and limits

## Verdict

**Accepted as an isolated playable reference-map candidate.** Not merged into the original/live game; procedural generation has not been implemented. The previously found P1 hidden-projectile-lane admission oracle is corrected and independently closed.

The executed and reviewed candidate02 inventory is `freeze-candidate-02/source-sha256.json` in the external evidence directory, SHA256:

`53daed126768265156cc83640f3d0bb64fc13544e986dbc8d4e64cfb618d2015`

This document is a later inert delivery addition. All runtime, assets, tests, project settings and launchers are the exact candidate02 bytes; the final delivery seal records that document-only difference rather than relabeling the tested inventory.

Evidence root: `/home/quatro/games/battle-brothers-2-map-visibility-evidence/`.

## Executed final headless aggregate

Fresh private project, private HOME/XDG/TMP, pinned Godot 4.4.1, bounded children, source integrity and actual raw-log hashes checked:

- **33 suites, 32,049 checks, zero failures**, plus successful cold import.
- Engine/visibility/default-off parity: 11 suites, 1,944 checks.
- Maps/session/cold persistence/isolation: 5 suites, 6,472 checks.
- Composed UI/camera/fog/observer/routed-input: 9 suites, 141 checks.
- Inherited current combat/perks/archer/terrain regressions: 8 suites, 23,492 checks.
- All exits zero; no engine errors, timeouts or source drift; all owned children reaped.
- Exact visibility-disabled frozen comparison remains **1,613/0**, including state, scheduler and RNG.

Receipts: `runs/final-candidate-02/receipt.json`, per-test raw logs and inventory; recomputed summary: `final-candidate-02-headless-summary.json`. These selected current suites are not a claim that every historical migration or inherited legacy suite is green.

### Real map fights and persistence

Both actual 32×32 authored boards have legal central two-rank formations with a six-step front gap. Map area does not add company members or grant equipment.

- Crossing: actual victory after 240 steps, round 14, one casualty.
- Woodland: actual victory after 70 steps, round 4, no casualty.
- First weapon contact occurs at step 12 in both deterministic fixtures; both sides perform paid movement and actual weapon commands.
- Stock settlement and a distinct-process cold reader retain real physical ownership, condition, survivors/deaths and camp resources. No combat-save serialization or ancient save migration was added.
- Terrain construction retains inherited mask arithmetic using local bins; 16×16/32×32/64×64 construction and rebuild fixtures pass. These CPU construction checks are not target-GPU FPS measurements.

## Independent review and the corrected leak

The initial complete source review is retained as **BLOCKED** at `review/report.md`. It found that moving an unseen fighter into a projectile lane could change the attack's public legality even when the target and company-visible terrain were unchanged. Generic refusal text and withheld damage previews alone did not close that Boolean oracle.

The minimal correction qualifies every required intermediate projectile cell using current party sight before physical occupancy checks. Unknown empty and unknown occupied lanes now refuse identically; personally visible targets are still required. True occupancy, known physical blockers, actual payment/reactions/combat math and RNG are not filtered or replaced. The conservative policy is documented in README.

- Implementer retained true RED/GREEN and focused results: `engine-lane-correction/handoff.md`.
- Independent identical authored-map probe: candidate01 **145 checks / 33 failures**, candidate02 **145 / 0**.
- Independent candidate02 execution: **7 suites / 5,815 checks / 0 failures**, including the probe, known paid ranged shots, composed observer/HUD/cues, actual AI choice and default-off parity.
- Exact source-pinned closure: `review-closure-candidate-02/closure-verdict.json` and `report.md`; passed with no remaining scoped blockers.
- Original complete review covers unchanged scope; closure reviews only the bounded correction and one capture-only harness step. No redundant whole-feature review is implied.

## Actual private native journey

Canonical run: `/home/quatro/omabox-trial/runs/default/19deee175d0b/report.json`.

Durable copy: `native/candidate-02/` in the evidence root. Native bindings: `native-candidate-02-binding.json`.

- **27 checks passed** through the real launcher and external pointer/keyboard input.
- Both boards, close and whole-board framing, real paid outward and return movement, newly discovered ground, remembered ground, withdrawal confirmation and return to camp were exercised.
- Nine screenshots retained. Actual final Crossing close, memory overview and Woodland close pixels were inspected: normal painted current sight, dim/desaturated remembered fringe and black unexplored ground are visible; no obvious material/shadow failure or hidden actor/name/bar leakage appears in those inspected states.
- `04-new-ground.png`, `05b-remembered-overview.png`, `07-woodland-close.png` are qualified gameplay captures. An initial close screenshot can precede the battle's painted frame and is not used as visual acceptance.
- Raw engine log has no error/warning/shader-failure markers. Exact native engine exited zero and was reaped; frozen source remained unchanged. Canonical cleanup and absence of the exact runtime/private HOME/cache/cgroup were independently checked.
- The renderer was **Mesa llvmpipe, OpenGL Compatibility software rendering** in the private desktop. This is actual native rendering/input evidence, not target-GPU performance, audio, exports, another platform or human fun/balance certification.
- Native coverage is scouting/camera/withdrawal/return, not a complete native victory/casualty fight or the specially placed hidden-lane regression. Those outcomes have separate real-engine headless evidence.

## Scope and remaining differences

- Crossing and Woodland are authored reference maps, not procedural recipes yet.
- Visibility is BB2's tested daytime radius-seven hex-ray/height policy with immediate refog. Native current-retail BB elevation, occlusion, night/helmet modifiers and brush hiding are not certified.
- Shared terrain sight does not grant every actor personal targeting sight. Unexplored movement routes and unknown intermediate firing lanes are conservatively unavailable.
- Existing projectile blocker/combat math remains separate; partial cover, interception/scatter and shooting-over-obstacle parity were not added.
- Raw ledger-driven visible attack lunges are withheld rather than consuming hidden command records. Qualified movement and safe hit feedback remain; a richer public attack-effects receipt is future work.
- Fog-enabled company AI searches known contacts/static rendezvous; boss tactics are not parity-certified in this slice.
- **CAMP persistence only:** quitting mid-battle returns to the last camp. Own namespace/checkpoint guard is `ashen-company-map-visibility` / `map-visibility-camp.json`; no old saves are imported.
- Human tactical enjoyment/balance, target-GPU FPS and integration with the full live world remain separate future acceptance boundaries.

## Launch and containment

Run the successor's executable `launch-map-visibility.sh` from its own root. It delegates to the preserved launcher, imports only this isolated project, then selects `res://map_visibility/main.tscn`. The project, namespace and checkpoint guard isolation tests pass. Do not use older launchers inside this successor namespace.

The accepted predecessor `/home/quatro/games/battle-brothers-2-combat-completion/` is protected by its full bootstrap inventory, rechecked by each candidate seal. Original game/save roots are not mounted into private acceptance. No Git staging, commit, merge, release, public push or live activation was performed.
