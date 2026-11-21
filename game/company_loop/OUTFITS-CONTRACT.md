# Full-body outfit scope and lane contract

Base: ff184def1016bfcb4a523da484b71ae1ef4868a7. Work only in /home/quatro/games/battle-brothers-2-full-outfits, branch spike/full-body-outfits. Accepted company worktree and all saves remain untouched.

User: the body armor outfit must own matching legs and boots. Outermost supported body outfit owns lower-body paint, removal reveals the next real outfit, and no-body-gear returns the original ordinary-clothes figure. No new stats, slots, items, terrain, camera/light changes, identity/anatomy changes or broad catalogue work.

## Shared asset contract

New files under company_loop/outfits/characters/:
- outfit_quilt.png
- outfit_mail.png
- outfit_brigandine.png
- foundation_keep_mask.png

All 1024x1536 RGBA, same foot (512,1490), pixel_size0.00134. Each outfit PNG includes original accepted upper equipment paint plus newly painted matching legs and boots; retain original torso material/shape rather than regenerate it. The common keep mask's ALPHA multiplies the selected foundation's alpha only when a supported outfit is active. RGB of the mask is irrelevant. Mask hides obsolete base trousers/boots, not original face/hands/upper anatomy. All three new outfits must completely cover the intended retained/revealed join; no brown old boot fringe. Original immutable inputs must never be overwritten. The art owner chooses and documents contour/seam based on actual art; runtime must not hardcode a new anatomy boundary.

Mapping must arise from the inherited resolved/visible body layer, with priority body/outer > body/mail > body/base. Complete outfits remain singular; inspect unsupported and duplicate-slot behavior through actual resolver, not independent raw gear guesses. Damage tint belongs to the physical owning armor. Broken-but-equipped body armor stays visible/worn. Base fallback and helmet identity/removal remain exact. Contextual foundation/asset choices belong in the cache key and diagnostics. Missing required outfit or mask refuses entire composite rather than silently keeping stale/plain legs.

## Authorized glove extension

The user additionally requested gloves during the full-outfit pass. Include outfit-owned glove appearance in the final deliverable, in both camp and battle, without adding mechanical slots or stats. Light outfits use simple leather gloves; heavier outfits use coherent protective glove construction. Keep original hand anatomy, fist pose and weapon/shield registration unchanged beneath the reversible equipment paint. Actual visible body-outfit ownership and condition control gloves, with correct inner-outfit or bare-hand restoration on removal.

Finish the already-running legs/boots lanes without discarding their evidence; qualify gloves as a bounded follow-up before final delivery. Use separately reproducible glove paint/masks on the frozen pose. Inspect and test the complete held-item stack: inherited bare-skin grip foregrounds must not reappear above a full glove, and weapons/shields must remain correctly held and legible. No gloves must restore the exact original exposed hand/grip pixels. Preserve the accepted upper armor and all original source images; no anatomy regeneration, arbitrary hand stretching or independent cosmetic loadout. Record actual light/dark close-up and menu/battle evidence, not just source-alpha tests.

## Ownership

Art lane only: company_loop/outfits/** (including sources/recipes/docs/asset evidence), company_loop/tests/outfit_assets_test.py.
Runtime lane only: company_loop/character.gd, company_loop/compositor.gd, company_loop/tests/outfit_test.gd, company_loop/OUTFITS-RENDERING.md. No other files.
Parent: this contract, integration runner/docs, native acceptance, final packaging/review. No competing file writers. No subagent GUI/staging/commit.

Keep existing equipment, foundation and head assets immutable. Preserve all existing source trees except explicitly owned company adapter paths. Read original source/catalog and tests first. TDD for behavior/assets, execute real Godot headless with private HOME/project; preserve RED/GREEN and actual logs. Offline art sheets are not engine evidence. Report unsupported/unfinished work honestly. One final combined native/review gate, not repeated unbounded polishing.
