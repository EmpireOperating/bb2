# Company characters — bounded individuality and motion

## Delivered scope

Three head identities, selected solely by `posmod(int(unit.visual_id), 3)`:

- **0: original** — exact accepted brown-haired, brown-bearded foundation.
- **1: copper** — red hair/sideburns, horseshoe moustache and exposed chin.
- **2: silver** — bald crown, silver temple hair and full silver beard.

The original shared body, fists, stance, clothing foundation, foot registration and all existing equipment remain unchanged. This is not a full animation rig, a new weapon batch, or a replacement art direction. Six company members repeat these three bounded appearances. Missing `visual_id` defaults to the original; battle `id`, names, `appearance`, and gear do not select anatomy. The domain remains responsible for stable company `sid` / deployed `visual_id`.

`character.gd` extends the accepted `sprite_study/character.gd`. It inherits `configure(unit,catalog)`, equipment resolution, source tint/wear, whole-outfit suppression, shared preview Texture2D, original Compatibility color shader, alpha/depth behavior and picker geometry. `compositor.gd` changes only dispatch of four new foundation PNGs. The inherited LRU holds at most 16 composite textures; source dispatch is finite (17 existing PNGs plus four derivatives). Full source asset names make identity and helmet context part of the stack/cache key. Held preview references remain valid after eviction.

Helmet context comes from the **accepted resolver's actually painted head/shell callback**, not another equipment scan. Thus duplicate/omitted unsupported shells cannot hide hair. Missing identity art fails the whole figure closed with named diagnostics, never silently substitutes another face. Removal restores the exact identity-specific bare pixels. Signatures retain every real equipment field, and foundation adds `visual_id`, `identity`, `helmet_context`, and the accurate source root/name.

## Presentation API

Call these only after the parent accepts a command or produces real feedback:

```gdscript
actor.play_attack(target_world_position - actor.global_position)
actor.play_hit()             # hit recoil
actor.play_hit("stagger")    # same recoil; parent's actual feedback spelling
actor.play_hit("shield")     # tiny guard pulse, only with a visible real shield
actor.play_hit("block")      # alias of shield
actor.cancel_motion()
```

- Attack: 0.10 world-unit maximum horizontal Illustration lunge, 0.22 seconds total.
- Hit/stagger: 0.045 world-unit camera-right recoil, 0.18 seconds total.
- Shield/block: 0.025 recoil, 0.20 seconds total; the **whole composited guard** briefly scales to at most 1.014 × 1.008. This is not separately articulated shield motion.
- Smooth finite envelopes; no idle bobbing, no RNG, no tweens/timers retained by the actor, no frame recomposition, no texture/color changes and no actor-root movement.
- Same-person refresh preserves the current animation clock. A new command replaces the previous pulse. Explicit cancel, person change, death refresh, missing art, invisible actor processing, and leaving the tree reset motion. Removing/breaking/omitting a shield cancels its guard pulse. Zero/nonfinite attack vectors and unknown hit kinds cannot invent movement.
- Parent movement/death/visibility remains authoritative. Dead actors may still render for the parent but cannot start pulses. Camp actors may be process-disabled.

The unchanged picker already uses each Composite's actual global transform and alpha; moving Illustration and scaling Composite keeps pick geometry aligned. No picker fork or simulation write is introduced.

## Original source edits and exact provenance

Immutable reference: `sprite_study/assets/sources/base-master.png`, plus all **17** accepted `sprite_study/assets/characters/*.png` files. Their before-work SHA-256 seal is retained in `assets/sources/protected-inputs.json`.

New source artwork is retained byte-for-byte in:

- `assets/sources/copper-master.png`
- `assets/sources/silver-master.png`
- `assets/sources/provider-receipts.json` — exact returned tool fields, prompts, request IDs and original returned paths, wrapped with copy/identity metadata.

Both requests used provider **openai-codex**, reported model **gpt-image-2-medium**, one edited reference image, requested size `1024x1536`, requested quality `medium`. Both actual results were **1173x1341**. Copper reported quality `medium`; silver reported quality **`low`**, preserved rather than relabeled. Source reference was a `(440,20,720,340)` crop of the immutable base enlarged to `840x960` with Pillow's default RGB resize, retained as `head-reference.png`. Generative production is not deterministic; rebuilding from the retained paintings is.

`assets/rebuild.py` records/exercises the extraction:

