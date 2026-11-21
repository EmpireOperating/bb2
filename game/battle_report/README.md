# Battle Report — B / Iron & Oath

## Presentation / ownership

`hollow_campaign/main.gd` mounts `battle_report/report.gd` in the existing aftermath overlay. The inherited settlement/return/checkpoint owners are unchanged. The inherited `_aftermath_text` is still populated for consumers but hidden.

- Painted camp backdrop under a dark veil, existing brass-rimmed Iron & Oath panels and oxblood continuation button. Serif result and mission hierarchy; the battle map is untouched.
- Separate crowns/casualty strip, per-companion performance table and lasting consequences. Outgoing HP, armour and shield-condition damage use only `aftermath.rows.damage_hp`, `damage_armor` and `damage_shield`; missing fields default to zero in this projection only. No invented combined damage number.
- Recovered gear resolves `aftermath.loot[].item` literally through `campaign.items` and `campaign.item_def(uid)`. Artwork comes from the exact `iron_oath/inventory_art.gd.item_icon` resolver used by Company Inventory, through the actual `hollow_campaign/character.gd` appearance resolver. Unmapped actual items explicitly say **No artwork**.
- Inventory cards retain literal UID, rolled name, rarity and condition. The read-only inspector uses both canonical Company Inventory formatters, `inventory_presentation.summary` and `hollow_campaign/appearance.item_details`. There is no equip/sell/claim action.
- Fixed continuation footer outside a scrolling report body. Tab / Shift-Tab remains inside the active overlay and reveals offscreen loot. Enter / Space inspects the focused native loot Button. PageUp / PageDown / Home / End scroll the report; Alt with those keys scrolls exact item details. Escape does not bypass aftermath. Checkpoint errors remain the higher-priority modal.

## Mounted-engine tests

Tests are SceneTree scripts mounting the actual `application/run/main_scene` (`res://next_build/main.tscn`), not helper-only view models. Test-output files use `LM_OUTPUT` / `CUX_OUTPUT`, never `res://`. The source-bound runner copies a frozen source into a detached writable import project and isolates HOME / XDG state; use the shared engine lock.

Pinned engine:

`/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64`

Runner:

`/home/quatro/games/battle-brothers-2-character-sheet-evidence/attempt-01/run_gate.py`

Evidence root:

`/home/quatro/games/battle-brothers-2-battle-report-evidence/attempt-01`

Chronology and final receipt paths are recorded in the evidence root's presentation delivery notes. A RED runner receipt intentionally remains INCOMPLETE because this canonical runner stops at a failing case. Raw logs distinguish expected product failures from the retained interrupted import attempt.

## Native visual fixture (prepared, not gameplay)

`battle_report/tests/native_fixture.gd` mounts the actual project main scene, then installs a **clearly labeled synthetic settlement** containing genuine catalogue-generated rolled physical items. Mission title and consequence text label the fixture. It is composition/interaction evidence, not earned travel, victory, balance or reward acceptance.

The parent/operator must run this on its own isolated native desktop, using a fresh private source copy and isolated HOME / XDG roots. Import that exact private copy first. Do not run the fixture against real saves. Example engine command, after preparing those private roots:

```
GODOT_BIN=/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64
"$GODOT_BIN" --single-threaded-scene --path "$PRIVATE_PROJECT" --script res://battle_report/tests/native_fixture.gd -- "$ABSOLUTE_EXISTING_OUTPUT_DIR"
```

The last user argument is the existing absolute output directory outside the source tree. The fixture sets `root.size` and `root.content_scale_size` once per state, never every frame:

1. **wide** — requested physical/logical 1440×900.
2. **compact** — requested physical/logical 960×600.

For each state it waits for rendered frames, writes `<state>.png` from the native viewport and `<state>-ready.json`, then waits at most 75 seconds for `<state>-continue`. The private compositor owner may adjust the physical window after the ready handshake; JSON reports actual physical and logical dimensions rather than assuming compliance. Ready packets include PID, fixture label, report data, literal loot UIDs and raw/clipped native Button rectangles, selected UID, scroll position and fixed Return rectangle. After capture/optional external click, create the continuation marker. `<state>-after.json` records final inspection state. `fixture-complete.json` records assertions and failures.

Do not click a zero-area clipped rectangle. Use actual wheel/Tab scrolling to expose offscreen loot first. A full report view and a scrolled loot view are separate useful captures. Never describe a viewport PNG as a compositor screenshot; the parent can capture the private desktop independently at each handshake.

`-- --fixture-smoke "$OUTPUT"` permits headless construction/handshake checks without waiting or pretending to emit pixels. `native_pixels` is explicitly false in those receipts. Native visual acceptance remains distinct from headless semantic/input/geometry checks.
