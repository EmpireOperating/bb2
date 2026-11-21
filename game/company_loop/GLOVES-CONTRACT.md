# Outfit-owned glove follow-up

User explicitly added gloves to the approved full-outfit task. Work only in /home/quatro/games/battle-brothers-2-full-outfits on spike/full-body-outfits, base ff184def1016bfcb4a523da484b71ae1ef4868a7. Legs/boots source has completed its bounded lanes; preserve that implementation/art except narrowly superseded hand-preservation assertions. Original sprite_study, visual_slice, prototype, src, data, company session/UI/terrain and all original art stay immutable.

## Asset interface

New 1024x1536 RGBA PNGs under company_loop/gloves/characters/:
- glove_pair_quilt.png: both hands, simple full leather gloves.
- glove_pair_mail.png: both hands, mail-backed protective gloves with leather palms/fingers.
- glove_pair_brigandine.png: both hands, coherent reinforced leather/metal gauntlets.
- hand_keep_mask.png: auxiliary alpha mask applied to original foundation only while a supported body outfit owns gloves; RGB ignored. Suppress original hand paint only inside documented source-bound footprint, retain all other anatomy and the source pose. Preserve sleeve/hand attachment without a naked-skin crescent or floating cuff. Gloves overlay equipment, not new anatomy.

Keep common canvas/foot (512,1490), original fist centers, lengths, gripping orientation and weapon/shield registration exact. Genuine generated scoped glove paint, not tint-only hands or arbitrary recolored skin. Keep source masters, exact tool receipts, extraction/registration recipe, deterministic builder, protected hashes and contrasting close-ups. Do not bake gloves into existing full-outfit/body/base PNGs. No independent glove slot/stat/definition. Preserve the complete original no-body-armor figure/hand foregrounds exactly on removal.

## Composition

Use the already-resolved visible full-body outfit owner (outer > mail > base), not raw armor scans. Corresponding glove source and tint/wear derive from that exact owning body stack entry. Whole pair is drawn at priority19, before weapon20. Replace inherited bare-skin weapon_grip (priority21) with glove-owned foreground sampled from the same glove pair, clipped by the ORIGINAL corresponding grip image's alpha; do not paint the whole glove over the weapon or move the held object. Shields remain priority22. Hand keep-mask and existing lower keep-mask multiply foundation alpha independently; no hardcoded anatomical boundary. All added context belongs in cache keys and diagnostics. Missing/corrupt required glove or hand mask fails the figure closed, not stale gear. This algorithm is a starting contract, not visual proof: if its actual contact fails, report source-bound evidence before revising it.

The art lane must inspect glove coverage both without equipment and against the existing sword/axe/spear/bow and kite/round-shield stack. Runtime must exercise actual same equipment, owner removals, broken/worn armor, shared exact camp/battle Texture2D, identities, picking/anchors, bounded caches, no simulation mutation and missing required assets. Original exposed fingers are correct only when no supported outfit is active.

## Ownership

Art child ONLY company_loop/gloves/** and company_loop/tests/glove_assets_test.py. Runtime child ONLY company_loop/character.gd, company_loop/compositor.gd, company_loop/tests/glove_test.gd, company_loop/tests/character_test.gd, company_loop/tests/outfit_test.gd, company_loop/GLOVES-RENDERING.md. Runtime may reconcile obsolete predecessor pixel/diagnostic/cache assertions explicitly and narrowly: preserve all non-body cases, actual equipment fields, original opaque torso pixels outside authorized glove support, face, bare restoration, motion and selection gates. Do not delete useful tests or simply bless whole output hashes. Parent owns runner/docs/native/review/package.

Execute actual tests first (RED then GREEN), privately imported project/HOME/XDG. Fixture cohorts must be labeled, default real-art tests fail if art absent. Required new Godot marker COMPANY_GLOVE_TEST: N checks, 0 failures. New Python asset test is standard unittest. No child GUI, staging, commit or public actions. Stop at bounded genuine implementation and report native acceptance pending.
