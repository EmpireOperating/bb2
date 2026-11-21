# World-loop shared implementation contract

Scope/constraints: `BRIEF.md`; source audits in evidence `discovery/session/campaign-seam-audit.md` and `discovery/ui/READ_ONLY_AUDIT.md`.

## Session lane (exclusive ownership)
`world_loop/session.gd`, `world_loop/deployment.gd` if needed, `world_loop/tests/{session*,deployment*,checkpoint*,cold*,journey*}_test.gd`, optional `world_loop/tests/support.gd`. Evidence `implementation/session/`. Plain RefCounted, one stock Campaign, no demo subclass. Host-facing API:
- signal `changed`; `campaign`; `last_error: String`.
- `setup(seed: int = 7391) -> void`: exact normal src/main setup flags (all current features except regional_recovery), enable_dungeons. Stock founders/gear only.
- `start_battle() -> bool`: actual pending scout contact ONLY, transactional detached Campaign.deploy, stable geometry binding, 24 slot profile; no artificial job/teleport/grants. Refuse other contacts clearly without mutation.
- `resolve_battle()`, `retreat_battle()`, `return_to_camp() -> bool`: stock methods, exactly once.
- `selected_map_id = "generated_woodland_road"`; read-only `deployed_map: Dictionary`, `deployed_generation: Dictionary`, `selected_generation() -> Dictionary` (public recipe, seed, fingerprint only; empty before bound contact).
- `save_camp(path: String)`, `load_camp(path: String) -> bool`, checkpoint `user://woodland-campaign-camp.json`, exact origin `ashen-company-world-loop`. Strict current stock restore/canonical equality permits real roster/catalog/jobs/pending contact; never migration/import or active battle serialization. Silent save/no recursive changed.
- `preview_unit(sid: int) -> Dictionary`, `gear_slots(sid: int) -> Array` only if needed by observation; keep catalog-wide actual data, not SUPPORTED filter.
- Stable mapping version `woodland_contact_v1`, derive from world seed + encounter kind/id/site/generation (exclude encounter counter so withdrawing/recontact does not reroll same force; different generation varies). Can recompute rather than journal if no time-varying data; validate consistency on load. Accepted generator packet/geometry fingerprint unchanged; expanded spawn profile separately versioned and validated.

## Host/UI lane (exclusive ownership)
`world_loop/main.gd`, `world_loop/world_view.gd`, optional `world_loop/observer.gd`, `world_loop/tests/ui*_test.gd`. Evidence `implementation/ui/`.
- Parent owns project.godot, launch-world-loop.sh, world_loop/main.tscn, isolation_test.gd, scope docs. Main scene root Node2D; host may extend company_loop/main.gd (Node) and reuse overlays, not its camp panel/session defaults.
- Use session API above. `world_view.gd` subclasses src/main.gd to retain existing CAMP overworld/town/roster/market/recruitment controls. Inject actual session.campaign, don't call original boot/stock save. Intercept every deployment/new/load/save/attack_camp/dungeon entry. Genuine roaming scout deploy routes host; other battle entrances explicitly unavailable with honest message for this bounded slice, never unhosted 2D combat.
- World node hidden+PROCESS_MODE_DISABLED+input disabled outside CAMP. Accepted field single command/AI authority; host settle once, aftermath->same world map-first. Fully refresh/rebind world Campaign/Battle after detached swap/load/new and disconnect stale signals. Save error overlays block command mutation/deploy and retain corrupt checkpoint.
- `_create_battlefield()` points to `res://world_loop/battlefield.gd` (parent presentation adapter, inherits accepted grassland). Until it exists, missing dependency is setup failure; do not invent it or edit parent files.
- Public `observation()` and single atomic `user://company-observation.json` when --observe: top-level `world_loop:true`, `phase`, `saved_ok`, `checkpoint_blocked`, `viewport`, `screen_transform`, company actual roster/gear, inventory owned only. `world` subobject visible actual UI control rectangles, known markers, player position/time/resources, selected context/mode, pending public encounter. All real enabled button geometry from existing immediate-mode UI. No full world snapshot or unseen party positions. Field observer merge only during battle; no hidden actor/meta leaks. `generation` = session.selected_generation() or deployed_generation for battle/aftermath.
- Explicit seed7391 fresh default for reproducible first loop; original existing new-company dialog can choose another seed. No --smoke/demo resets.

## Parent presentation/tools/verification ownership
`world_loop/{battlefield,character}.gd` if necessary for truthful bounded same-family equipment proxies (no new gameplay/gear grants), `world_loop/tests/{isolation,presentation}*_test.gd`, tooling/evidence/docs, final native journey/review. Preserve original art and accepted files byte-exact. Any proxy must derive actual definition/family, preserve UID/condition/stats, disclose proxy mapping in existing read-only inspection and not claim exact authored coverage. Unsupported families remain explicit omissions, never sword substitution.

## Concurrent discipline
Only own paths above. Every behavior strict vertical RED/GREEN with retained raw output, private copied tests via evidence/run_private.py (120s child cap, isolated HOME/XDG). Actual engine pinned4.4.1. No native GUI, source imports, public writes, git commits or save reads from live HOME by children. Concurrent new owned-path source drift is not a product failure; final parent freeze closes the gate. Tell parent early if this API conflicts with real source; do not silently alter another lane.
