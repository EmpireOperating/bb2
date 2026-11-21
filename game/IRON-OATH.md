# The Ashen Company — Iron & Oath UI candidate

Selected direction: B / Iron & Oath, authorized for implementation by Josh.

This is an isolated full-campaign UI successor. It is not the original game or an overwrite of the existing campaign/UI experiments. Start it with:

    ./launch-iron-oath-ui.sh

The launcher requires Godot 4.4.1.stable.official.49a5bc7b6; it checks the version and imports resources before launch. Set GODOT_BIN only to that pinned engine.

## Save isolation

Godot custom user directory and checkpoint envelope origin: `ashen-company-iron-oath-ui`.
Checkpoint: `user://hollow-campaign-camp.json`.
Existing builds' directories and saves are not imported or modified. CAMP checkpoints remain the sole persistence path. Quitting in battle is not a battle save.

## Approved scope

- B-style painted blue-black iron panels, thin aged brass trim and oxblood primary controls.
- Left roster, central real equipped figure with nine surrounding equipment cards, separate capacity-driven carried arms, right owned-stash/detail/equip area.
- Matching tactical overlays with map space retained; actual active versus inspected identity remains distinct.
- Existing gameplay, equipment authority, UID ownership/condition, prices, camera and maps are retained.
- The painted camp backdrop is inventory-only. It does not replace either gameplay map.

The selected concept's decorative labels, outfits and icons are not mechanics. Actual equipment controls and current painted-asset omissions take precedence; no demonstration gear or resources are granted to make the artwork look fuller.

## Provenance and acceptance

Base: frozen painted-overworld integration candidate `merge-overworld-01/freeze-01`, with only the accepted `ui-polish-01/freeze-03` UI delta integrated, then the scoped Iron & Oath changes. The separate painted-overworld integration's native promotion was still pending when adopted; this candidate does not retroactively certify that work.

Canonical implementation evidence:
`/home/quatro/games/battle-brothers-2-iron-oath-evidence/`

Selected references and original generated assets:
`/home/quatro/design-concepts/bb2-ui-2026-11-02/`

STATUS: READY_FOR_EXPERIMENTAL_PLAYTEST — functional B-style UI first pass, not final art-complete polish.

The combined runtime passed 1,141 checks across 37 headless test suites plus a cold import. Inventory/shared presentation and combat source reviews passed. Two private native Godot runs passed; the full smoke used 17 real external input gestures and retained nine screenshots. It exercised roster selection, removing/re-equipping the same owned item, Back to the unchanged paused overworld, ordinary travel/contact into combat, withdrawal confirmation/cancel, and End Turn. Both exact private task lifetimes retired cleanly.

Parent pixel review confirms the mounted inventory composition, painted frames/action rail and usable controls at 960×600 physical / 1440×900 logical resolution. This is private software-rendered verification, not host-desktop, GPU-performance, audio, or human playability approval.

Known visible limits: some stock starter equipment has no matching painted layer/icon, so actual characters look under-equipped and some item cards remain text-only; no fake wardrobe or filled stash was substituted. Long equipment names and compact utility labels truncate at small size; Details retains full information. The Company screen shares the skin but retains its existing management layout. The generated concept is an art target, not an exact screenshot of this build. Native logs contain the environment's missing optional libspeechd.so.2 message; the engine exited cleanly with no GDScript errors.

Final acceptance: `/home/quatro/games/battle-brothers-2-iron-oath-evidence/delivery-acceptance.json`.
Actual screenshots: `/home/quatro/games/battle-brothers-2-iron-oath-evidence/screenshots/`.
The final acceptance receipt, not the historical headless/preparation status text, records the completed checks and remaining limits.
