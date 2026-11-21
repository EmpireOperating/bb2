# Braced sprite study — art handoff

## Delivered / scope

17 transparent RGBA layers under `assets/characters/`, all **1024×1536**, foot anchor **(512,1490)**, pixel size **0.00134**. All three hero kits use the same accepted original face, fists, trousers, boots and braced pose. Terrain, rules, original `visual_slice` art, runtime selection, launchers and `project.godot` were not edited by the art lane. This is offline art evidence, **not native renderer/gameplay acceptance**.

The cold blue mail, silver pointed nasal helm, oxblood brigandine, wide kettle brim, bright broad sword/axe and large contrasting shields are new original generated paint, not contrast-filtered legacy equipment. Review at actual 90/120-pixel canvas heights shows clearly distinct blue/red material groups, helmet silhouettes and held-item shapes. Ring/rivet detail necessarily collapses at tactical scale; silhouettes and large values carry the design.

## Runtime contract

| Slot | Supported files / meaning |
|---|---|
| Base | `foundation.png`: ordinary dark brown clothes and full original hair. `foundation_helmet.png`: same source with crown suppression only; **use only with a supported actual helmet**. |
| Body | `body_quilt.png`: lighter linen-family cloth, derived from accepted base folds; not a separately generated padded-jack design. `body_mail.png`: blue-steel mail and its belt. `body_brigandine.png`: oxblood riveted armor and its belt. |
| Head | `head_nasal.png`, `head_kettle.png` — independently removable, no baked second face. |
| Main hand | `weapon_sword.png`, `weapon_axe.png`, `weapon_spear.png`, `weapon_bow.png`. All hold at original viewer-left/anatomical-right fist. |
| Original fingers | `grip_sword.png`, `grip_axe.png`, `grip_spear.png`, `grip_bow.png`: exact accepted base pixels supported by the paired weapon. Never use with another family. |
| Offhand | `shield_kite.png`, `shield_round.png`: face in front of original viewer-right/anatomical-left fist; do not paste that fist over shield faces. |

Compose: chosen foundation → chosen body → chosen head → weapon → paired grip → shield. **Choose one body**, rather than underlaying `body_quilt` beneath both armors. Helmet removal must switch back to `foundation` as well as removing the helmet. Bare-head linen/sword has no shield. No equipment means ordinary `foundation`, not an automatic armor layer. Authoritative equipment-to-family selection is the runtime owner's responsibility.

Bow and spear are bonus **static one-hand carry** presentations, not bow-draw, two-handed thrust or animation proofs. Bow was mirrored as a whole object so its string faces toward the body; no original anatomy was mirrored. Weapon transformations are whole-object scale/rotation/registration, never separate blade/guard/pommel rearrangement. Shield anchors represent the hidden rear grip, not forced boss-to-hand correspondence.

Unsupported families are explicit in `assets/asset-manifest.json` / `extraction-recipe.json`: plate/lamellar/scale/independent leather bodies; fullhelm/hood/coif heads; dagger/mace/hammer/crossbow/flail/twohand_sword/poleaxe/thrown weapons; buckler/tower shields. Any other unlisted family is also unsupported. Contract: retain mechanics, omit unavailable slot art, emit `unsupported_art:<slot>:<family>`; never silently substitute sword/mail. No placeholder PNGs were emitted for unsupported families.

## Reproduce

From this worktree:

```sh
python3 sprite_study/assets/build_layers.py
python3 sprite_study/tests/asset_test.py
```

Tested interpreter: Python 3.11.16, Pillow 12.3.0, NumPy 2.4.3. Evidence typography uses the verified installed `/usr/share/fonts/ttf-ia-writer/iAWriterQuattroS-Regular.ttf`; another host needs that font or an explicitly selected typography adaptation. The builder resolves input/output relative to itself and performs **no network calls**. Generation is not deterministic; retained generated masters make extraction/recomposition deterministic.

`assets/extraction-recipe.json` records new-pose contour masks, original/donor wrist exclusions, crown mask, atlas crop ownership and whole-item transforms. `assets/build_layers.py` keys the magenta backdrop, only unmattes chroma-edge RGB, preserves accepted interior pixels, and writes layers, labeled proofs and hashes. Mask feather is 0.45 source pixels; grip masks are hard-selected exact original RGBA. Ordinary linen uses a disclosed cloth-only color treatment of the new base; armor and objects retain newly generated paint. No procedural old-armor repaint or global sharpening was used.

## Sources and receipts

Parent-owned `assets/sources/base-master.png` and `base-provenance.json` remain unchanged. Base SHA-256: `7ac84c8821b4c9b2ff5af232b5e45e318daf3c9ceb30c9653ef083dd81ea6c52`.

Exactly **three** equipment-generation calls used the exact accepted base as input, all provider `openai-codex`, model `gpt-image-2-medium`:

| Retained master | Request ID | Requested / reported quality | Actual decoded canvas |
|---|---|---|---|
| `mail-master.png` | `a396c8ce-feee-4ac4-9343-615246674adc` | medium / medium | 1024×1536 |
| `brigandine-master.png` | `d1d77b4d-32c3-420a-8589-e8910e317d8d` | medium / medium | 1024×1536 |
| `equipment-master.png` | `0a5317ca-b5ef-4ec0-8305-940f036b294f` | medium / **low** | 1536×1024 |

Each master has a `*-provenance.json`; `sources/generation-tool-receipts.json` retains complete prompts and returned fields, including the distinction between top-level quality and reported quality. All originals are retained byte-for-byte. Generated faces/hands are source context only and are not adopted as anatomy.

## Verification and review

- `tests/asset_test.py`: **4 tests PASS**, covering actual source pixels, dimensions, transparency/bounds, independent equipment ownership, face/fists/legs/boots, exact paired-grip pixels, source hash, material distinction, manifest hashes and crown/wrist defect regressions.
- Real RED evidence precedes foundation and equipment implementation. Enlarged inspection caught an interior scalp gap and generated wrist crescent; both have retained RED→GREEN logs and repaired source-bound masks.
- `assets/evidence/reproducibility.json`: same-root rebuild and independent cold-copy rebuild match **28 emitted files byte-for-byte**: 17 layers, 10 current proof PNGs and manifest. All 17 layers independently pass shape/alpha/boundary checks. A deliberately corrupted grip in the disposable copy is correctly rejected; original outputs remain intact.
- `assets/evidence/offline-readability-sheet.png`: six labeled full-body combinations at 430px menu height plus **actual 90px and 120px** canvas heights on light/dark grounds. The images are not enlarged substitutes for the tactical samples.
- `assets/evidence/removal-and-joins-final.png`: current corrected helmet removal, face/scalp and both armor wrist joins; full accepted hair returns.
- `assets/evidence/offline-joins.png` and `isolated-layers.png`: enlarged grasp/helmet/cuff checks and independent transparent slot ownership.
- `rejected-crown-join.png` is explicitly historical failed evidence, not a current output. Sources/evidence directories have `.gdignore` markers.

## Known limits

Fixed-pose cutouts, not skeletal art or animation. Static grasps retain the original painted clenched fists; the closed hand naturally hides most handle paint. Some original cloth/cuff underlap remains at source-fit boundaries rather than adopting regenerated skin. Linen is a base-derived light-cloth visual, not new quilt construction. Cold-copy reproducibility was exercised on the same machine/font stack, not a separate OS. No native lighting, depth, minification, clicking, mechanical item selection or terrain claims are made by this lane. Runtime review remains with its owner.