1. Key only generated magenta background (`R>150`, `B>150`, `G<100`).
2. LANCZOS resize each edited crop to `280x320`, place at `(440,20)` on `1024x1536`.
3. Replace only the recorded head polygon, with a 1.1px inward-clipped join feather. The bounded polygon includes a small head/upper-neck join; **every pixel outside it is exactly original**. No new hands/body/equipment are adopted from generated sources.
4. For helmet context, limit alpha to the accepted helmet foundation's alpha. Preserve its original pixels outside the head region. This prevents new hair/scalp from extending beyond the accepted helmet-context silhouette.
5. Save four full registered foundations, a labeled offline review sheet and a source/output manifest. No changes to existing equipment PNGs, source originals, shader, terrain or rendering constants.

Rebuild dependencies exercised here: Python 3.11, Pillow 12.3.0, NumPy 2.4.3. From the repository root:

```bash
python3 company_loop/assets/rebuild.py
python3 company_loop/assets/verify.py
# Independent output roots for byte-reproducibility checks:
python3 company_loop/assets/rebuild.py --output /absolute/evidence/identity-rebuild-a
python3 company_loop/assets/rebuild.py --output /absolute/evidence/identity-rebuild-b
python3 company_loop/assets/verify.py --output /absolute/evidence/identity-rebuild-a
```

The builder refuses protected/source output roots and validates the immutable input seal before writing. The independent verifier checks full non-head RGBA, body/fists/feet, helmet silhouette containment, source/output hashes, dimensions, visible variation and opaque magenta leakage.

## Verification and evidence

Evidence root: `/home/quatro/games/battle-brothers-2-company-evidence/characters`.

- `red-identity/godot.log`: genuine pre-implementation RED, identities 1/2 still matched original pixels.
- Subsequent retained REDs caught duplicate-shell suppression, missing motion, unsupported-shield pulse, and missing-identity diagnostic/stagger handling; these were fixed rather than weakening expectations.
- `green-character-final/godot.log`: **214 checks, 0 failures**, real Godot 4.4.1 with isolated HOME/XDG directories. Positive tests use real source PNGs; one explicit missing-source fault fixture verifies fail-closed behavior.
- `accepted-character-regression/godot.log`: unchanged accepted real-asset suite, **198 checks, 0 failures**.
- `accepted-color-regression/godot.log`: unchanged accepted color-transfer oracle, **572 checks, 0 failures**, max scalar roundtrip error 0.0.
- `reproducibility.json`: two complete post-final-builder rebuilds matched each other **and all six shipped output files** byte-for-byte (four PNG foundations, sheet, manifest).
- `rebuild-a-verify.json`, `rebuild-b-verify.json`: all 18 protected input files exact, all non-head pixels exact. `corrupt-negative.log` confirms a deliberately corrupted copied output is rejected.

The native engine API measured Composite AABB position `(-0.68608,-0.06164,0)`, size `(1.37216,2.05824,0)` after queued Sprite3D mesh updates, matching canvas `1024x1536`, foot `(512,1490)` and pixel size `0.00134`. Tests exercise actual alpha picking of head/torso/foot witnesses and transparent margins under motion, orthographic/perspective projections and zoom 14/22/32; damage, removal, stale arms, source failures, identity churn, cache eviction, automatic return, replacement/cancellation and unchanged simulation/catalog inputs are covered. First immediate AABB sampling was a test-readiness failure; its failed log remains retained, and the test now awaits the real engine frame flush.

Example standalone headless invocation (use a new private state directory):

```bash
STATE=/absolute/evidence/private-character-state
mkdir -p "$STATE"/{home,data,config,cache}
HOME="$STATE/home" XDG_DATA_HOME="$STATE/data" \
XDG_CONFIG_HOME="$STATE/config" XDG_CACHE_HOME="$STATE/cache" \
/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64 \
  --headless --single-threaded-scene \
  --path /home/quatro/games/battle-brothers-2-company-loop \
  --script res://company_loop/tests/character_test.gd
```

Offline sheet inspected: `assets/characters/identity-sheet.png` — bare heads, both accepted helmets, and same mail/sword/round-shield loadout at tactical size. Distinct bald crown/beard/moustache and clean helmet joins are visible; finer facial details naturally reduce at tactical size. This sheet and native **API geometry** tests are not live GPU/input acceptance. The parent owns actual private GUI review, battle/camp integration and final packaging. No GUI, staging or commit was performed in this lane.
