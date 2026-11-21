# Dungeon Maps — frozen integration and ownership contract

Map-readiness only. Stock campaign content, floor/room graphs, enemies, gear, rewards, progression and settlement remain unchanged. Predecessor is immutable. New source `dungeon_maps/**`; only parent edits root README/project/launchers. Evidence outside source. Strict vertical TDD, private engine copies/state, bounded children and clean raw diagnostics. No GUI by implementation lanes.

## Authorized imported correction

Josh explicitly requested importing the two enemy-facing fixes from the current Burial source. Exact approved hashes are recorded in evidence/approved-imports.json: world_loop/character.gd mirrors enemy Composite sprites only, and prototype/battlefield.gd mirrors alpha-picking texture coordinates to match. These two precise imports supersede the inherited-byte prohibition for those hashes only. No other inherited runtime changes are authorized. Parent enemy_facing.gd proves actual facing/refresh and asymmetric mirrored alpha picking without Battle/RNG mutation.

## Actual coverage

Seven exact engine field IDs, not seven invented content types:
`crypt`, `crypt_barrow`, `crypt_gallery`, `crypt_throne`, `crypt_mound`, `crypt_garrison`, `crypt_royal`.

Current version6 sites: `dungeon_0→crypt_barrow`, `dungeon_1→crypt_gallery`, `dungeon_2→crypt_throne`; three `dungeon_barrow_[0..2]→crypt_mound`; `dungeon_complex_0→crypt_garrison`, `dungeon_complex_1→crypt_royal`; complex2 uses site-seed parity for garrison/royal. Saved `room.field` is authoritative; never reinterpret original landmarks through `Themes.theme()`. Generic `crypt` is supported generator/installer/preview coverage but has no fresh generated campaign site. No old-save migration.

## Ownership

- GENERATOR lane: `dungeon_maps/generator.gd`, `deployment.gd`, `tests/generator_*.gd`, `tests/deployment_*.gd`, optional owned test-only helper `tests/map_support.gd`; evidence `implementation/generator/`.
- DOMAIN/HOST lane: `dungeon_maps/session.gd`, `main.gd`, `tests/session_*.gd`, `tests/host_*.gd`, optional owned test-only `tests/domain_support.gd`; evidence `implementation/domain/`.
- GALLERY/RENDER lane: `dungeon_maps/gallery.gd`, `gallery.tscn`, `tests/gallery_*.gd`, `tests/render_*.gd`, optional owned test-only `tests/gallery_support.gd`; evidence `implementation/gallery/`. Reuse immutable `burial_ruins/battlefield.gd` and its crypt terrain/undead/player presentation. No new terrain, camera, control or sprite rewrite without concrete blocker and parent coordination.
- Parent: project/name/namespace/main.tscn/launchers, BRIEF/CONTRACT/README/VERIFICATION, isolation test, freezing/combined/native/independent review and delivery. No peer edits. All inherited2429 files protected except root README/project.godot. Share findings through handoff, not another owner's source.

## Pure generator and installer API

`generator.gd`:
- `const FIELDS` ordered exactly as above; `const RECIPE` fixed version string `seeded_crypt_v1`.
- `static func generate(field_id: Variant, seed: Variant) -> Dictionary`
- `static func validate(packet: Variant, expected_field: Variant, expected_seed: Variant) -> bool`

Input field must be a supported literal String; seed must be actual int in0..2147483647, rejecting bool/float/container/unknown IDs. Local seeded RNG only. Packet exact top-level keys:
`recipe`, `field`, `seed`, `descriptor`, `spawns`, `fingerprint`, `metrics`.

Descriptor `{id,title,width,height,goal,tiles,presentation}`: id equals exact requested stock field (do not rename Battle.map_id); complete flat odd-row tile dictionary, each tile explicit stone/wall, height0, blocked/vision_blocking/obstacle exactly matching actual wall rules; goal an in-bounds walkable Vector2i. Presentation includes biome=`crypt` AND arrays road/stream/bridges/keep (empty indoors). All coordinates/array/type domains validated before comparisons. Spawns24 distinct safe Vector2i anchors, first12 player side/last12 enemy side, usable separated fronts and connected travel between sides.

