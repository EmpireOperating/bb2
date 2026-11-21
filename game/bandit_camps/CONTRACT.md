# Bandit Camps — integration and ownership contract

All runtime additions live under `bandit_camps/`; preserve every accepted `world_loop/`, `src/`, renderer, actor, art and generator byte. Parent owns project config, launcher, scene, BRIEF, this contract and evidence runner/sealer. No lane may edit another lane's files.

## Session lane
Own `bandit_camps/session.gd` and `bandit_camps/tests/session*_test.gd`, `camp*_test.gd`, `cold*_test.gd` plus uniquely named `session_support.gd` if required. Use a scoped copy of accepted `world_loop/session.gd`, not inherited constant shadowing. Namespace `ashen-company-bandit-camps`, checkpoint `user://bandit-camps-camp.json`. Preserve all current snapshot/nested-version/canonical/atomic guards and default Campaign flags.

APIs retain accepted `setup`, `start_battle` (scout), selected/deployed generation, previews, resolve/retreat/return and save/load. Add:
- `camp_attack_reason(site: String = "") -> String`: pure, returns empty iff contract-free assault on that physically reached active camp is admissible; empty argument resolves current location. Refuse active contract, any encounter/pending scout, active dungeon, wrong phase/dead/empty company, remote/unknown/inactive target. Never mutate live encounter for inspection.
- `start_camp_battle(site: String = "") -> bool`: stage a validated detached Campaign, use genuine `candidate.attack_camp()`, verify exact resulting kind/site/generation and no contract redirection, derive stable camp packet, install accepted terrain/24 spawns/active positional-origin/visibility, publish only after all validation. Refusal retains original object, snapshot, metadata, signals and prior checkpoint bytes. Keep scouts' exact old key/recipe/seed/fingerprint behavior.

Camp binding may use `woodland_camp_v1/woodland_road_v1`; selected CAMP generation must stay truthful without inventing a pending encounter. Existing accepted `world_loop/deployment.gd` owns the immutable stock24 profile. Do not introduce a second Campaign/Battle authority or public fixture mutation API. Private late-failure tests may use only test subclasses/seams; no production force-win/teleport endpoints.

## UI/host lane
Own `bandit_camps/main.gd`, `bandit_camps/world_view.gd`, optional `camp_recon_view.gd`, `bandit_camps/tests/ui*_test.gd` and uniquely named `ui_support.gd`. Copy the small accepted host where needed because factories/checkpoint are hardcoded. Reuse unchanged `world_loop/battlefield.gd` directly. Scene is already parent-owned and references `bandit_camps/main.gd`.

Intercept the real `attack_camp` action before legacy handler; call host `_deploy_camp()` -> session `start_camp_battle(world.world_selected)`, with save/error and shared accepted mount/lifecycle guards. Retain scout deploy, every legacy direct-helper/input/processing/feedback fence, once-only settlement and map-first same-position/time return. Contracts/continue/dungeons remain refused; do not let stock can_deploy redirect camp action to a contract.

Reuse actual existing camp recon detail, approach/watch and close/Escape semantics. Inspection/decline at paused genuine arrival must not create an encounter or mutate the complete domain. Do not change pause merely to make this test pass. Add only a bounded explicit Leave/selected-camp status if needed; no art/map redesign.

Observation keeps existing `world_loop:true` shape for inherited external helpers and adds `bandit_camps:true`. `world.selected_camp` is emitted only for currently admitted known selected camp, with literal site/name/at-site, same displayed dated reconnaissance label/report summary, watching, actual mounted assault/approach/leave controls/refusal. No garrison/hidden HP/remote fresh-roster exports. Read-only result status must use participant/last-observed truth and existing known journal/trade projections, never dump all world events/caravans. Root/field observers continue visibility-filtered rows and one final viewport transform.

## Shared fixture and evidence
A genuine default route is proven in `evidence/discovery/session/route_probe.gd`: seed7391 starts `(784,656)`, ordinary travel to discovered `ford` `(624,624)`, reissue same travel order after scout-sighting pause (do NOT pursue scout), arrive day1 15:15, empty job/encounter, one real resident, no home party. Use this route, not captured snapshot injection. Existing `world_loop/tests/support.gd` provides a separate real scout fixture.

Independent discovery audits contain source anchors. Parent native acceptance and final combined freeze/review are separate gates. Use private copies/HOME/imports and raw diagnostics, retain semantic RED/GREEN and exact owned-file hashes during concurrent work. Tests intentionally leaving corrupt default checkpoint must run last or in fresh HOME; UI purchase fixtures need a fresh town HOME. Schedule cold reader immediately after writer in the same private HOME. Do not change unrelated files, weaken old tests, use original/live saves, run GUI, commit or claim broad acceptance.
