# Terrain and Battle Brothers terrain-rule successor

## User-authorized outcome

Improve the accepted Ruined Crossing terrain and build one contrasting Woodland Road ambush using reusable components. Finish terrain-related gameplay rules using vanilla Battle Brothers as the baseline. Scope includes ordinary terrain traversal, elevation, melee/reach restrictions, ranged line of sight/obstruction and elevation, and engagement where terrain affects it. It does not authorize replacing all existing combat, campaign, equipment, perk or economy systems with vanilla parity.

Continue from Full Outfits commit `5ad919b4f81126a24603e9375449c488b3549174` in this isolated `spike/terrain-rules` worktree. The user's previous build, import metadata and active checkpoint remain untouched. New mechanics must not silently alter the old explicit presentation scenes; use one small authoritative rule seam with bounded opt-in where practical, not a second combat simulation.

## Visual direction

- Retain accepted complete outfit art, identity, equipment authority, scale and color material.
- Preserve real 3D terrain and exact odd-row hex standing positions/height steps.
- Replace uniformly busy yellow-brown ground with larger quiet earth/grass regions, a clear worn approach road, damp darker banks and gravel transitions.
- Prefer broad readable landforms, irregular exposed rock and clear ways onto high ground. Hide cosmetic hex construction without obscuring legal cells or falsifying cliff traversal.
- Make ruins spatially coherent: foundations, broken corners and nearby fallen rubble; do not add tall decorative blockers to mechanically clear lanes.
- Woodland Road should contrast through wooded edges, a clear road, a raised flank and multiple viable approaches. It must reuse the terrain component path rather than copy the crossing renderer with another hardcoded river.
- Improve composition before increasing detail. Keep bounded mesh/surface counts appropriate to Compatibility/software rendering. Freeze tonemapper/exposure assumptions used by accepted sprites; no silent shader-domain changes.

## Rules source gate

Exact vanilla movement, fatigue, height, line-of-sight, cover and relevant Pathfinder behavior are being independently researched. Do not infer target rules from current approximations or assume geometric realism is vanilla. Preserve source URLs, quoted evidence and confidence. Label unverifiable edge cases explicitly and do not advertise full Battle Brothers parity. Reconcile the current engine's pathfinder, actual move/attack execution, AI and visible feedback through a shared implementation.

Research output: `/home/quatro/games/battle-brothers-2-terrain-rules-evidence/research/`.
Source audit output: `/home/quatro/games/battle-brothers-2-terrain-rules-evidence/discovery/code-audit.md`.
Baseline protected manifest: adjacent `discovery/baseline-manifest.json`.
Implementation file ownership and exact rule contract are finalized after those outputs, not guessed here.

## Acceptance

- Real RED/GREEN engine tests for each new behavior, including invalid actions preserving state/RNG.
- Movement highlighting/path cost, actual execution, AI and attack explanations agree with the adopted rules.
- Both authored maps support authentic deployment and complete fights without unreachable starting units or renderer-invented rules.
- A minimal camp map selector changes only the next deployment; no fresh-gear grant, healing, reset or midcombat map swap.
- Preserve actual equipment/conditions/identities through map changes, battle, retreat/settlement and camp reload. State isolation must prevent overwriting the user's accepted company checkpoint.
- Real private native input and screenshots on both maps, including movement/elevation/obstruction and fade/picking checks, with original protected-source comparisons and exact cleanup.
- Complete current regression cohort with obsolete assertions explicitly superseded, not silently dropped; known unrelated baseline failures remain disclosed.
- One final independent review of frozen source, cold archive and launcher verification, isolated commit only. No public push or main-game merge.
