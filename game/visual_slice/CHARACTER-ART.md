# Painted character slice

## Implemented and verified

`character.gd` extends the unchanged `res://prototype/character.gd`. Its inherited equipment resolver remains authoritative: real `armor_parts`, combat `weapon`, `arms.weapon`, `arms.shield`, shield condition and catalog families select layers. `configure`, `refresh`, `set_selected` and the existing `layer_signature` fields remain available. The only refresh specialization selects a crown-hair-suppressed foundation when a real helmet shell is equipped. No appearance loadout, stat override, equip mutation, or baked complete armed unit is used.

**19 transparent, full-canvas PNG layers** are in `assets/characters/`. The production canvases contain no checkerboard. Their richer RGB artwork comes from generated paintings; Python performs chromakey/masks and rigid object registration, not SVG character construction.

Supported hero profiles exercised against real equipment definitions:

1. `sword`, `shield`, `linen`, `mail`, `arming_cap`, `nasal` — mail, nasal shell, sword and kite shield. Arming-cap art is explicitly omitted, not replaced with a false visible item.
2. `axe`, `round_shield`, `red_gambeson`, `brigandine`, `kettle` — visibly different outer coat, helmet, weapon and shield.
3. `sword`, no shield, `linen` — original bare head, ordinary clothing / equipped quilt-family overlay, no lingering mail or outer coat.

Removing all actual gear returns only the ordinary brown-clothes foundation. That foundation has an empty equipment definition and `ordinary_clothing=true`; the visible coat and boots are **not** evidence of equipped armor. Catalog `linen` itself uses the `quilt` family. A real base garment adds a restrained catalog tint and responds to condition. Broken armor remains present and dimmed; a broken shield disappears.

## Canvas and native geometry

- Canvas: **1024 × 1536 RGBA** on every character layer.
- Common foot anchor: **(512, 1460)**; Sprite3D `pixel_size = 0.00129`.
- Original opaque crown reaches **1.806 world units** above the nominal foot. The lowest painted sole extends slightly below the nominal anchor; no root repositioning is performed.
- Stable opaque selection witnesses, in source pixels: face **(530,190)**, torso **(475,450)**, boot **(310,1425)**. Face witness in the camera-facing foot frame is approximately **(0.02322, 1.63830)**. A nominal `1.8` head observation is at the crown edge, not the reliable face center.
- Parent illustration retains actual camera-basis orientation, Sprite3D billboard facing, alpha opaque prepass, world depth testing and physical `priority × 0.001` camera-depth offsets. Render priority alone is not relied upon.
- The original separate ground-plane shadow is retained. No legacy vector equipment is composited over the painted figure.
- Original weapon-hand pixels are composited above supported weapons at priority 21. They are restricted to the actual weapon's alpha support; shields remain in front. Both source hands and all exposed facial features come from the original base, not regenerated full-body edits.

## Extraction / reproduction

```sh
python3 visual_slice/assets/character_sources/build_layers.py
python3 visual_slice/assets/character_sources/run_checks.py \
  --output visual_slice/assets/character_sources/evidence/new-check
```

Pillow and NumPy are the only build dependencies. The delivered PNGs need neither package at runtime. The builder resolves paths relative to itself and writes only its adjacent character output and character-source evidence. The runtime reads original PNG bytes and creates mipmapped ImageTextures, including without an editor-import cache. Standalone/PCK export behavior has not been qualified.

`build_layers.py` retains every polygon, feather radius, atlas selection and source-to-canvas rigid transform. Magenta extraction derives alpha from magenta excess and unmattes color rather than discarding dark paint. Strong residual backdrop pixels are removed even in enclosed negative spaces. Masks exclude edited face, skin, hands, legs and boots; cuff and hem boundaries follow clothing. The helmet-only crown suppression removes protruding original hair without importing a second face; actual helmet removal restores the original base.

`layer-manifest.json` records source hashes, layer hashes, actual alpha bounds and opaque-pixel counts. `evidence/reproduction.json` verifies **22 outputs** (19 layers, two offline sheets, manifest) are identical across the retained build and two complete rebuilds. Base/mail inputs still match the original attached source images byte-for-byte.

`offline-character-sheet.png` and `offline-joins.png` are deliberately labeled **offline asset evidence**, not engine/gameplay captures. They show ordinary clothes, the two equipped art combinations, a light combination, enlarged head/cuff/grip cuts and tactical-size reductions. The art sheet omits runtime wear and restrained base-garment tint; it is not a fabricated engine screenshot.

## Generation provenance

Full exact prompts and returned receipts for the two new requests are in `assets/character_sources/provenance.json`.

| Source | Provider / model | Requested / decoded pixels | Tool `quality` field / reported quality | Request ID |
|---|---|---|---|---|
| `equipment-master.png` | `openai-codex` / `gpt-image-2-medium` | `1536x1024` / `1536x1024` | `medium` / **`low`** | `18edf6f4-46ce-4de2-9c8c-b5226c25e070` |
| `brigandine-master.png` | `openai-codex` / `gpt-image-2-medium` | `1024x1536` / `1024x1536` | `medium` / `medium` | `b32e5446-2465-4738-acf5-11c23dcb8600` |

