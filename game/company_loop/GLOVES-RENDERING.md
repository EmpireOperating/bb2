# Outfit-owned gloves: runtime integration

## Outcome and scope

The company renderer now uses the real glove PNGs supplied by the parallel art lane. Production-source headless integration passes. This is not native GPU/contact/visual acceptance; the parent owns that gate, the aggregate runner, UI, documentation rollout and packaging.

This runtime lane changed only:

- `company_loop/character.gd`
- `company_loop/compositor.gd`
- `company_loop/tests/glove_test.gd`
- `company_loop/tests/character_test.gd`
- `company_loop/tests/outfit_test.gd`
- `company_loop/GLOVES-RENDERING.md`

No original art, simulation, data, prototype, sprite-study resolver/shader, company session/UI, motion methods or picking code was changed. No GUI, source-tree import, staging or commit was performed. `glove-runtime/preservation.json` compares 671 protected files with the initial pre-implementation snapshot: zero changes. Parent/art-lane writes are separate.

## Resolver and source plan

Gloves are presentation owned by the already-resolved visible body outfit, not an independent gear slot or a second scan of raw equipment. The inherited resolver still controls actual item identity, supported/omitted art, first-slot duplicate admission, covered layers and helmet-context foundations. Ownership is outer, otherwise mail, otherwise base. Broken-but-equipped supported armor still owns gloves; its actual wear tint is applied to both glove layers.

| Resolved body source | Glove source |
| --- | --- |
| `outfit_quilt` | `glove_pair_quilt.png` |
| `outfit_mail` | `glove_pair_mail.png` |
| `outfit_brigandine` | `glove_pair_brigandine.png` |

`CompanyCompositor.contextual_stack()` is idempotent and is used by both composition and diagnostics:

1. Existing lower keep-mask and new `hand_keep_mask.png` independently multiply a copied foundation's alpha, with RGBA8 rounding at each multiplication. RGB is retained; mask RGB is ignored. There is no runtime anatomical cutoff.
2. The complete owner-tinted glove pair is drawn at priority 19.
3. The unchanged selected weapon remains at priority 20.
4. The inherited priority-21 `weapon_grip` is replaced with the **same glove source**, multiplying its alpha by the **original corresponding grip PNG's alpha**. Original grip RGB is never sampled into a gloved figure. The entire glove is not painted over the held weapon.
5. Shields remain priority 22.

Foundation, outfit, glove and original grip caches are immutable inputs. Removing the final supported outfit restores the original complete straight RGBA, including hidden RGB and original bare grip foregrounds. Lower-body paint, texture scale, foot anchor, mipmaps, source shader, node lifetime, bounded motion and alpha picking keep their inherited behavior.

Required glove sources use ordinary painted-source validation. The hand keep-mask uses the existing separate auxiliary-mask validator: decoded RGBA8, correct canvas, no mipmaps, meaningful retained and suppressed alpha; opaque corners and arbitrary RGB are allowed. The original grip alpha source remains required. Missing or invalid required art fails the **whole figure** closed, clears stale sprite/shadow, diagnoses the exact source and never caches failure. Removal restores a valid bare figure. Source assets are immutable for a process lifetime; hot-reloading files under an already-cached texture is not supported.

## Diagnostics and cache

- Body signatures retain every physical field and add `owns_gloves`, parallel to existing `owns_lower_body`.
- `glove_pair` identifies the real armor item/definition/condition/maximum/broken state, actual glove asset/root, priority, tint, owning body slot and `outfit_owner`. It is a support painting, not an invented inventory item.
- `weapon_grip` retains its actual physical weapon identity/condition. Its glove asset/root/color, original `clip_mask`/root/error, explicit `outfit_owner`, `wear_condition` and `wear_maximum` describe glove-owned foreground support without relabeling the weapon as armor.
- Foundation signatures expose `hand_keep_mask`, root and exact error, alongside existing lower-mask and outfit-owner fields.
- A blocked figure retains planned ownership but all painted signatures are nonvisible/`composite_blocked`.
- `render_diagnostics().cache_key` is exactly `JSON.stringify(stack)`: selected foundation/helmet, lower and hand masks, actual glove source, original grip clip, tint, priorities and owning slot are present. Physical UIDs do not fragment pixel-identical textures.
- Final texture LRU remains capped at 16. The finite source upper bound is 29: 17 accepted sources, four identity variants, four outfit/mask sources and four glove/mask sources. Existing obsolete limits of 21/25 were narrowly updated.

## Tests and retained evidence

Evidence root:

`/home/quatro/games/battle-brothers-2-full-outfits-evidence/glove-runtime/`

Each attempt has exact raw logs, commands, engine SHA-256 and a complete copied-source manifest. `run-private.py` is the retained reproduction harness. It cold-copies the project into `/home/quatro/.hermes/cache/scratch`, imports there and supplies private HOME/XDG/TMPDIR with desktop/bus environment unset. The executable is the specified Godot 4.4.1. The source worktree has no `.godot` directory.

Actual vertical RED/GREEN:

