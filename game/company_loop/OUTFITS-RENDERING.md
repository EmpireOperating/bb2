# Full-outfit rendering: legs/boots stage

## Scope and ownership

This stage implements existing body armor owning matching legs and boots. It adds no equipment slots, items, protection, rules, anatomy, camera changes, terrain changes, or autonomous motion. Gloves are **not implemented** here; the authorized glove follow-up and final native acceptance belong to the parent.

Only these repository files are owned by this runtime lane:

- `company_loop/character.gd`
- `company_loop/compositor.gd`
- `company_loop/tests/outfit_test.gd`
- `company_loop/OUTFITS-RENDERING.md`

All original asset trees, the accepted resolver/shader/picker and motion methods remain untouched. Art sources, recipes, PNGs and offline verification are the separate art lane. No GUI, source-tree import, staging or commit was performed by this lane.

## Resolver and composition

`Character._add_layer()` receives the original inherited resolver's decisions. Only supported painted body sources are redirected:

| Accepted resolved family | Required full outfit |
| --- | --- |
| `body_quilt` | `company_loop/outfits/characters/outfit_quilt.png` |
| `body_mail` | `company_loop/outfits/characters/outfit_mail.png` |
| `body_brigandine` | `company_loop/outfits/characters/outfit_brigandine.png` |

The inherited sprite-study refresh still suppresses covered paintings and retains their actual item/definition/condition diagnostics. The company compositor receives that **already-visible stack**; its owner is outer, otherwise mail, otherwise base. It never scans `armor_parts`, appearance, aggregate protection or inventory independently. Unsupported first-slot equipment continues to win duplicate-slot admission while omitting its paint, so a later supported duplicate cannot create a phantom outfit. Broken-but-equipped supported armor remains worn and owns the complete outfit.

`foundation_keep_mask.png` ALPHA multiplies only the selected foundation's ALPHA, with RGBA8 rounding. Mask RGB is ignored. Original cached foundation RGB/alpha and source images are never mutated. Bare restoration uses the exact original straight RGBA, including hidden RGB. Mask validation is separate from ordinary painted-source validation: correct decode, 1024x1536, RGBA8, no mipmaps, and both retained and suppressed alpha are required; opaque corners are valid for auxiliary masks. Missing/invalid selected sources refuse the whole composite, clear the sprite/shadow, and identify the exact failed source. Failure results are not cached.

Source-over, current armor RGB wear tint, white sprite modulation, shader, mipmap generation, depth, pixel scale `0.00134`, canvas `1024x1536` and foot `(512,1490)` retain their accepted behavior. Quilt catalog color and each owning armor's condition also tint its own legs/boots. Helmet-context foundations still originate only from the inherited actual painted shell callback.

The art-owned seam is documented in `outfits/recipe.json`: all rows above y700 are exact; lower paint underlaps per-column accepted hems. Opaque original upper-equipment pixels remain exact, including the hem. Semitransparent hem pixels may composite over new lower paint rather than old trousers. The runtime contains **no anatomy cutoff**. Runtime tests independently compare the sealed upper and every original opaque armor pixel, not a blanket equality assertion over the intentionally changed lower body.

## Existing observer fields

No observer or UI changes are needed. `layer_signature().foundation` adds:

- `outfit_owner`: `{slot, item, definition, asset}` for the real selected armor; `{}` when no supported outfit is active. `asset` includes `.png`.
- `keep_mask`: `foundation_keep_mask.png` or empty string.
- `keep_mask_root`: `res://company_loop/outfits/characters/` or empty string.
- `keep_mask_error`: exact auxiliary failure text or empty string.

Supported body signatures retain physical item/definition/condition/maximum/broken/color and expose the actual full-outfit `asset`, `art_family`, `asset_root`, plus `owns_lower_body`. Covered armor retains `visible=false` and the inherited `suppressed_by`. A blocked composite retains planned ownership but every painted layer becomes nonvisible/`composite_blocked`.

`render_diagnostics()` adds the same copied `outfit_owner` dictionary and `cache_key`. `cache_key` is **exactly** `JSON.stringify(stack)` of the diagnostic contextual stack: actual foundation/helmet identity, outfit asset, priorities, inherited tints, and foundation `keep_mask` are all explicit. Physical IDs do not fragment pixel-identical textures; physical ownership remains in the signatures. Shared caches retain at most 16 final textures and the finite source inventory (at most 25 accepted/identity/outfit/mask images). No separate camp renderer or per-frame composition exists. Asset sources are immutable for a process lifetime, as before; hot-reloading edited PNGs is not implemented.

## Real engine evidence

All attempts use the retained Godot 4.4.1 executable, a fresh project copy and private HOME/XDG/TMPDIR under `/home/quatro/.hermes/cache/scratch`. The source worktree has no `.godot` directory. Logs, command receipts, engine SHA-256 and copied-source SHA-256 inventories are under:

`/home/quatro/games/battle-brothers-2-full-outfits-evidence/runtime/`

Retained progression:

