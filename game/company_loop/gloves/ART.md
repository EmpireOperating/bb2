# Outfit-owned genuine painted gloves

## Delivered interface

All four runtime PNGs are **1024×1536 RGBA**, fixed foot **(512,1490)**:

- `characters/glove_pair_quilt.png`: full tan leather, seams, reinforced finger planes.
- `characters/glove_pair_mail.png`: dark leather fingers/palms, genuine interlinked steel mail backs/cuffs.
- `characters/glove_pair_brigandine.png`: oxblood leather, steel knuckle/finger plates and riveted reinforcement.
- `characters/hand_keep_mask.png`: auxiliary **alpha** keep mask; RGB ignored.

No equipment definitions, stats or separate glove slots were added. These are
outfit-owned layers selected by the already-resolved visible body owner.
Original foundation/equipment and completed full-outfit sources are unchanged.
No GUI, runtime integration edits, staging or commits were performed by this lane.

## Frozen geometry and faithful source extraction

`recipe.json` records inspected hand/cuff contours on the actual original
foundation. Fourfold contour rasterization followed by a 128 threshold establishes
binary ownership; the exported glove alpha inside that ownership is **exactly the
original foundation alpha**, not the generated person's anatomy. Both new hands,
finger support, centers, outer silhouettes and original weapon registration remain
in place. The glove/cuff footprint does not extend beyond the original hand/bracer
footprint. All original forearm paint beyond the cuffs remains unchanged.

The keep-mask suppresses only original nonzero-alpha paint inside that footprint.
It is independent from the existing lower-body keep-mask. Removing the owning
outfit/gloves bypasses both masks; the exact original straight RGBA, including
hidden RGB, returns. Tests cover ordinary and helmet foundations and all retained
identity variants. The figure's complete alpha silhouette is unchanged by gloves.

Genuine source pixels are extracted without scaling, warping, recoloring, generated
texture or adopting regenerated anatomy. **Small disclosed edge transport** fills
magenta source-to-frozen-contour gaps using the nearest actual non-magenta pixel of
the same generated painting. This is not pixel-exact extraction at those locations:

| Design | Transported edge pixels | Maximum source distance | Opaque direct-source RGB pixels |
|---|---:|---:|---:|
| Leather | 1009 | 8.9443 px | 42302 |
| Mail | 492 | 4.2427 px | 42810 |
| Reinforced | 382 | 3.6056 px | 42864 |

The initial 8px bound rejected eight leather lower-cuff pixels. The narrowly scoped
successor permits up to 12px **only at x>740,y>630**, the original shield-side lower
cuff; actual maximum is below 9px. Everywhere else the 8px cap remains. Original
alpha/geometry is never expanded. The deterministic nearest-source selector and
its exact source RGB are independently replayed in tests. No interpolated skin,
procedural glove paint, broad rectangle extraction or new hand anatomy is used.

## Image generation receipts

Exactly **3 configured image-edit calls**, no additional model repair call.
Provider `openai-codex`, model `gpt-image-2-medium`; requested/reported medium,
actual returned RGB **1024×1536**. Each primary reference is the exact accepted
registered foundation + complete full-outfit composite on magenta. Tests independently
recompose and compare those reference pixels. Full prompts and literal returned
fields, cached-original paths, retained master hashes and request IDs are in
`sources/generation-tool-receipts.json`.

- Leather: `5da57590-58c1-45d4-a86d-afd5d7a592bc`
- Mail: `b83e2e99-25e7-426b-bf0b-0d6a42ef6f08`
- Reinforced: `e9302877-a526-4830-a5c0-ab4d54595631`

Generated whole figures are retained as inert masters only. Only hands/cuffs enter
runtime layers. The original face, armor, legs and all other generated repainting
are discarded.

## Ordered contact contract

1. Apply existing lower keep-mask and new hand keep-mask independently to a copy
   of the chosen original foundation; draw the actual selected full outfit.
2. Draw corresponding whole glove pair at **19**, with the owning body's tint/wear.
3. Draw unchanged original weapon at **20**.
4. Replace, do not retain, the old bare-skin `grip_*` at **21**. Sample RGB from the
   same glove pair; alpha is `glove_alpha * original_grip_alpha / 255`.
5. Draw original shield at **22**.

`build_gloves.compose` and saved review images replay this physical stack with the
real original sword/axe/spear/bow and kite/round-shield PNGs. They do not substitute
whole-glove foregrounds. Exact opaque weapon pixels outside original grip support
and all opaque shield-face pixels remain unchanged. Deliberately restoring the
original skin grip produces a measurable failure for every supported weapon.
The runtime agent owns actual resolver/cache/fail-closed integration and wear.

## Reproduction and verified gates

From the worktree:

```sh
python3 company_loop/gloves/build_gloves.py
python3 company_loop/gloves/render_review.py
python3 company_loop/tests/glove_assets_test.py
python3 company_loop/gloves/verify_gloves.py --output /absolute/new-evidence-directory
```

The last complete receipt is:
`/home/quatro/games/battle-brothers-2-full-outfits-evidence/glove-art/verification-1/verification.json`.

- **8 real-source unittest tests pass**, plus the inherited source-art suite.
- Required-assets, protected-source validation and held-compositor RED→GREEN logs
  are retained. Additional pixel gates are backed by actual private corruption
  REDs and a restored full-suite GREEN, not described as independent pre-art TDD.
- Two actual complete builds and an independent copied-root rebuild match
  **76 files**: 4 runtime PNGs, 70 offline review PNGs, 2 manifests.
- **7 actual private corruption probes rejected:** source RGB, finger alpha,
  mask affecting face, immutable foundation, oversized cuff, missing PNG,
  undecodable PNG. Only copied evidence sources are mutated; all are restored.
- **546 immutable input files** remain byte-identical, including all 17 original
  registered character PNGs, original source paintings/recipes, current full
  outfits and lower keep-mask. Parallel runtime files are not sealed by this lane.
- Sources, builder, recipe, output hashes and exact extraction counts are bound in
  the manifest; verifier records its own source and test hashes.

## Reviewed evidence and limitations

`evidence/review/` includes 45 complete combinations (three designs × five weapon
states × three shield states), isolated source/extraction comparisons, light/dark
hand contacts, actual **400px menu** and **120/90px tactical** samples, plus exact
bare removal. Some exhaustive shield+two-handed combinations are diagnostic art
fixtures, **not statements of gameplay legality**.

All three hand-contact sheets were actually inspected: full fingers remain covered,
weapons stay registered and visible, shields stay in front, and neither background
revealed a rectangle, oversized new silhouette, floating cuff or old skin grip.
Representative actual-size menu/tactical sheets for each material were inspected.
The steel plates and tan/dark leather value differences remain readable; individual
mail rings, stitches and rivets disappear at 90/120px. Small leather cuff-edge
transport is an explicit source-fitting limit, not recovered hidden paint.

These are **offline PNG composites only**. They prove neither native GPU filtering,
lighting, camp/battle Texture2D sharing, picking, gameplay, worn/broken states nor
Save/Load. Parent/runtime lane must perform those gates. Fixed original clenched
pose only; no attack/drawn-bow animation or larger equipment catalogue is implied.