- `red-owner`: explicit fixture cohort **6 checks, 5 failures**, missing pair/owner/mask/paint. Default real-art test separately **4 checks, 4 failures**, because the art had not arrived. No silent fixtures were used.
- `green-owner`: **7 checks, 0 failures**.
- `red-grips-valid`: **259 checks, 108 failures**, exactly the missing glove-foreground plan, diagnostics and pixel oracle across the held matrix.
- `green-grips`: **259 checks, 0 failures**.

Retained test setup mistakes are not product REDs: `red-grips` had a GDScript local type-inference error; `reconciled-fixtures` exposed mipmaps in region data (fixed by clearing mipmaps on extracted test regions); `expanded-fixtures` placed a fractional-mask witness underneath opaque outfit paint (fixed with a deliberately isolated synthetic outfit). No production oracle was weakened to accept those failures.

Latest completed focused production-art results:

| Evidence directory | Suite | Result |
| --- | --- | --- |
| `final-expanded` | Production glove | **574 checks, 0 failures** |
| `final-expanded` | Explicit synthetic glove fixtures | **571 checks, 0 failures** |
| `real-art-integration` | Company character | **245 checks, 0 failures** |
| `real-art-integration` | Full outfit | **535 checks, 0 failures** |
| `real-art-integration` | Camp panel | **204 checks, 0 failures** |
| `real-art-integration` | Original sprite-study character | **198 checks, 0 failures** |

Ordinary glove/character/outfit/camp/import logs have no engine warnings/errors. The original sprite-study suite retains its previously documented filesystem-image-loading warning; it is not introduced by this lane.

`final-expanded` also contains six separate production-decoder probes: missing and undecodable `glove_pair_mail`, `hand_keep_mask`, and original `grip_sword`. Each completes **6 checks, 0 failures**. These are deliberately negative source tests; their raw logs contain the expected decoder/refusal warnings/errors and must not be passed through the ordinary clean-output acceptance policy. Only private-copy files were changed and restored.

The glove suite exercises all three outfits × original sword/axe/spear/bow definitions × no/kite/round shield (36 resolver stacks). An independent original compositor consumes explicitly masked copied sources, not the runtime context function. The suite proves exact source-over output, exact existing legs/boots below the art-owned y700 seam, opaque original shield preservation, original-grip RGB nonparticipation, exact bare held restoration, owner precedence/removals, omitted first duplicates, catalog tint, all three identities, partial/broken wear, physical diagnostics, cache identity/bounds and source immutability. The held matrix is a presentation/resolver proof, not a claim that every two-handed-plus-shield combination is legally equippable in the campaign.

Existing full-outfit tests still exercise real Session-owned UIDs, kit/stash transfers, camp automatic refresh, exact camp TextureRect/field Sprite3D Texture2D identity, actual deployment, three identities and supported helmet contexts, unchanged command/RNG snapshots, native headless AABBs and camera-facing alpha picking during motion at both projections and three zooms. Existing company-character motion tests are retained.

### Narrow predecessor reconciliation

All useful predecessor checks remain:

- Nine old lower-body-inclusive equalities are now source-qualified upper comparisons plus **new** opaque-original-body comparisons. Glove exceptions use actual glove alpha; hand-mask suppression may excuse only foundation pixels, never opaque original armor.
- Three old original-identity whole-body equalities become exact original upper/face comparisons outside those same named supports. Exact bare and every non-body-gear whole-composite equality are unchanged.
- Nine diagnostic equalities explicitly validate full-outfit/glove ownership, then normalize only the three known body source fields and the two ownership flags. Every inherited physical/fallback/color/visibility field is still compared exactly. New pair diagnostics are checked separately, not blindly ignored.
- Only the obsolete finite source-count limits change. The texture LRU remains 16.
- The outfit suite's blanket upper-hand preservation check is replaced by the same source-bound exception; opaque original armor remains exact outside actual glove alpha, including the hem. All lower/body/face/removal/motion/picking tests remain.

### Reproduction

Inside an imported private project:

```text
<Godot-4.4.1> --headless --single-threaded-scene --path <private-project> --script res://company_loop/tests/glove_test.gd
```

Append `-- --fixture-assets` only for the explicitly labeled synthetic cohort. Character and outfit tests also accept this explicit development option. Default tests require the real new sources and fail when missing. `--required-source-failure=<asset>` is exclusively a negative-probe entry point, with that source independently removed/corrupted by the private harness.

## Actual art integration and limits

The real art arrived during runtime implementation and was tested through the production PNG decoder. The tested manifest binds:

- Quilt: `2066d86d8fdd0725dda53f3b7833dc9d7b871053a767336d59a8f95244657587`
- Mail: `4489165807fcaf63ea0e79b4f1462444ac80aea9b640d1e1f10f8f1994f406c6`
- Brigandine: `22e2e0bfdd0f58b199557590999a8c38db14a2dbd7a084d604b692fcc56733e9`
- Hand mask: `d45daeec55e88f271602b0019ca5c00a7fa267ceccfb9c2adc94219f2184fc85`

This lane did not author, modify or visually approve those PNGs. The art lane owns their generation receipts, source-bound mask/extraction, source hashes, offline verification and review sheets. Headless image equality is not GPU appearance, natural painted glove/weapon contact, external-pointer/native acceptance, export validation or human playability. Those remain parent-owned; no GUI claim is made here.
