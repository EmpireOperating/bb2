# Equipment inspection

## Player controls

- Select a living friendly with the existing field/roster controls. **Equipment [I]** or **I** opens that person's equipment inspection.
- **Return to battle**, **Escape**, or **I** closes it without issuing a battle command. Clicking outside does not dismiss it or click through.
- The full-body preview is the **same Texture2D object** returned by that actor's `preview_texture()` and used by its `Illustration/Composite` Sprite3D. There is no independent illustration, costume state, or second compositor.
- Body and head list every actual worn part. Weapon and shield show the actual held items; carried items/ammunition appear when present. Names come from the equipment catalogue (including named-item overrides). Condition is current/maximum only where the engine models a positive durability maximum; ordinary weapons without durability do not display a misleading `0/0`. Broken and empty slots are explicit.
- HP, AP, body protection including padding, head protection, and fatigue are live battle values. Opening after real combat refreshes the preview and labels; it never repairs anything.
- **Next kit · New battle** cycles the existing three `visual_slice/loadouts.gd` profiles on the explicitly named hero, even when inspecting another person. Its explanation says this starts a fresh battle and discards the current fight. It reloads the actual scene using the existing kit mechanism, not an in-combat equipment grant. The existing field **L / Next kit** control remains intact.

This is an ephemeral equipment-inspection prototype, **not campaign inventory management**. No campaign save, equip/transfer command, or persistence path was introduced.

## Modal and rendering boundaries

The study subclasses the existing painted battlefield. It loads `visual_slice/terrain.gd` unchanged and retains the inherited camera, lighting, combat controller, terrain rules, picking, and normal field controls. Only the actor script is replaced by `sprite_study/character.gd`.

A separate full-viewport CanvasLayer receives modal pointer input. The battlefield guards keyboard and unhandled field input. While inspection is open, the battlefield's normal processing does not advance the AI accumulator or pan the camera; passive observations still publish. Scene animation/tween presentation is not a new simulation clock. Closing resumes the existing AI rather than resetting its queued timing.

The dark-neutral paper doll fits the complete source canvas without cropping. Gear details scroll independently at smaller sizes; the preview and close/new-battle controls stay within the viewport. Logical viewport bounds were exercised down to **640×480**. Existing field-HUD compactness at small sizes is inherited, not redesigned here. Unsupported painted equipment remains honestly listed with an explicit limited-art note.

## Passive native-observation contract

The existing opt-in `--observe` publisher continues to write `user://prototype-observation.json`, including while the inspector is open. The parent-owned project config selects the custom user directory. Observations are read-only; there is no input/command backdoor.

Additional top-level fields:

- `sprite_study: true` (inherited `visual_slice: true` remains)
- `inspector_open: bool`
- `preview_unit_id: int` (`-1` when closed)
- `preview_layers: Dictionary` (empty when closed)
- `buttons.equipment`: actual field button center
- `buttons.inspector_close`, `buttons.inspector_nextkit`: actual centers, present while open
- Existing `buttons.kit`, `kit_index`, `kit_name`, `screen_transform`, `viewport`, battle/unit/command observations remain available.

`inspector` contains:

- `preview_unit_id`, `unit_name`, `preview_texture_id` (Godot object instance ID), `preview_layers`, `slots` with literal IDs/definitions/names/condition/maxima.
- `buttons.close` and `buttons.nextkit`, each `[x,y]` in the same logical viewport coordinates as inherited buttons; empty when closed.
- `panel_rect` and `preview_rect`, each `[x,y,width,height]` in logical viewport coordinates. These are layout diagnostics, not synthetic clickable targets.

Use the inherited `screen_transform` when translating logical coordinates to native window pixels. Window title: **The Ashen Company — Equipment Study**.

## Headless verification

Run in a private copied/imported project with isolated HOME and XDG directories:

```text
/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64 --headless --single-threaded-scene --path <PRIVATE_PROJECT> --script res://sprite_study/tests/inspection_test.gd
```

The test mounts the production `.tscn` as the real current scene and routes real Godot Window key/pointer press/release input. It verifies:

- I/button opening and I/Escape/button closing preserve battle snapshots, every unit and tile, RNG/commands, selection, target, AI accumulator and camera.
- Different friendly identities, actual displayed gear names/conditions, full-resolution source-PNG textures, exact Texture2D resource equality, and equal actor signatures.
- Pointer/wheel/keyboard/restart/camera controls cannot act behind the modal, including a genuinely attackable target; ordinary paid movement and attacks work after closing.
- A real enemy side cannot advance during an open inspector, observation still publishes, and the existing enemy AI resumes after closing.
- All three comparison transitions replace the real scene/battle, exactly match the unchanged loadout factory, leave the abandoned battle unmodified, and return to playable field controls.
- Preview, explanation, scroll column and action-button bounds at 1440×900, 1024×720, 800×600 and 640×480; close/restart targets and explanations do not overlap.
- Actual enemy combat supplies damage; reopened previews and gear labels reflect the current worn state without repair.

Executed with Godot **4.4.1.stable.official.49a5bc7b6**: **214 checks, zero failures**, clean exit, no script errors. Additional unchanged headless regressions: controller **14**, scenario **550**, loadout **93** checks, all zero failures. A separate fresh-state default-main-scene smoke also exited cleanly and published a real observation under `ashen-company-sprite-study/prototype-observation.json`: study flags true, inspector closed, kit 0, player side, round 1, twelve actors and a visible Equipment-button target.

Construction evidence is retained in `/home/quatro/.hermes/cache/scratch/sprite-menu-jvl0btsv/`: initial missing-scene RED, input-guard RED, missing-preview RED, missing-comparison RED, and succeeding GREEN logs. An early unguarded restart probe invalidated its scene and hit the process timeout; the harness now stops on the preceding state violation before destructive restart probes. Early open/close/control passes used a **private staging-only legacy-renderer dependency fixture** while the new renderer was unavailable. That fixture was replaced before preview/integration verification. `13-final-real-source-integration.log` uses the production renderer and real source PNGs, explicitly asserted by the test. No fixture is shipped in these owned files.

**No GUI was launched by this worker.** These are headless input/resource/layout/simulation proofs, not native screenshots or visual acceptance. The parent owns final native E2E, generated-art review, launchers and project configuration. Legacy campaign suites were not reclassified as green.

## Ownership

This lane created only:

- `sprite_study/battlefield.gd`
- `sprite_study/battlefield.tscn`
- `sprite_study/inspection_panel.gd`
- `sprite_study/tests/inspection_test.gd`
- `sprite_study/MENU.md`

No commits or staging; no edits to existing `src`, `data`, `tests`, `assets`, `prototype`, `visual_slice`, terrain, camera implementation, launchers, project configuration, or the other worker's renderer/art.
