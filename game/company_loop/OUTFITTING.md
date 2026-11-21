# Company outfitting panel

`camp_panel.gd` is the live camp view, not a wardrobe mock or the read-only Equipment Study inspector. It consumes the production `session.gd` and `character.gd` from `CONTRACT.md`.

## Player flow

1. Select a living company member. The name, current/max health, body/head protection, melee/ranged skill, defense and armor load come from the real session projection.
2. Select an equipped slot. The list includes the actual item name and condition when that item has a positive durability maximum. Weapons never acquire invented `0/0` condition.
3. Select a suitable **owned, unassigned** stash item. Selection alone changes neither equipment nor the portrait. Armor comparison uses Campaign's read-only `component_preview`, including current protection and load before/after. Weapon/shield comparisons name the actual replacement and modeled condition; they do not invent damage or defense bonuses.
4. Confirm **Equip selected**. Session/Campaign owns validation and the transfer. The old item returns to the stash, the exact actor texture and stats refresh, and the selected stash item clears. **Remove slot** preserves item identity and condition and obeys Campaign's fitting rules; a weapon must be replaced, not removed.
5. **Deploy company** only emits `deploy_requested`. The parent owns actual deployment, initiative, phase changes and saving. There are no fresh-kit, free-gear, repair or midbattle outfitting controls.

The persistent helper text is: **“Camp autosaves. Battles are not saved; quitting resumes your last camp.”** The parent owns autosave and blocking save-failure diagnostics; this panel does not write saves.

## Presentation and ownership

- Dark slate cards and restrained brass selection/focus borders follow the accepted Equipment Study inspector. Full-height roster, portrait, equipped slots and stash are separate columns at 1440×900. At 960×600 and 640×480, the equipped/stash lists stack and scroll independently; the footer actions remain on screen. Long compact names retain their full tooltip. All native buttons are keyboard-focusable and scroll containers follow focus.
- One hidden, offscreen, tree-owned production character composes the selected actual bro. Both `process_mode = PROCESS_MODE_DISABLED` and `set_process(false)` are applied. Composition still works without a camera.
- `TextureRect.texture` is the **exact** `character.preview_texture()` resource and the exact `Illustration/Composite.texture`. There is no UI compositor, copied image, decorative outfit or random character identity.
- Repeated binding of the same session preserves selection and connects `changed` once. Replacing, unbinding or exiting the tree disconnects the old session. Re-entry reconnects once. Removed/dead members and externally consumed stash selections are invalidated on refresh.
- Only `camp_panel.gd`, `tests/camp_panel_test.gd` and this document belong to this UI workstream. Terrain, simulation, art sources, parent control, save implementation and protected paths are not edited here.

## Passive native observer

Call `observation()` on the mounted panel after layout settles. Coordinates are **viewport/client-space pixels**, including parent CanvasLayer transforms; they are not desktop-global coordinates. `viewport_rect` and `window_size` describe the spaces separately. A native driver must apply its observed physical-window mapping rather than hardcode the examples below.

- `selected_sid`, `selected_slot`, `selected_item_id`, `unit_name`, `phase`, `revision`.
- `selected_preview`: deep copy of the complete actual `session.preview_unit(selected_sid)` dictionary, including company/visual identity, HP/stats, item-bearing armor parts and arms.
- `preview_layers`, `preview_texture_id`, `preview_diagnostics`, `preview_rect`. Texture IDs are **signed nonzero** integers; negative values are valid.
- `slots`, `items`: deep-copied real domain rows; `comparison`, `reason`, `checkpoint_notice` mirror the UI.
- `targets.roster["<sid>"]`, `targets.slots["<slot>"]`, `targets.items["<item_id>"]` and `actions.equip/remove/deploy` each contain:
  - `center: [x,y]`, `rect: [x,y,width,height]`, `clipped_rect`;
  - `visible`, `disabled`, `text`, `reason` (the native tooltip).
- `buttons` is a convenient center-only mirror: `buttons.roster`, `buttons.slots`, `buttons.items`, plus `buttons.equip/remove/deploy`.
- `scrolls.roster/slots/items` are viewport-space scroll rectangles. A hidden target has no usable click center. Wheel over the appropriate scroll rectangle, observe again, and click only a visible, enabled target with a nonzero clipped area. Selection does not imply successful input; check the corresponding selected identity afterward.

Measured footer centers in the retained untransformed headless runs:

| Viewport | Equip | Remove | Deploy |
|---|---|---|---|
| 1440×900 | (88, 869) | (236, 869) | (1321, 869) |
| 960×600 | (88, 569) | (236, 569) | (841, 569) |
| 640×480 | (82, 449) | (230, 449) | (527, 449) |

At 1440×900 the measured slot centers are x=811 with y=154 weapon, 220 shield, 286 base, 352 mail, 418 outer, 484 helmet, 550 ammo. These are examples, **not** driver constants; stash rows and scroll positions depend on the actual inventory.

## Verification

Final focused result with Godot **4.4.1.stable.official.49a5bc7b6**:

```text
CAMP_PANEL_TEST checks=204 failures=0
EXIT 0 CLEAN_LOG True
```

Evidence: `/home/quatro/games/battle-brothers-2-company-evidence/camp-ui/final-production/` contains the complete raw `engine.log`, command/environment/source-hash `receipt.json`, and a fresh private `home/`. The three actual observer snapshots are written under that private Godot user-data directory as `camp-1440x900.json`, `camp-960x600.json`, and `camp-640x480.json`. Earlier RED and intermediate attempts remain in sibling directories, including the fixed compact name/health overlap, two-handed refusal explanation, same-session selection reset, and parent-canvas observer defects.

The suite runs actual `Window.push_input` pointer motion/down/up, wheel, Tab and Enter against the real panel, real session/Campaign and real production character/PNG assets. It verifies owned-item equip/remove, unique ownership and unchanged inventory count, changed real stats, damaged helmet preservation/removal/re-equip, shared resource identity with independent field-capable actors, same-identity refresh, passive browsing, disabled repeat/invalid actions, external selection invalidation, responsive bounds/reachable last rows, transformed canvas input, deployment-signal ownership and connection lifecycle.

No early domain/art doubles are used. Damage, death and noncamp presentation tests deliberately seed the **real** domain's item condition/alive/phase fields; these are explicitly labeled test arrangements, **not combat damage, battle settlement, save/resume or full parent-entry E2E proof**. All actual equipment changes in the UI journey use routed native controls; the external-invalidation test separately invokes real Session.equip to simulate another legitimate domain owner.

Run from the repository with a fresh private state root and no display access:

```sh
private="$(mktemp -d "$TMPDIR/company-camp-ui.XXXXXX")"
env -u DISPLAY -u WAYLAND_DISPLAY \
  HOME="$private" XDG_DATA_HOME="$private/data" \
  XDG_CONFIG_HOME="$private/config" XDG_CACHE_HOME="$private/cache" \
  /home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64 \
  --headless --single-threaded-scene --path . \
  --script res://company_loop/tests/camp_panel_test.gd
```

Treat a logged engine/script error or warning as a failure even if the process exits zero. Retain raw logs and private state. This workstream performed **no GUI launch, native screenshot/pixel approval, deployment, staging or commit**. Parent/private-Omabox acceptance remains responsible for the integrated live window, terrain/battle flow, save/resume and visual judgment.