Both new image requests supplied the original base mercenary as their one image input. Exact returned `size`, `pixel_size`, `requested_size`, `reported_size`, `quality` and `reported_quality` fields are retained separately. In particular, the equipment sheet is not mislabeled as reported-medium quality.

`../sources/base-mercenary.png` and `../sources/mail-mercenary.png` were supplied by the parent, each decoded at 1024 × 1536. Their provider, model, request IDs, requested/reported quality and actual dimensions are recorded in `../PROVENANCE.json`; source identities and hashes are retained in the layer manifest. These are exploratory generated art inputs, not approved production assets or gameplay evidence.

## Honest family coverage and limits

`layer_signature()` adds `painted`, `visible`, `art_family`, `asset_root`, `fallback_reason`, `catalog_color` and `ordinary_clothing`. Original physical definition/item identity, family, condition, maximum, broken state, priority and fallback remain available. A signature is returned for unsupported equipped armor even when its art is intentionally omitted.

| Equipment | Painted representation |
|---|---|
| quilt-family base garments | Original brown quilt cut; restrained real-catalog tint, not bespoke linen tailoring |
| mail | Painted mail coat; source design includes its shoulder caps |
| short/long mail | Same mail coat, explicit broad-family proxy |
| brigandine | Separately painted oxblood riveted coat |
| leather / plate / patched | Brigandine-coat proxy, explicitly not exact leather/breastplate geometry |
| scale | Mail proxy, explicitly not actual scale construction |
| shoulders / collar | Separate cuts from painted mail source; not separately generated new designs |
| nasal / kettle | Separately removable generated helmet designs |
| cap | Derived nasal source with nose-strip cut, explicitly approximate |
| bascinet | Nasal-shell proxy, explicitly approximate |
| sword / axe | Separate complete painted objects, rigidly fitted to the original hand |
| dagger / buckler | Scaled sword / round-shield source derivatives, explicitly approximate |
| round / kite shields | Separate painted shield sources fitted to the offhand |
| padding/coif/face/decor, cloak/overcloth; spear/polearm/mace/hammer/bow/crossbow/bolas | Not authored in this bounded slice: explicit `visible=false`, `fallback=true` with reason; never silently replaced with old SVG equipment or a false sword |

Arsenal variants reuse supported family art, including differing real weapon statistics; this is not a full catalog silhouette proof. Unsupported families on other scenario actors may therefore be visually absent. Unknown families retain the upstream resolver's documented fallback identity behavior.

This remains one static shared pose/anatomy. Weapons do not swing, hands do not regrasp, and shields do not animate. The natural source hands were retained rather than regenerated as bespoke closed grips. Clothing/helmet masks and rigid fitted objects are usable layered art, not a skeletal-animation package. Painted source edits are not pixel-identical to the base; the equipment masks deliberately retain original exposed anatomy. Some catalog families share broad proxies, and fine material detail reduces at battlefield size.

## Real engine verification

Godot **4.4.1.stable.official.49a5bc7b6**, `--headless --single-threaded-scene`, fresh isolated HOME/XDG directories; **no GUI opened**.

Final authoritative receipt: `assets/character_sources/evidence/final-verified/summary.json` and adjacent complete logs:

- Painted character suite: **206 checks, 0 failures**.
- Unchanged prototype character suite: **327 checks, 0 failures**.
- Unchanged prototype view suite: **763 checks, 0 failures**.
- **1,296 checks total**, all processes exit 0; no Godot errors in final logs.

The new suite exercises live separate Sprite3D layers for the actual hero profiles, physical identities, removal of armor/head/weapon/shield, broken-condition presentation, absent-shield handling, no equipment mutation, all armor-catalog diagnostics, shared bounds and approximately 1.8-height anatomy. It calls the **unchanged real battlefield picker**, not a test replacement, for opaque head/torso/boot pixels and transparent margins at three camera zooms. It checks actual native world-depth/prepass/billboard properties and ground-shadow geometry.

REDs were observed before implementing the foundation, equipment adapter and crown-hair correction. Historical logs remain under `evidence/`. Early foundation attempts exposed magenta-border alpha noise and pre-frame AABB timing; both were corrected. The initial combined runner used the wrong expected marker (`VIEW_TEST` rather than the actual `VIEW`); its failed receipt remains under `evidence/final/`, and the corrected fresh run is `final-verified/`.

Protected `prototype/`, `src/`, `data/` and legacy `tests/` have no Git diff from this lane. Nothing was staged or committed. Parent-owned level/HUD/loadout controls are outside this lane. **Headless tests and offline sheets do not establish native rendered gameplay acceptance**; integrated scene, camera framing and real GUI clicks remain the parent's verification step.