Genuinely varied walls/rooms/corridors/niches with recognizable field-family organization, not one fixed board with different labels or random floor colors. Legacy IDs may explicitly map to the corresponding architectural family. Start bounded: at most25×17 tiles, at most120 wall cells; retain flat heights and origin transforms. Dimensions may be smaller if adequate full24 deployment and meaningful routes. Budget is a ceiling, not a performance claim. Same request returns exact bytes, independent of all global/combat RNG. Fingerprint derives actual canonical geometry/deployment, excluding title/seed-only metadata; metrics are derived and independently checked, not trusted admission. Validate geometry/topology/spawns plus expected field/seed binding, including coherent tamper/rehashed packets. No unbounded retries or recursive generate/validate loop.

Formation integration detail: the stock company has18 selectable formation cells (two×nine), with at most12 living field members; tactical rows24 are not the same thing as18 possible formation positions. Do not silently flatten every lawful selected formation into one default twelve-position line. Keep canonical24 default anchors in packet.spawns, but include any additional deterministic formation/role anchor policy in descriptor.presentation (renderer ignores additional map metadata). Provide `Deployment.profile(battle, packet, expected_field, expected_seed) -> Array` for the exact24 actual positions derived from post-stock-deploy q/r: preserve selected player front/back/column distinctions and enemy role depth where possible, repair empty/dead collisions only after reserving every living legal position. Generation/fingerprint must remain independent of party/occupancy; actual deployment can legitimately reflect formation. All potential formation anchors and actual24 profiles must be distinct/safe within side and geometry; test all18 legal formation cells, not just the four previous corner failures. If an alternative equally faithful mapping is smaller, document it before changing the agreed interface.

`deployment.gd`:
- `static func profile(battle, packet: Variant, expected_field: Variant, expected_seed: Variant) -> Array`
- `static func install(battle, packet: Variant, expected_field: Variant, expected_seed: Variant) -> bool`
- Validate before mutation. Keep stock full24 units/map_id/gear/RNG/queues/scheduler/AP/fatigue/results/nonpositional perk transients. Install only extent/goal, tiles, all24 coordinates, actual authored_map metadata, explicit terrain rules and existing personal visibility; correct only current active perk positional origin. Preserve stock boss_tactics around configure_visibility(). Do not restart initiative or activate again. Refuse hostile packet/field/seed/shape with zero battle mutation/raw diagnostics. Domain publishes only after whole installer success; injected late failure must retain original live Campaign object/state/signals.

## Domain, host and current persistence

Own a successor session adapter as needed: inherited IO methods use lexical hardcoded constants, so merely overriding a subclass const does NOT isolate saves. New actual origin `ashen-company-dungeon-maps`, checkpoint `user://dungeon-maps-camp.json`; new main `_create_session()` sets path before inherited startup IO. `main.gd` may extend Burial main and reuse its world-view/guards/field factory; its existing world dispatch calls the burial_* method names, which remain supported aliases of the same generalized authority.

Provide `func dungeon_request(c = null) -> Dictionary` returning `{field,seed}` for the current actually bound occupied dungeon room (private helper, not public observer). Derive seed from canonical immutable tuple: generator recipe, world/region seed, literal site ID/site seed, floor index/floor seed, room ID/room seed and exact room.field. Exclude encounter counter, wear, living count, roster/formation, visited/looted/approach/withdrawals. No tactical geometry added to stock dungeon records.

Generalize all enter/context/attack/stairs checks together to real known physically reached stock sites and exact field support, preserving original arrival/contact/current-CAMP/stock validator semantics. Do not query hidden remote current state to paint a refusal. Generation/validation must precede stock deploy on the detached candidate. Deploy via unmodified stock Campaign; install generated terrain/positions; publish full descriptor + metadata before changed emits once. Keep signed job/escrow and every non-map stock delta exact. Retain inherited scouts/contracts/camp/outdoor routes unchanged.

