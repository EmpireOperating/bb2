# Temporary layered character asset specification

## Status and provenance

These are original, temporary illustrated assets authored for this isolated proof, not extracted Battle Brothers artwork. The existing Iron 0.46 project had procedural `CanvasItem` character drawing, not a reusable painted sprite atlas. Its artwork and drawing code remain unchanged.

This set is vector-authored with outlines, gradients, hatch/metal/mail details and muted catalog-driven colors. It establishes equipment layering; it is **not** a claim of finished hand-painted production art or reference-image fidelity.

## Runtime contract

- Source of truth: each actual combat unit's `armor_parts`, `weapon`, `arms.weapon`, `arms.shield` and `shield` state. Cosmetic `appearance` is deliberately ignored.
- Armor slot: `group/layer`, with the catalog definition selecting shape and color. Actual condition/maximum controls worn tint; broken armor remains equipped. Missing armor removes its live layer.
- Held weapon: the combat `weapon` identity wins over a stale arm item. Catalog variants share weapon-family geometry while retaining their physical definition/item identity in `layer_signature()`.
- Shields: round, buckler and kite/heater silhouettes; broken/absent actual shields remove the layer. Unknown physical definitions have an explicit diagnostic fallback.
- `configure(unit,catalog)` / `refresh(unit,catalog)` are presentation only. They never equip an item, change statistics or mutate the unit.

## Authoring coordinates and ordering

- Shared transparent canvas: **384 × 512 pixels**.
- Ground/foot anchor: **(192,486)**.
- Scale: **0.0048 world units/pixel**; opaque anatomy is approximately 1.8 world units tall. Spear silhouette remains below 2.3 units.
- Full-body foundation plus separate body, head, weapon and shield PNG layers. Each has an editable SVG master.
- Order: rear cloak, anatomy, base garment, mail, outer armor, overcloth, reinforcement, head padding/mail/shell/face/decor, weapon, shield. Fur is placed over shoulders.
- The root sits at the exact logical hex surface. A camera-oriented illustration parent and small camera-depth offsets order the cutout Sprite3D layers. World depth testing stays on; character sprites do not render through terrain.
- A separate ground-plane alpha texture provides a contact shadow. Full dynamic character-shaped cast shadows are not implemented.

## Assets and reproducibility

`character_assets/build_assets.py` reproduces the SVG masters and PNG companions using `rsvg-convert`. `preview_layers.py` can produce an **offline art sheet** from runtime-derived signatures; that sheet is not gameplay evidence.

The delivered PNGs need no art-tool installation to play. Runtime prefers normally imported Godot textures when the import cache exists, with a raw-PNG source-run fallback for model-only tests before editor import. Texture images receive mipmaps. Native source-project execution has been exercised; standalone export packages and other platforms have not been qualified.

## Replacement-art requirements

Keep canvas size, foot anchor, slot ownership and transparent margins consistent. Create front/three-quarter illustrated poses before introducing facing variants. Preserve separate weapon grip/shield sockets and helmet facial cutouts. Match production figures' lighting/outline strength to terrain and retain readable silhouettes at default zoom. Build actual walk/attack/death frames around the same equipment anchors rather than baking the loadout into a single static character.

## Current limitations

One shared anatomy/pose; no gait, attack-swing or death animation. The view interpolates position and displays actual combat feedback. Related equipment definitions reuse family art. No campaign gear-editing interface is added: the scenario demonstrates distinct real equipment combinations, while automated tests replace/remove actual equipment and verify live layer changes. Production hand-painted assets, richer silhouettes, directional animation and art review remain necessary.
