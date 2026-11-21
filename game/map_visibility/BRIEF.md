# Battlefield scale and visibility — bounded successor

## User-approved goal

Preserve the accepted painted hex-map direction, enlarge ordinary combat maps to Battle Brothers scale, place the formations appropriately, and conceal areas/enemies the company has not discovered. Ordinary procedural generation is the next separate step; this candidate first establishes authored reference maps and a reusable map/visibility contract.

## Isolation and ownership

- Source successor: `/home/quatro/games/battle-brothers-2-map-visibility` (plain detached copy; no commit/merge implied).
- Preserved combat slice: `/home/quatro/games/battle-brothers-2-combat-completion`.
- Own checkpoint: `user://map-visibility-camp.json`, exact custom directory `ashen-company-map-visibility`; no imported older saves.
- Evidence: `/home/quatro/games/battle-brothers-2-map-visibility-evidence/`.
- Engine owns `src/battle.gd`, `src/tactical_visibility.gd` and engine-only tests.
- Content/session owns new `map_visibility/maps.gd`, `session.gd`, `terrain.gd` and map/session tests.
- Presentation owns new `map_visibility/battlefield.gd`, `controller.gd`, fog helpers/shaders and UI tests.
- Parent owns project/main/launcher/isolation, source freeze, integration, independent review and private native acceptance.

## Reference and explicit approximation boundary

The retained research finds ordinary plains/forest 32×32 boards in two pinned unofficial script snapshots. Normal opposing fronts are around six hex steps apart near the board centre, not at opposite edges. The official historical explanation distinguishes black unexplored terrain, dim/desaturated remembered terrain, shared company sight and personal target visibility. Base source vision is seven; actors do not block sight. Full references, rejected decompilation and current-retail uncertainty are retained in `research/research.md` and `source-excerpts.md` outside this project.

This is not an assertion of exact current retail BB visibility: native occlusion/elevation, brush concealment and within-round expiry were not independently measured. Any implemented hex-ray/height/refog policy must be named and tested as BB2 policy. Existing projectile blocking/cover remains separate from sight; do not silently rewrite combat math to create fog.

## Acceptance

- Two actual 32×32 connected authored battlefields, detached validated descriptors, legal independent twelve-slot placements, appropriate normal central gap, real enabled Battle dimensions and boundary queries.
- Authoritative paid movement, resources, activation origins, AI and settlement remain stock-owned. No equipment grants, healing, new turn resets or campaign-state shortcuts.
- Deterministic sight with no combat RNG consumption; company-shared terrain knowledge and personal attack admission; terrain memory never becomes a live enemy marker.
- Hidden enemies absent from rendering, health/name bars, selection/picking, target/hover/quote, initiative identity, feedback/animations, scenery fading and passive player observation.
- AI must search/advance without consulting live unknown enemy coordinates; truth still controls physical occupancy, reactions, scheduler and victory.
- Camera supports complete board bounds and overview while preserving readable close play. Fog updates do not rebuild terrain.
- Private fresh-copy RED/GREEN, baseline disabled-mode regressions, map/session cold persistence, independent frozen-source review and real private GUI screenshots/input. Headless arithmetic is not native rendering or human fun evidence.
- CAMP-only persistence remains explicit; no historical save migration, full world-game merge, new procedural generator or claim of target-GPU performance.
