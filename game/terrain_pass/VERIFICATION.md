# Terrain Rules verification

## Candidate and scope

Based on Full Outfits `5ad919b4f81126a24603e9375449c488b3549174`, isolated in `spike/terrain-rules`. This is the two-map terrain/rules successor, not a complete retail Battle Brothers port. Only five existing tracked paths change: README, project settings, two presentation factory seams, and the opted-in Battle rule integration. All 2,162 other baseline tracked files remain byte-identical; all 2,167 tracked files in the accepted Full Outfits worktree remain unchanged.

Evidence root: `/home/quatro/games/battle-brothers-2-terrain-rules-evidence/`. Checked-in selected receipts/screenshots are inert under `terrain_pass/evidence/.gdignore`.

## Executed headless gates

The verification integration aggregate completed **38/38 commands**, with **29 Godot suite processes / 57,938 checks / zero failures**, **7 Python suites / 55 tests / no unittest skips**, and two cold imports. A nested real launcher also imported and started the scene. This aggregate predates the final one-line shadow correction and its added assertions: its terrain result is 5,890/0, not 5,909/0.

After the correction, a fresh private cold import and the actual production terrain **5,909/0** and UI **92/0** suites passed. Exact executed runtime/test hashes match the candidate. Native acceptance below uses the corrected runtime. The final archive's cold aggregate is a separate post-freeze gate, recorded in `package/receipt.json` and `package/cold-checks/summary.json` outside this immutable source snapshot.

Key actual gates include:
- Terrain rules **11,402/0**: real paid moves and AP/fatigue route alternatives, invalid-command/RNG atomicity, heights/reach/ZOC, reactions/displacement/AI and opt-in isolation.
- Maps **98/0**, session **391/0**, separate-process cold reload **10/0**, routed UI **92/0**.
- Real headless sequential Crossing victory then Woodland defeat on the same unreset company; a separate real casualty/retreat/reload cohort. These are not native victory/casualty claims.
- Original terrain, painted terrain, equipment, full-outfit/glove composition, source pixels, picking and lifecycle regressions.

All engine runs use Godot 4.4.1 with private project copies and HOME/XDG. Source worktrees are not imported. One inherited image-loading warning remains in the older sprite-study character test; it is explicitly retained, not a clean-log claim. Final native and focused shadow/UI logs contain no Godot errors/warnings.

### Historical art-seal reconciliation

The first parent aggregate completed all 37 commands but failed two Python historical code-seal assertions because this task intentionally changes `src/battle.gd`. That failed evidence remains intact in `parent-aggregate-01/`.

The successor wrapper executes all **12 original outfit/glove pixel and provenance cases unchanged**. Only `OutfitAssetsTest.test_protected_inputs` and `GloveAssetsTest.test_protected_source_validator` are superseded by two strict replacements. Those verify **889 immutable historical entries / 580 unique files**, with equality exempted only for the literal path `src/battle.gd`. Original tests, builders and historically hash-pinned protected/artifact manifests are unchanged. No directory/glob, image, support file or sidecar is exempt. The runner emits explicit retained/superseded test and preservation receipts.

### Legacy limits

The rules lane separately compared 15 baseline/candidate logs byte-for-byte: nine passing suites, five unchanged inherited failing suites (formations, engagement AI, tactical AI, weapons and armor), and an identically incomplete People suite. Those are not silently converted into green gates, nor is old-save migration certified. Predecessor persistence checks use the predecessor project origin only inside the private test copy.

## Final native acceptance

Canonical task: `/home/quatro/omabox-trial/runs/default/cded2b82e26c/report.json`.
Native runtime tree: `5a158c3960fec4c8e25630dfdcea2976f9197771`.

Actual external mouse/keyboard input completed:
- Camp map selection without company/items/condition/encounter grants or resets.
- Both production maps with individual initiative and correct initial activation origin.
- **13 paid moves** across the two maps; completed movement AP/fatigue equals the quoted route.
- Real accepted player weapon actions, enemy responses and resulting damage.
- Shared equipment inspection, overview/close zoom, retreat cancel/confirm, unpaid settlement and return-to-camp saves.
- Exact engine close followed by a separate-process cold launch; company, inventory/condition and encounter records compare exactly. Transient map preference intentionally resets to Crossing.

**93 observed checks, 17 screenshots, two engine lifetimes**, both exit 0 with before/after sources matching the mounted stage. Parent independently reconciled receipt identities, stage hashes, costs, cold state and logs. Canonical cleanup succeeded; recorded runtime, private cache and cgroup paths are absent.

Parent inspected actual final Crossing, Woodland and equipment screenshots. Ground diagonal bands are gone; roads/river/bridge/ruins and raised flanks are readable; Woodland is a distinct green road/ridge composition without crossing-specific structures. Full-body sprites, boots and gloves retain the accepted style. Rocks and sparse trees remain stylized prototype art, not a finished biome or reference-art parity claim.

The run used native Wayland/Compatibility **Mesa llvmpipe software rendering** with Dummy audio. It does not qualify target-GPU FPS, audio, exports or other platforms. Dedicated opaque helmet/boot/transparent-margin click matrices, manual panning and an explicit native fade/restore demonstration were not repeated in this journey; their existing headless geometry/fade tests remain separate evidence.

## Rejected visuals and causal repair

The first native journey (`ac6fa11d8642`) passed gameplay but failed parent visual acceptance due to diagonal ground banding; an early Crossing screenshot was stale camp. Both findings are retained, not relabeled.

A separate real rendered diagnostic (`f3623196e6b4`) captured production, ground-caster-off and ground-receiver-off states with unchanged simulation. Only disabling continuous-ground casting removed self-shadow acne while retaining scenery shadows. Disabling reception unnecessarily removed useful shadows and was rejected. This programmatic GPU diagnostic is not external-input acceptance.

Test-first correction: **5,909 checks / 3 expected caster failures**, then the single runtime line setting `ContinuousFields.cast_shadow` OFF, then **5,909/0**. The original lit/shadow-receiving field shader, cliff/scenery casters, palettes, geometry, global lighting, sprites and simulation remain unchanged. Final external-input acceptance above was rerun on these corrected bytes.

## Freeze, independent review and delivery gates

The source is frozen with a native Git binary patch, reverse-apply check, complete changed-file manifest, added-line security scan and exact native runtime binding. Only documented tests/docs/inert evidence may differ from the native stage. Independent review is read-only against that frozen candidate; confirmed defects block delivery.

Post-freeze package evidence lives outside the source archive: `final-freeze/freeze.json`, `package/receipt.json` and the final delivery receipt. Packaging checks every archive member against its frozen Git blob and tracked regular/executable mode, cold-extracts without Git/import/save caches, exercises the successor plus four explicit historical presentation launchers, and reruns the entire aggregate from the extracted payload. A successful source test is not substituted for this gate.

## Unfinished rules, explicitly not certified

Exact native height-sensitive visibility/LOS, probabilistic cover/interception, miss scatter, swamp combat-stat modifiers, retail forced-fall exceptions and unrelated damage/perk rules are not completed. A historical cover helper was recovered, but native coordinate/direction tie-breaks and current-retail parity remain unverified. No invented 3D ray formula is labeled vanilla. See `RULES.md` and retained source citations. Camp-only saves, single-writer checkpoints and bounded equipment/world-content limits remain in README.
