# Sprite study rendering contract and evidence

## Delivered boundary

`character.gd` is a presentation subclass of the **unchanged** `prototype/character.gd`. Its inherited `configure`, `refresh` traversal, `_refresh_arms`, `set_selected`, `layer_signature`, billboard alignment and ground-shadow creation remain authoritative. The overridden `_add_layer` records the resolver's actual equipment choices; it does not equip items, consult `appearance`, change statistics, or reproduce combat rules.

The adapter assembles one CPU source-over image, generates one final mip chain, and binds one `Sprite3D` under `Illustration/Composite`. `preview_texture() -> Texture2D` returns that **same resource**, not a separately drawn portrait. The `GroundShadow` is a separate inherited ground-plane blob; it is not part of the menu texture or actor picker.

The menu should use the returned texture directly with aspect-preserving fit and linear/mipmap filtering, not rebuild the equipment stack. Null means rendering was refused: show an explicit unavailable state and consult `render_diagnostics()`, not a legacy portrait. No GUI code is owned by this change.

## Source-grounded diagnosis, not native visual acceptance

The old path was read in `visual_slice/character.gd`, `prototype/character.gd`, `prototype/battlefield.gd`, `visual_slice/battlefield.gd`, `project.godot`, and the original `src/main.gd` drawing routine. Godot's **4.4.1-stable** upstream renderer source was also inspected:

