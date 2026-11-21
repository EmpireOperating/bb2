# Seeded Woodland Road — bounded first recipe

## Scope and isolation
Build the first reproducible procedural ordinary-battle recipe on the accepted 32×32 map/fog candidate. Keep the painted art, shaders, combat engine, ownership, fog policy and both authored reference maps unchanged. Do not build a biome catalogue, full world-game merge, historical migration, paid dependency, public release or new combat system. Human fun/balance is not certified by automation.

Source: /home/quatro/games/battle-brothers-2-procedural-woodland
Evidence: /home/quatro/games/battle-brothers-2-procedural-woodland-evidence
Protected predecessor: /home/quatro/games/battle-brothers-2-map-visibility
Own namespace: ashen-company-procedural-woodland
Own checkpoint: user://procedural-woodland-camp.json

## Shared frozen API
- New folder is procedural_woodland/; do not edit inherited runtime, map_visibility/, company_loop/, terrain_pass/, art, tests or helpers.
- Generator lives procedural_woodland/generator.gd, RefCounted. RECIPE_ID = "woodland_road_v1"; MIN_SEED=0; MAX_SEED=2147483647. Default selected generation seed73.
- Generator.generate(seed: Variant) -> Dictionary. Invalid type/range or bounded validation failure returns {}. Successful detached packet has EXACT keys recipe, seed, descriptor, fingerprint, metrics. Uses only local seeded randomness, never global/combat RNG.
- Generator.validate(packet: Variant) -> String, empty only when well-formed/version/seed/descriptor/fingerprint/layout contracts pass. Revalidate actual geometry, not supplied diagnostic metrics alone. Strict types/closed fields, finite bounded generation; never silently fall back to an authored map or another undeclared seed.
- Generator.descriptor_fingerprint(descriptor: Dictionary) -> String: deterministic SHA256 of the full gameplay/presentation layout, EXCLUDING human title (so different seed labels do not fake layout diversity). Include tiles/heights/obstacles/spawns/goal/presentation. Stable sorted-key canonical serialization under pinned Godot4.4.1; no object IDs/timestamps.
- packet.descriptor is EXACT existing eight-field LargeMaps descriptor, id="woodland_road", width=height=32; pass map_visibility/maps.gd::validate. Presentation biome woodland, matching road footprints, no crossing scenery. All12 normal tactical spawn slots legal, central fronts at least six steps apart. Keep roster/equipment identities and stock initiative.
- Build deliberate bent west/east road, coherent groves/clearings, broad stepped elevations with traversable one-level approaches, protected spawn space and multiple approaches. Reject disconnected/unreachable walkable terrain, unusable deployments or route bottlenecks. Feature/route constraints must be demonstrated independently in tests; fair here means bounded structural checks, not guaranteed human balance.

## Integration seam
- New session extends map_visibility/session.gd. select_map("ruined_crossing"/"woodland_road") keeps authored references byte-exact. Additional selection id="generated_woodland_road".
- select_generated(seed: Variant) -> bool validates/generates before atomically publishing selection; camp-only. generation_seed is saved seed. _selected_descriptor() provides detached generated descriptor to inherited transactional start_battle(); no duplicated Campaign or Battle authority. Expose selected_generation() -> Dictionary containing only public recipe/seed/fingerprint metadata ({} for fixed). Capture deployed_generation on successful deployment so metadata cannot drift during battle.
- Keep the seed+recipe version+selected map in one strict successor checkpoint envelope with the real validated Campaign camp snapshot. No sidecar journal, old-save import, battle serialization or second ownership model. Atomic write/readback and whole-validation-before-publish; malformed/unsupported version/seed leaves company and selection unchanged.
- Camp UI has fixed maps plus Generated Woodland Road, a literal seed field, Apply seed and Next seed. Next seed may deterministically increment/wrap only generation seed; never reroll combat/global RNG or replace owned gear. Selecting seed does not deploy; normal Deploy commits.
- Expose passive camp actions seed_input/apply_seed/next_seed and map_choices.generated_woodland_road using actual clipped control geometry; state includes generation_seed and selected_generation. Keep modal/keyboard admission and current equipment controls intact. No generation metrics/hidden terrain in the battle observer.
- Parent new main owns session/camp factories and public generation metadata; own battlefield can inherit map_visibility unchanged. Parent app title "The Ashen Company — Procedural Woodland".

## Ownership and acceptance
- Generator lane owns generator.gd and procedural_woodland/tests/generator*_test.gd only.
- Integration lane owns session.gd, camp_panel.gd and procedural_woodland/tests/{session,cold,ui}*_test.gd only.
- Parent owns project/config/main/launcher/isolation, runner, source seals, final review/native delivery. No engine changes planned.
- Strict vertical RED/GREEN, private copied projects/HOME/XDG, bounded child timeouts, exact source/runtime/log hashes, cold persistence immediately after writer and real paid fights. Retain failed attempts honestly; parallel-owner drift is not a failing assertion, but only the final no-writer frozen cohort closes acceptance.
- At least64 distinct topology seeds plus boundary/invalid seeds, repeated determinism, mutation isolation, genuine layout diversity ignoring titles, runtime/global RNG purity, actual terrain construction for distinct layouts, real generated fights and current combat/fog regression. Native acceptance must use ordinary controls to choose seeds and deploy at least two different generated boards, fixed reference still available; inspect real pixels and clean up exact private processes.
- No human playtest has been claimed. Deliver the first recipe ready for one, not a claim that all random battles are enjoyable or that full campaign contextual generation is integrated.