Outside-combat current saves remain complete stock snapshots with all nine sites and battle:null; underground cleared and pending rooms admitted. Pending CAMP binding may include private map binding in checkpoint, but public observation must not expose raw identities/seeds/layout/hidden actors/loot. Public deployed/pending generation metadata is restricted to recipe, field and fingerprint; do not export packet/metrics/descriptor or new gameplay QA actions. Draw-bound inherited world/field observations remain authoritative.

## Gallery and shared rendering

Standalone `gallery.tscn` with real disposable stock Battle and same production `burial_ruins/battlefield.gd`, plus minimal facade only if field requires one. No Campaign, inventory grants, saves/loads, rewards, settlement or campaign QA endpoint. Clearly label **MAP PREVIEW — disposable battle, no campaign saves**. Ordinary paid battle controls may work on this disposable Battle; do not call it owned campaign progression.

Literal field selector covering all7 IDs, strict validated seed entry, explicit Build/Rebuild, Replay same seed and next-seed controls as practical. Field construction must call the production Generator and Deployment. Replace/dispose whole field on request changes, including actors/tweens/feedback/controller/fog/material references, rather than rebuilding terrain under old fog. Keep no duplicate callbacks. Invalid request leaves current field intact with visible refusal. Camera, normal inspection and paid ground movement remain available; do not reveal hidden terrain/units or bypass fog for convenience. Root/field viewport transforms must be published from actual layout and applied exactly once. If SubViewport is necessary, derive its actual offset/clipping instead of hardcoded screen points. Optional `--observe` is passive production-writer output only, no mutation endpoint; use a separate file/name from campaign and no default IO when not requested.

## Required qualification and honest labels

Generator lane: semantic RED→GREEN, all7 IDs×meaningful seed cohort, repeatability/global-RNG invariance, independent odd-row topology and unique all24 spawns, geometry-only diversity (e.g.16 fixed seeds per field, clear min distinct actual-wall signatures), architectural family distinction, hostile types/coherent packet tamper and exact no-mutation installation, stock unit/queue/RNG/transient parity. Keep evidence count reconciliation and raw diagnostics.

Domain lane: all9 real current sites individually through production session; prepared structural fixtures may stage physical arrival in test memory and follow genuine stock BFS to the first accessible occupied room excluding locked vaults. These are labeled prepared fixtures, NOT earned expeditions or starter-solvability evidence. Include generic crypt via independent standalone real Battle, complex2 both parity branches, founders default/corner and full12 formations, late refusal + signal-time metadata, stable geometry after true no-action withdrawal/reentry, immediate distinct-process pending and clear underground current saves. Explicitly preserve/document stock boss-AI compatibility rather than inventing a new AI policy.

Gallery lane: all7 actual request builds, real descriptor/geometry/anchors/fog/occluders, picking and paid movement, seed/replay/type transitions through actual root Window input, invalid controls refusal/no field loss, field lifetime retirement and exact player texture/outdoor invariance. Test practical960×600 and1440×900 physical viewports. Retain strict-decoded unchanged production-writer packets for parent's controller preflight. Gate raw errors plus final nonempty completion marker and bound reports.

Parent: combined immutable full-source cohort, one exact-source independent review, canonical private native all7 field selection/seed rebuild and deeper paid movement/camera/inspection/fog on mound/garrison/royal, plus authentic stock-world route smoke. Native map readiness does NOT require earning or winning every dungeon. Software rendering not target GPU/audio/fun; no campaign expansion. Seal exact runtime/asset/launcher equality and deliver working preview + actual routing + coverage matrix. Keep bounded memory, no simultaneous heavy native/headless siblings, preserve every failed attempt, exact cleanup and no duplicate unchanged review.