- [Sprite3D material construction](https://github.com/godotengine/godot/blob/4.4.1-stable/scene/3d/sprite_3d.cpp#L259-L285): opaque prepass maps to alpha-depth-prepass material; render priority is only applied for alpha-cut-disabled sprites. This confirms the old physical per-layer depth offsets were deliberate, not redundant.
- [Compatibility fragment output](https://github.com/godotengine/godot/blob/4.4.1-stable/drivers/gles3/shaders/scene.glsl#L2281-L2306): `MODE_UNSHADED` bypasses material lighting, **not** exposure/tonemapping and linear-to-sRGB output. The old battlefield explicitly selected Filmic. Therefore warm directional light is **not a direct explanation for the unshaded character's color**, but the 3D color pipeline can alter even unshaded painted pixels.
- [Filmic curve](https://github.com/godotengine/godot/blob/4.4.1-stable/drivers/gles3/shaders/tonemap_inc.glsl#L38-L54) and [material alpha generation](https://github.com/godotengine/godot/blob/4.4.1-stable/scene/resources/material.cpp#L1700-L1710) confirm those are separate operations. The Sprite3D `alpha_scissor_threshold=0.12` is also the unchanged picker's CPU alpha cutoff; it is **not** a promise that opaque-prepass rendering performs an identical 0.12 discard. StandardMaterial emits `ALPHA_SCISSOR_THRESHOLD` for the scissor mode, not depth prepass.
- The old adapter generated mipmaps for each transparent layer, filtered each layer independently with linear+mipmap sampling, and drew the filtered layers at separate physical depths. This is a confirmed path where overlapping transparent edges receive separate filtering. It is not a measured claim that filtering alone caused the rejected look. The new path removes that source of layer-edge disagreement by composing registered source pixels first and filtering only the final character.
- The old adapter already avoided full catalog-color multiplication on metal/skin. It used a 30% catalog tint for base cloth and a condition-dependent darkening toward `363127` with maximum weight 0.64. The successor retains those presentation semantics in the composite; it does not globally sharpen, saturate, change lighting or modify frozen terrain.
- Strict source-alpha measurement (`a == 255` among `a > 0`) found **487,413 / 506,980 = 96.14048%** opaque pixels in the old foundation and **569,175 / 573,350 = 99.27182%** in the new foundation. Both have transparent corners. This is a foundation-only, exact-255 measurement, distinct from any earlier near-opaque/whole-set metric. It does **not** support broad accidental body translucency as the main cause. Edge quality, paint values and perceived blandness still require visual judgment.
- The original inventory/board code is a separate procedural drawing path; `_draw_equipped_soldier` prefers `appearance` when supplied. It cannot serve as a source for this adapter's actual-equipment authority or an exact shared painted preview. It is unchanged.

**Certainty:** code paths and source-alpha measurements are established. A single root cause for subjective washed-out/boring artwork is **not** established. No screenshot, native GPU rendering, art approval, gameplay usability or performance claim follows from these headless checks.

**Important remaining color boundary:** shared `Texture2D` identity alone does not guarantee identical final screen RGB between 3D and 2D. The bounded sprite-only correction below now compensates the audited 3D RGB path. This is source/math/resource evidence, not native pixel or visual acceptance. The environment and frozen terrain remain unchanged.

## Art and authoritative selection

All production layers load exclusively from `res://sprite_study/assets/characters/`. There is no old-character fallback and no runtime-generated fixture. Raw source PNG bytes are decoded to straight RGBA8; there is no import-time compression/resizing dependency. Source-project execution is qualified; exports must explicitly retain the source PNGs and are not qualified here.

- Canvas: **1024 × 1536**; foot pixel **(512,1490)**; pixel size **0.00134**.
- Bare foundation always exists. `foundation_helmet` is selected only when the inherited resolver selected a supported painted shell; removing it restores the exact bare source. An omitted unsupported helmet does not suppress bare hair.
- Authored body families: quilt, mail, brigandine. Supported shell families: nasal, kettle.
- Exact supported weapon definitions: **sword, axe, spear, bow**, with the corresponding conditional original-hand `grip_*`. Bow/spear are static carry depictions, not firing/thrust animation.
- Exact supported shield definitions: **shield** (kite painting) and **round_shield**. The inherited resolver still removes broken shields and honors the combat shield flag.
- Other body/head families, weapon variants (including greatsword, greataxe, thrown items, shortbow and heavy spear), buckler, unknown definitions, and inherited unknown-family fallbacks are omitted with their literal mechanical identities retained. A same-family mechanics result is not permission to present a different weapon design. There are no silent broad-family visual proxies.
- The published art manifest says the body paintings are **complete outfits**: quilt must not underlay mail/brigandine; mail must not underlay brigandine. The highest supported actual outfit suppresses lower outfit **paint only**. All physical parts, conditions, IDs and priorities remain in `layer_signature`, with `visible=false`, `suppressed_by` and `visibility_reason` on covered layers. Removing the outer outfit exposes the actual retained inner outfit. Unsupported outer equipment does not invent a substitute outfit.
- Wear affects that layer's RGB only, never alpha. Broken armor remains equipped and drawn; broken shields vanish by the inherited rule. Explicit empty combat weapon wins over stale `arms.weapon`; grips cannot survive weapon removal.

Logical paint order is foundation, selected body outfit, shell, weapon, conditional grip, shield. The actual source-over operation is performed on RGBA8 illustration pixels, not a physically linear-light lighting simulation. A lone foundation is copied exactly, including hidden RGB. Small RGBA8 blend rounding is tested separately from exact bare-source equality.

## Diagnostics and failure behavior

`layer_signature()` returns a deep copy with real definition, item identity, resolver family, asset, asset root, priority, original catalog color, effective tint, condition, maximum, broken, painted, visible, fallback reason and ordinary-clothing state. Conditional grips are included, not hidden extra geometry.

`render_diagnostics()` returns `ok`, `errors`, per-asset `asset_errors`, `source_kind`, canvas/foot/pixel-size metadata, the actual selected paint stack and build count. Missing/undecodable selected sources, wrong canvas, empty layers, absent transparency or nontransparent corners refuse the **whole** composite. The previous sprite is removed, preview is null, ground blob is hidden, every signature entry becomes nonvisible, and source-PNG mode reports a named engine error on changed failure. No stale equipment or partial bare fallback is displayed. Unsupported art omissions are intentionally different from a missing required supported asset.

The test-only `install_test_images()` hook is explicit and per-compositor. It never falls back to the filesystem when a fixture is absent; `source_kind` reports `synthetic-test-fixtures`. Production actors use a shared source/composite cache. Tests allocate separate compositors when injecting fixtures.

## Cache, depth and picking

The selected asset/priority/tint stack is the cache key, not mutable HP/AP/selection or physical item IDs. A successful stack produces one immutable `ImageTexture`; repeated refreshes reuse it. An LRU retains at most **16** composites, while consumers holding an evicted texture retain a valid resource. Shared raw source images are loaded once per process and assumed immutable; restart after art replacement. Missing results are not cached. Camera-facing `_process` changes basis only, not pixels.

Each refresh replaces the single Sprite3D node even on a texture-cache hit. This intentionally preserves the inherited picker's per-node cached-alpha lifetime. Depth testing and opaque prepass remain enabled, modulation is white, shading/cast shadow are off, and illustration filtering is linear with mipmaps, not pixel-art nearest. Actual camera-facing bounds place the source foot at local zero, including transformed/moved roots. The unchanged picker intersects the Sprite3D plane and reads its final composite alpha, rejects transparent margins, and chooses nearest opaque depth.

## Bounded source-color identity correction

`color_identity.gdshader` is a `ShaderMaterial` override on **only** `Illustration/Composite`. It samples the exact `Texture2D` returned by `preview_texture()`; the compositor, image bytes, menu, assets, ground shadow, world, lights, terrain and camera are not modified. There is no sharpen/saturation/contrast knob, brightness multiplier, nearest filtering, 2D overlay, or depth bypass.

### Exact audited engine path

Engine/tag: **4.4.1.stable.official.49a5bc7b6**, upstream full commit **49a5bc7b616bd04689a2c89e89bda41f50241464**. The tag was resolved with `git ls-remote`, not inferred from a current branch.

- [RGBA8 texture storage](https://github.com/godotengine/godot/blob/49a5bc7b616bd04689a2c89e89bda41f50241464/drivers/gles3/storage/texture_storage.cpp#L377-L382) uses `GL_RGBA8`. The sampler retains the `source_color` declaration. In this Compatibility path, the decisive input decoding is **after the user fragment**, not an assumed IEC sRGB texture decode.
- [Shader color decoding](https://github.com/godotengine/godot/blob/49a5bc7b616bd04689a2c89e89bda41f50241464/drivers/gles3/shaders/scene.glsl#L1963-L1967) applies `srgb_to_linear(ALBEDO)` even before the `!MODE_UNSHADED` branch. [Unshaded output](https://github.com/godotengine/godot/blob/49a5bc7b616bd04689a2c89e89bda41f50241464/drivers/gles3/shaders/scene.glsl#L2281-L2306) then applies exposure, white-normalized Filmic and `linear_to_srgb`.
- [Exact approximation and Filmic constants](https://github.com/godotengine/godot/blob/49a5bc7b616bd04689a2c89e89bda41f50241464/drivers/gles3/shaders/tonemap_inc.glsl#L13-L54) differ from ideal IEC sRGB at the dark end. Replacing them with textbook sRGB, or inverting Filmic alone, would not establish identity.
- [Environment defaults](https://github.com/godotengine/godot/blob/49a5bc7b616bd04689a2c89e89bda41f50241464/scene/resources/environment.h#L115-L119) are exposure **1.0**, white **1.0**. [Compatibility uniforms](https://github.com/godotengine/godot/blob/49a5bc7b616bd04689a2c89e89bda41f50241464/drivers/gles3/rasterizer_scene_gles3.cpp#L2339-L2352) use those actual environment values. The focused test constructs the unchanged battlefield setup and verifies Filmic, both defaults, fog/glow/adjustments off, SDR and unit 3D scale.
- [Post-processing branch selection](https://github.com/godotengine/godot/blob/49a5bc7b616bd04689a2c89e89bda41f50241464/drivers/gles3/rasterizer_scene_gles3.cpp#L2232-L2249) changes when 3D scaling or glow is enabled; adjustments also select post at lines 2341–2343. Those paths are **outside this correction's qualification**.

For a sampled encoded channel `s` in `[0,1]`, the current unshaded output is:

```text
P(x) = x * (x * (0.305306011*x + 0.682171111) + 0.012522878)
U(x) = (x*(0.88*x + 0.06) + 0.002) / (x*(0.88*x + 0.60) + 0.06) - 0.01/0.30
F(x) = U(x) / U(1)                 # exposure bias 2 baked into A=0.88, B=0.60
O(x) = max(1.055*x^0.416666667 - 0.055, 0)
screen(s) = O(F(1.0 * P(s)))       # actual exposure=1, white=1
```

The inverse material outputs `ALBEDO = P^-1(F^-1(O^-1(s)))`, independently per RGB channel. `O^-1` uses the upstream exponent, `F^-1` is the positive quadratic root (rationalized for dark-channel stability), and six bounded Newton iterations invert the strictly increasing `P` on `[0,1]`. Its derivative is always positive there. Exact black selects the zero preimage of the output clamp; positive dark channels invert the nonclamped branch. No HDR/out-of-domain input is claimed: the shared sampled image is RGBA8, and the tested white/exposure keep the required albedo in `[0,1]`.

This removes a deterministic second display transformation of already-painted color; it does not add detail to the art. For example the audited **uncorrected** pipeline sends encoded `0.5` to approximately `0.634821479`, while the inverse supplies about `0.388613432` to recover `0.5`. This is not a global contrast increase: near-black behavior needs the opposite correction because of the renderer's approximate transfer functions.

### Alpha, geometry and filtering

The shader leaves `ALPHA = source.a` exactly, retaining straight-alpha `blend_mix`, `depth_prepass_alpha`, double-sided drawing and ordinary depth tests. It does **not** write `ALPHA_SCISSOR_THRESHOLD`: [upstream opaque-prepass handling](https://github.com/godotengine/godot/blob/49a5bc7b616bd04689a2c89e89bda41f50241464/drivers/gles3/shaders/scene.glsl#L1895-L1919) differs from scissor mode. The original CPU pick cutoff of 0.12 remains a picker property, not a new shader discard. The real original picker suites remain unchanged.

There is no vertex function or shader billboard: `prototype/character.gd` already sets `Illustration.global_basis` from the camera, and the actual Sprite3D plane/UV/foot bounds remain authoritative. The sampler explicitly keeps linear mipmapped filtering, sampled **before** inversion, with repeat disabled. No nearest or mip-bias change is justified by this source finding. Different 2D/3D screen footprints, mip levels, subpixel positions and backgrounds can still produce different final edge pixels; this correction does not promise screenshot-wide byte equality.

This is deliberately **not a general-purpose material**. Engine version, renderer, environment mode/exposure/white, fog, glow, adjustments or viewport scaling changes require requalification; there is no runtime environment rewrite or automatic adaptation. Native shader compilation, GPU precision, alpha blending/prepass behavior, overlap/terrain occlusion, camera motion, tactical zooms, performance and human clarity/color approval remain required before calling it visually accepted.

### Executed focused proof (private/headless only)

Evidence root: `/home/quatro/.hermes/cache/scratch/sprite-color-f85moxxa/`. All runs use the exact engine above, a private project copy, isolated HOME/XDG and cleared DISPLAY/WAYLAND_DISPLAY, with an in-engine 25-second watchdog and a 65-second subprocess bound. No GUI, staging or commit occurred.

- `01-red-shader-missing.log`: expected RED, missing material shader, exit 1.
- `02-math-green-binding-red.log`: scalar inverse passed; expected missing-binding RED. A separate test setup mistake compared float32 0.12 to a double exactly; corrected to `is_equal_approx`, without changing the picker threshold. That extra failure is not claimed as a product defect.
- `03-color-green.log`: **572 checks, 0 failures**, exit 0. Executes the **actual scalar production shader statements** through a deliberately narrow GLSL-to-GDScript test translation, then checks the independent exact upstream forward curve. All 256 byte-channel values plus six fractional dark/highlight values roundtrip within **0.00001**; chromatic RGB witnesses, finite `[0,1]` albedo, alpha-source contracts, shared texture identity, material binding and live native-API environment/camera-plane properties pass. The log's `0.0` maximum is Godot's formatted small-number output, **not a claim of zero floating-point error**. This is CPU arithmetic and source/resource evidence, **not GPU execution**.
- `04-character-fixtures.log` and `05-character-real.log`: each **198 checks, 0 failures**, exit 0, including unchanged real-alpha camera geometry/picking and the real delivered PNG cohort. Final logs have no script/engine errors or warnings.

Reproduce the focused gate in a private copy with the same isolated state as the character gates:

```sh
"$GODOT_BIN" --headless --single-threaded-scene --path "$PRIVATE_PROJECT" \
  --script res://sprite_study/tests/color_test.gd
```

Native owner: inspect the same actual kit in menu and battle at minimum/default/maximum tactical zoom; verify no shader errors, unchanged overlap/terrain depth, opaque torso/head/foot picking, transparent margins and edge halos. Do not accept increased darkness alone as evidence of improved accuracy: compare recognizable sampled paint regions against the unchanged menu/source. No native visual success is claimed here.

## Executed verification

Godot: `/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64`, reported **4.4.1.stable.official.49a5bc7b6**. Only headless processes were launched, with a private copied project and isolated HOME/XDG under:

`/home/quatro/.hermes/cache/scratch/sprite-compositor-b492ng80/`

The suite has a 25-second in-engine watchdog; each subprocess also had a 65-second hard timeout with owned-child retirement. The private source tree, logs and receipts remain there; this scratch path is ephemeral, not portable evidence storage.

- `26-fixture-final.log`: **198 checks, 0 failures**, exit 0; explicitly synthetic source-pixel cohort.
- `27-real-final.log`: **198 checks, 0 failures**, exit 0; actual delivered source-PNG positive path. Negative/malformed-source and analytical blend-oracle cases remain explicitly synthetic inside this cohort.
- Both final logs contain no script/engine errors or warnings. `real-asset-manifest-final.json` binds all **17** delivered PNGs copied for this run; `final-source-manifest.json` binds the three implementation/test files.
- Vertical RED/GREEN receipts cover shared texture, actual equipment pixels, wear, full RGBA preservation, missing/invalid assets, bounded shared caching, complete-outfit masking and explicit design coverage. Removal, read-only authority and native-API geometry/picking were also exercised as retained regressions. The initial compiler-name/type errors, deferred-bounds test setup issue, and an incorrect test assumption about float-to-RGBA8 rounding remain in prior failed logs; they are not called product REDs or final passes.
- Tested actual `prototype/battlefield.gd.pick_unit` with upper/middle/lower opaque source witnesses at three orthographic sizes and perspective projection, translated/scaled actors, overlapping foreground/rear actors, transparent margins and texture replacement. This is **headless native-API picking geometry**, not external native mouse acceptance.
- Actual scenario snapshots/catalog bytes stay unchanged across render/selection refreshes. Protected tracked `src`, `data`, legacy `tests`, `assets`, `prototype`, and `visual_slice` match base `d210199` in the final Git check. Nothing was staged or committed.

Reproduce in a private copy with separate HOME/XDG (do not point a test at a live user's project/state):

```sh
"$GODOT_BIN" --headless --single-threaded-scene --path "$PRIVATE_PROJECT" \
  --script res://sprite_study/tests/character_test.gd
"$GODOT_BIN" --headless --single-threaded-scene --path "$PRIVATE_PROJECT" \
  --script res://sprite_study/tests/character_test.gd -- --real-assets
```

Require exit 0, the explicit `SPRITE_STUDY_CHARACTER_TEST` zero-failure marker, and no script/engine errors. Real art arrived during this worker's run and was exercised; it is no longer merely pending fixture integration. Native visual acceptance, final packaged/export handling and whole-scene GUI verification remain the parent/UI owner's gates.
