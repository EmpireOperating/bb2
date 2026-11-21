# Woodland Campaign — bounded playable encounter connection

## Goal
Reuse the existing full overworld/town/company game and accepted painted 32×32 generated battle, fog and low grass. Produce one authentic loop: leave town, meet a real roaming band, deploy actual company/owned gear against that encounter's real enemies on a stable generated Woodland Road layout, fight or retreat, settle once, return to same world, reach town/manage/save/reload.

## Isolation
- Working successor: `/home/quatro/games/battle-brothers-2-world-loop`.
- Evidence: `/home/quatro/games/battle-brothers-2-world-loop-evidence`.
- Protected accepted predecessor: `/home/quatro/games/battle-brothers-2-procedural-woodland`; accepted grass delivery manifest `79f928fda0ac7554349114fad55cd1b7ff036b1ee6dd85b4840cd7995d71254c`.
- Protected original game and all live saves are outside scope.
- Own app title `The Ashen Company — Woodland Campaign`, custom user directory `ashen-company-world-loop`, default scene `res://world_loop/main.tscn`, executable `launch-world-loop.sh`.
- Camp-only checkpoint `user://woodland-campaign-camp.json`, strict origin/version/canonical digest/atomic replace/readback. No historical save import and no active-battle serialization. Do not accidentally invoke stock save path from inherited UI.
- Do not commit, merge, publish, spend, mutate user desktop or overwrite another build.

## Boundaries
Reuse actual Campaign setup/restore/travel/encounter/deploy/resolve/retreat/return, stock World/Battle/ownership/enemies/initiative. Do not reuse demo setup grants, demo enemy kits, artificial sortie jobs or teleport-to-ford. No new world simulation, biome catalogue, quests, weather, economy or combat rebalance. Preserve accepted source art, shaders, geometry, generator, fog/targeting and controls. Existing authored special maps remain present; wider special-site 3D rendering need not be claimed for this first ordinary encounter slice.

Generation must derive a versioned recipe seed from durable world/encounter identity, not combat/global RNG, title, wall time, camera or input timing. Repeat the same contact after reload/withdrawal without rerolling its ground. Different admitted contacts must demonstrably vary layouts. Admit complete map and detached Campaign before publishing; failed generation/deployment leaves company, world, encounter, RNG and selection unchanged. Only terrain, tactical placement and position-derived active origin may differ from stock deployment. Do not reset initiative, AP, fatigue or perk transients. Expose only public generation metadata in field observation.

Camp UI is existing world/town/management, not a recreated company/economy. Route accepted 3D battlefield through the same session campaign authority and remove hidden stock 2D combat input/AI underneath. Retain stock world semantics and observer visibility; no hidden enemy positions/terrain, true occupancy, internal planning or attack-admission leakage in battle. Modal/save-error guards apply before input and autosave.

## Acceptance
Vertical strict RED→GREEN with real production entry path and retained raw failures; bounded cold private copies/HOME, per-child timeout/cleanup, hash-bind source and exact engine. Current active campaign flags and save snapshot restore must be verified, not inferred from stale milestones. Compare authentic enemy/owned item identities and immutable values to stock deployment. Real accepted paid fight/retreat/settlement and no duplicate reward. Distinct-process cold reader immediately after writer with exact world position/state, stock resource effects and inventory. Native private ordinary input: travel/contact → real generated battle → paid action → aftermath → world → town/management → close/cold reopen; source/pixel/cleanup evidence, separate from human fun or target-GPU benchmarking. Independent final-source review, preserved predecessor manifests, executable launcher and honest limits.