- `red-owned-valid`: **72 checks, 34 failures**, expected missing outfit mapping/owner/lower pixels.
- `green-owned`: **72 checks, 0 failures**.
- `red-mask-guards`: **126 checks, 21 failures**. Twenty were missing validation assertions. One test incorrectly assumed Godot encodes floating 0.5 as byte128; its oracle was corrected to use the actual encoded source alpha rather than weakening multiplication.
- `green-mask-guards`: **126 checks, 0 failures**.
- `expanded-fixture`: retained test-setup failures from a face rectangle that included real armor beginning at y201. The corrected face witness is above that armor, while upper preservation remains separately tested.
- `final-source`: explicit fixture cohort **531 checks, 0 failures**, and production PNG cohort **531 checks, 0 failures**. Both finish with `COMPANY_OUTFIT_TEST: 531 checks, 0 failures` and no engine warnings/errors.
- `final-source`: four separate production-decoder negative probes (missing/undecodable mail outfit and mask), each **8 checks, 0 failures**. Those raw logs intentionally contain decoder/refusal errors; they are not ordinary clean-output positive cohorts. Only private-copy files were replaced and restored.

Coverage includes real Session-owned UID admission/equip/remove/kit/stash transfer, the requested hero mail→linen→none→mail/outer→mail journey, mixed/duplicate/unsupported resolver precedence, real CampPanel automatic refresh, exact camp TextureRect/field Sprite3D Texture2D identity, actual Campaign deployment, three identities with both helmet contexts, exact bare restoration, lower-leg and boot pixel distinction, current wear/broken retention, immutable foundation caches, exact contextual cache diagnostics, and camera-facing alpha picking of real opaque boots and transparent foot-row margins. Orthographic/perspective and three zoom settings are exercised during the unchanged bounded lunge; simulation snapshots/RNG/commands remain unchanged. Existing motion tests also still run in the untouched company-character suite.

Run the default production test only inside an imported private copy:

```text
<Godot-4.4.1> --headless --single-threaded-scene --path <private-project> --script res://company_loop/tests/outfit_test.gd
```

Append `-- --fixture-assets` only for the explicit early synthetic-lower cohort. Default tests never silently substitute fixtures for missing production art. The suite also injects labelled defect fixtures internally to test invalid-source guards. `--required-source-failure=<asset>` is a harness-only negative entry point requiring the named source to have been removed/corrupted externally in a private copy.

## Untouched predecessor tests: obsolete expectations vs regressions

Final-source results:

- Sprite-study character: **198 checks, 0 failures**; its previously documented filesystem image-loading warning remains unchanged.
- Company camp panel: **204 checks, 0 failures**.
- Unedited company character: **214 checks, 22 failures**; **192 assertions pass**, including all existing identity/removal, supported helmet, missing identity, motion, geometry/picking and read-only assertions.

Exact obsolete failure categories in `company_loop/tests/character_test.gd`:

1. Line121: nine lower-body-inclusive byte equalities (three outfits × three identities). Those old trousers/boots must now change. The new suite instead requires sealed upper/face/hands and every opaque original armor pixel to remain exact, plus distinct equipment-driven legs and boots.
2. Line122: three old whole-composite equalities for linen/mail/brigandine. Exact bare and all non-body gear remain preserved.
3. Line126: nine complete nonfoundation diagnostic equalities. Full outfit asset names/root and explicit lower-body ownership are intentional new diagnostics; physical identity/condition/visibility are retained and separately checked.
4. Line164: one obsolete `<=21` source-cache cap. The four additive full-outfit/mask inputs extend the finite inventory to at most25; the final composite cache still remains capped at16.

Do not report that old suite as green or edit it silently. The parent owns aggregate-runner reconciliation. No old test was edited by this lane. Parent changes to `run_checks.py`/`tests/check_runner_test.py` are separate from this runtime work.

## Glove follow-up seams (not implementation)

Use the same resolved visible outfit owner and its physical condition; do not add raw-equipment scans, slots or stats. The company compositor's contextual stack is the suitable bounded place for an outfit-owned glove source choice and any source-bound hand keep mask. Add those choices to the exact cache key and diagnostics before delegating final native acceptance.

Beware the inherited `sprite_study/character.gd::_add_layer()` weapon branch: it appends `weapon_grip` / `grip_<family>` at priority21, after weapon20 and before shield22. Those grip images are original bare-skin foreground. They must not reappear above a full glove. The visible owning outfit can be resolved only after inherited collection/suppression, so don't simply infer gloves when the foundation callback fires or blindly change all grip depth. Qualify actual sword/axe/spear/bow plus shield-held stacks: glove paint behind weapons where appropriate, hand/weapon contacts retained, and original grip pixels restored exactly with the final outfit removed. The original hand/upper preservation gates in this stage remain intact; any authorized glove-stage exception must be narrowly source-bound and retain bare restoration. No glove-support claim is made by this stage.

Headless pixel/geometry proof is not GPU appearance or external-pointer/native acceptance. Native combined legs/boots/gloves acceptance, packaging and final review remain parent-owned.
