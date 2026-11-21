# Combat Completion — verification

## Candidate and implementation

Worktree `/home/quatro/games/battle-brothers-2-combat-completion`, branch `spike/combat-completion`, based on `f0fc831a6bd48453f8c6366e7abd6256acefe26f`. Changes are uncommitted. Runtime: Godot 4.4.1 (`49a5bc7b6`), SHA256 `54215149d52efb1d653a3dec39d0993587bdf5daa2c56e787b5ee88417fb1339`.

Common seams and ownership:

- `src/battle.gd:1428` `action_quote`: read-only admission, target-aware AP/fatigue, hit breakdown and current-perk damage range. `:1469` `perform_action`: revalidates then dispatches canonical commands. Battle remains the only combat mutation authority.
- `src/battle.gd:2157` `damage_context`, `:2181` `perk_damage`, `:2196` `damage_preview`: context is explicit; commit owns RNG draws and Armor writes; preview enumerates possible rolls without RNG or mutation. `src/combat_damage.gd` owns pure current arithmetic.
- `src/battle.gd:634` AP explanation follows actual action cost. `:1934` shield-block wear uses equipped defense. `:2221` shares active-perk prices.
- `combat_pass/controller.gd` owns only selection/target mode. `combat_pass/battlefield.gd` owns controls/formatting; existing actor/terrain/camera presentation is inherited. Modal gates replace old Execute/End callbacks rather than connecting duplicate handlers.
- `combat_pass/session.gd` exposes owned carried slots via Campaign and enforces the isolated checkpoint origin. No new progression or equipment authority.

## Headless final candidate

Evidence root: `/home/quatro/games/battle-brothers-2-combat-completion-evidence/implementation/`.

`final-candidate/receipt.json` records the private project, isolated HOME/XDG/TMP, exact argv, per-suite 120-second limits, exits, reaping, log hashes and source drift. `source-sha256.json` pins 2,219 source inputs. Import and all 12 suites exited zero, no timeouts or script/test errors, no source drift:

- Combat UI: 56 checks.
- Action quotes/regressions: 13.
- Utility/perk/switch commands: 52.
- Damage parity/preview: 3,841.
- Company session: 287.
- Separate-process cold reader: 10.
- Existing perks: 134.
- Existing ranged perks: 7,513.
- Existing combat baseline: 141.
- Existing archer rules: 396.
- Existing terrain rules: 11,402.
- Existing map rules: 98.

**Total: 23,943 checks; zero failures.** This is the selected current-candidate cohort, not a claim that every inherited suite passes.

The damage oracle in `tests/frozen_damage.gd` is test-only pre-change code. Across the tested weapon/special/perk/reaction/seed combinations, the extracted resolver matches actual damage, armor wear and subsequent RNG state exactly; possible outcomes lie in the immutable preview. The legacy non-perk path was not replaced.

Headless session witnesses use actual fights/commands: Ruined Crossing victory (137 steps, round 8), then Woodland Road defeat (92 steps, round 8); a separate casualty/withdrawal route observes one fallen companion after 76 steps. Settlement, owned equipment wear, one-time consequences and a separately launched cold reader pass. These outcomes are headless, not native victory/casualty claims.

RED evidence and failed setup attempts remain retained. Independent read-only Codex review found an inherited Help-overlay Execute/End callback bypass. The failure was reproduced, callbacks replaced with guarded single handlers, and all tests rerun. `review-correction.txt` reports no blockers in that correction. The unsupported default review-model attempt remains as setup failure; the supported review model was `gpt-6-astra`.

## Native external-input acceptance

`native/attempt-02/report.json`: canonical private desktop task `default-ad5e607b4499`, driver exit 0, status passed, cleanup verified. `native/attempt-02/engine/final.json`: exact Godot process exit 0, reaped, zero source mismatches. Private runtime/HOME and recorded box/network processes retired.

Actual production launcher and scene, read-only frozen stage copied into private HOME, software-rendered Wayland/llvmpipe, Dummy audio. The compositor delivered a 936×550 client; observed canvas transform was used for input. Eight screenshots retained and attack/woodland pixels inspected.

Actual external pointer journey: camp → deploy Ruined Crossing → Wait → weapon special → Guard → movement → basic attack with live on-hit preview → confirmed withdrawal → aftermath → return/save → map chooser → deploy Woodland Road. Real AI turns occurred through the normal update loop. No gameplay injection, fabricated damage or save fixture was used.

`native/attempt-01` remains a failed driver route: a proposed ground-hex center was visually occupied by a foreground actor, so correct actor-first picking selected an enemy instead of moving. Engine closed cleanly, source unchanged, canonical cleanup passed. The controller-only correction conservatively avoids observed actor bounds; the retained observation rejects that point and offers safe alternatives. The second complete run passed without changing production bytes.

Native screenshots show controls and conditioned damage ranges without clipping in the tested client. Text is small at this downscaled private-window size; this is not a blind human usability study. Active learned perks, switching and Recover have headless command/UI coverage, not separate native action witnesses. No native cold relaunch, native victory/casualty proof, target-GPU performance, real audio, exports or other-platform claim.

## Scope limits

No old-save migrations or inherited obsolete-suite repairs. The discovery classification remains under `discovery/`. No perk-learning, new weapon content, full catalog art, world/campaign UI, missing retail mechanics, terrain/art changes or base-game merge. Fresh companions do not receive free active perks. Saves remain camp-only in `ashen-company-combat-completion/combat-camp.json`.

Final documentation differs from the frozen runtime candidate only as recorded in `implementation/delivery-integrity.json`; final runtime bytes remain bound to the headless/native/review receipts. Historical art/terrain files are compared against Git HEAD, not silently resealed.
