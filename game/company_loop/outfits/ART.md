# Full-body outfit extensions — art lane

## Delivered

`characters/outfit_quilt.png`, `outfit_mail.png`, `outfit_brigandine.png`, and
`foundation_keep_mask.png` are 1024×1536 RGBA, foot anchor **(512,1490)**,
pixel size **0.00134**. Runtime consumes the keep mask's **alpha**, not RGB.

- **Cloth/quilt family:** newly painted oatmeal trousers with stitched cloth knee patches and simpler fitted brown boots. The accepted upper remains the existing linen-family visual, not a newly quilted jack.
- **Mail:** genuine newly painted interlinked steel chausses on both thighs, knees and shins, with dark leather boot/cuff construction. Not blue cloth or a recolor.
- **Brigandine:** oxblood riveted thigh defenses, steel knees and strapped shin defenses, reinforced oxblood boots and metal toes. No mechanical leg/boot slots or new protection stats.

Use exactly one complete outfit selected by the inherited visible body resolver:
`body/outer > body/mail > body/base`. This document does not implement another
resolver. Removing outer equipment must expose the next actual outfit; no supported
body equipment must bypass the keep mask and return the exact selected foundation.
Runtime integration, gameplay, and native visual acceptance belong to the parent/runtime lane.

## Frozen upper, anatomy, and joins

Every opaque pixel of each old accepted body layer is unchanged. The complete
straight-RGBA upper region **y<700** is also exact. Original face, hands, arms,
identity foundations, hair and helmet behavior are not regenerated or replaced.
The old upper's retained under-hem contact shadows are deliberately retained.
Only lower paint is extracted from the generated image edits.

The common suppression seam is derived from the actual immutable upper alpha
contours: per column, find the last upper pixel with alpha>32 at y>=700, subtract
an **8px underlap**, clamp to y>=700, and use the earliest boundary across the three
outfits. Foundation alpha is retained above that contour and suppressed below it.
Each new lower starts under its own original hem. This is an authored alpha mask;
the runtime must not hardcode a guessed horizontal anatomy boundary. All foundation
paint below y920 is suppressed, including obsolete boot edges. No old-boot underlay
is used to fill gaps.

The lower source legs remain unscaled, unwarped and unrecolored. Integer y registration
for the viewer-right lower island is cloth +3px, mail +1px, brigandine +2px; viewer-left
is unchanged. These align measured original alpha>200 sole extrema exactly at
left y1378 and right y1485, preserving the shared foot anchor. Toe/foot horizontal
extents differ by at most **3px**. This is not pixel-identical new boot geometry.
Generated upper/anatomy is retained only in inert source masters, never adopted.
Only chroma-edge RGB is unmatted; opaque interior lower paint is byte-exact to the
retained generated source after the recorded integer registration.

## Reproduce and verify

From this worktree:

```sh
python3 company_loop/outfits/build_outfits.py
python3 company_loop/tests/outfit_assets_test.py
python3 sprite_study/tests/asset_test.py
python3 company_loop/outfits/verify_outfits.py --output /absolute/new-evidence-directory
```

The verifier requires a **new** output directory, runs two real builds, compares all
17 emitted PNGs plus the manifest, builds again in an independent copied root,
runs both art suites, deliberately corrupts the private mask/upper/protected source
to verify refusal, restores them, and exercises Godot 4.4.1 native Image load/mask/blend
in an isolated headless project/home. It does not launch the GUI or edit runtime paths.
Native-vs-Pillow comparison explicitly allows alpha delta<=1 and black/white matte
channel delta<=2 for integer image-compositing rounding; it does not assert raw RGB
identity at low alpha. The same installed font/Pillow/NumPy stack is used across roots.

`prepare_references.py` was the one-time baseline source seal/reference preparation.
It intentionally refuses to overwrite the existing seal; do not run it for rebuilds.
`protected-inputs.json` binds **345** immutable source, asset, recipe and rules files.

## Source receipts and bounded generation

Exactly **3** image-edit calls, all configured provider `openai-codex`, model
`gpt-image-2-medium`; requested/reported medium, actual RGB 1024×1536. No repair call.
Every call used the exact accepted foundation+corresponding upper composite as its
primary reference. The actual returned fields and full prompts are retained in
`sources/generation-tool-receipts.json`; masters are retained byte-for-byte.

| Outfit | Request ID |
|---|---|
| Cloth | `68a46bae-6d28-4e45-84ef-ec75ab283da1` |
| Mail | `66d796af-1753-489f-98bc-40e1a63d911b` |
| Brigandine | `fd2ead73-7c2a-4de4-8b4f-ed39cf1eb70e` |

## Verified result

The final recorded run is
`/home/quatro/games/battle-brothers-2-full-outfits-evidence/art/verification-2/verification.json`.
Six outfit tests and four inherited asset tests pass. Two actual rebuilds and the
independent cold-root build match **18 files** (17 PNGs plus manifest) byte-for-byte.
All three deliberate corruptions are rejected; all 345 protected inputs remain
unchanged. Godot native Image composites differ from the independent Pillow
reference by alpha<=1 and black/white matte channel error below 1.85/255.

## Evidence and honest limits

- `actual-menu-400.png`: real 400px canvas height on light/dark.
- `actual-tactical-120-90.png`: real 120/90px samples, not enlargements.
- `reference-source-delivery.png`: accepted composite, raw edit, extracted final.
- `isolated-layers-and-mask.png`: retained upper/new lower/full outfit and alpha mask.
- `hem-and-boot-joins.png`: native-pixel hem crops on light/dark and enlarged boot review.
- `identity-and-removal.png`: three existing identities, three outfits and exact ordinary-clothes restoration; tests also cover helmet-context foundations.
- RED logs precede the production builder. The first build caught a one-pixel cloth
  sole error; its failure remains recorded and the translation was corrected.

Visual inspection found complete joins, no old brown boot fringe, and distinct
light cloth / cool mail / red-and-steel heavy protection. Fine mail rings/rivets
collapse at 90/120px, especially mail on dark ground; broad values and materials
remain legible. All sheets are **offline**; headless Image math is not rendered GPU,
lighting, mipmapping, native menu/field or gameplay acceptance. Fixed pose only,
no animation or expanded equipment catalogue. No stage/commit/publish action.

**Gloves are parent-owned FOLLOW-UP pending.** This lane leaves the frozen original
fists unchanged; hand-preservation proof is not glove fit or glove-removal proof.
No glove generation or glove art is included in this lane or its attempt budget.
