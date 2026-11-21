# Equipment Study — verification

## Candidate and containment

This isolated follow-up is based on Painted Crossing `d210199d036af232d16a1fece3eb518c6a5fd827`, on `spike/equipment-sprites`. It changes the default entry point and adds `sprite_study/`; it does not merge into the main game. All 1,544 tracked files under the protected `src`, `data`, `tests`, `assets`, `prototype`, and `visual_slice` paths match that base. The original download's 3,585-file manifest also matches. See `evidence/preservation-final.json`.

Terrain geometry, textures, world lighting and camera implementation are unchanged. No original artwork or campaign saves were replaced. The new private user-data directory is `ashen-company-sprite-study`.

## Executed tests

Godot **4.4.1.stable.official.49a5bc7b6**. `python3 sprite_study/run_checks.py --output <new-directory>` cold-copies and imports the project with isolated HOME/XDG state, then exercises:

- Preserved prototype suites: layout, controller, view, scenario, character, terrain.
- Preserved Painted Crossing suites: loadout, view, character, terrain, integration.
- New real-art character, modal inspector, scene integration and source-color correction suites.
- Python native-child lifecycle, source-art and entry-point tests.

Final aggregate: **37,768 Godot checks, zero failures; 17 Python tests passed**. Individual logs and summary are under `evidence/headless/`. The color arithmetic gate executes production shader scalar equations through a narrow test translator against an independent upstream forward curve; this is not itself GPU evidence. The native run below supplies actual shader rendering.

The inherited legacy armor, weapons and tactical-AI failures remain documented in the earlier proof. They were not changed, rerun as part of this focused pass, or relabeled green. The old full-UI journey is explicitly skipped by `--skip-legacy` in this native cohort.

## Actual native game acceptance

Canonical private Omabox run: `268b28ba2287`; retained in `evidence/native/` and `/home/quatro/games/battle-brothers-2-sprite-evidence/native-final/`.

- Native Godot, Wayland, Compatibility renderer, **Mesa llvmpipe software rendering**, 936×550 window inside the private desktop; Dummy audio.
- **34 observation-backed checkpoints, 17 actual window screenshots.** All input was external mouse/keyboard, not a command-injection test API.
- Selected friendly actors, opened/closed the equipment panel by button and keyboard, and checked the exact actual equipment signatures against the battle actor.
- Compared mail/nasal/sword/kite, brigandine/kettle/axe/round, bare-head/light/no-shield, and restored mail through fresh real battle creation. These are new-battle comparisons, not free in-combat equipment swaps.
- Verified modal keyboard, restart, pointer and camera guards without battle-state mutation; reopened and returned to combat.
- Exercised close/overview zoom, HUD hide/restore, pan/reset, bridge movement with AP expenditure, enemy targeting, actual attack feedback, enemy actions and next-round progression. Continued real combat until armor/HP damage occurred, without changing RNG.
- Engine exit 0, wrapper final receipt present, tested source unchanged. Import/native logs have no engine/script ERROR or WARNING records. Verbose startup reports unavailable optional Speech Dispatcher/cursor resources; speech and audio were not qualified.
- Canonical cleanup verified; parent independently confirmed exact recorded processes, private runtime, cache and service cgroup absent. The 1,844-file native input stage matched the working candidate before adding these documentation/evidence files.

Representative **actual game screenshots**:
- `evidence/native/03-menu-mail.png`
- `evidence/native/03-menu-brigandine.png`
- `evidence/native/03-menu-light.png`
- `evidence/native/03-gear-detail.png`
- `evidence/native/05-crossing-move.png`
- `evidence/native/08-armor-damage.png`

These are not generated concepts. Asset sheets elsewhere are explicitly offline art evidence.

## Visual judgment and limits

The menu now visibly separates cool mail, oxblood brigandine, helmet silhouettes, sword/axe and shield shapes, with stronger contours and preserved anatomy. The battlefield has recognizable matching equipment colors and shapes, without the previous extra Filmic lightening of painted colors. No obvious rectangular cut seams, duplicated face/hands or broad edge halos were visible in the inspected captures. Grounding and terrain depth remained intact in this played scene.

This is a promising equipment-art direction, **not final reference-art parity**. Tactical downsampling still removes fine details, especially at overview zoom; the menu is much sharper than a small battlefield figure. One shared static pose/face remains conspicuous across a company. Some real item variants have no authored layer and appear empty-handed/unarmored in those slots; diagnostics and menu labels disclose them. The shader is bounded to this fixed Godot Compatibility/Filmic/exposure/white configuration. No screenshot-wide RGB equality, target-GPU FPS, all possible occlusion arrangements, animation, export build, other platform, or full campaign inventory integration is claimed.

Use this shared real-equipment compositor as the foundation for further sprite production. Expand distinct poses/faces and the equipment catalog deliberately; do not substitute independent menu portraits or spend another terrain pass before this core equipment presentation is accepted.

## Retained failures

The first native attempt (`f4ed3159e8ef`) stopped because its harness incorrectly required a positive Godot texture instance ID. The actual nonzero resource ID had its signed high bit set; both battle and menu had rendered. Its rejection receipts are retained in `evidence/native-first-rejected/`. The corrected harness accepts a nonzero signed ID, while headless tests independently require exact Texture2D resource identity. This was not a product fix or a passed first run.

Construction RED/GREEN evidence includes missing layers, crown/wrist extraction corrections, source-color material binding, and a label correction removing invented weapon `0/0` durability. Documentation in ART.md, MENU.md and RENDERING.md separates fixture checks, real-art checks, and native acceptance. Raw evidence logs are preserved byte-for-byte.
